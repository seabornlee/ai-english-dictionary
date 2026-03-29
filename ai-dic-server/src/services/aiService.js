const axios = require('axios');

// SiliconFlow API configuration
const SILICONFLOW_API_URL = 'https://api.siliconflow.cn/v1/chat/completions';
const SILICONFLOW_API_KEY = process.env.SILICONFLOW_API_KEY;

function sanitizeText(value) {
  if (typeof value !== 'string') {
    return '';
  }

  return value
    .replace(/\*\*/g, '')
    .replace(/\*(.*?)\*/g, '$1')
    .replace(/_(.*?)_/g, '$1')
    .replace(/`(.*?)`/g, '$1')
    .replace(/```[\s\S]*?```/g, '')
    .replace(/#{1,6}\s/g, '')
    .replace(/\[(.*?)\]\(.*?\)/g, '$1')
    .replace(/^['"]+|['"]+$/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function extractStructuredPayload(content) {
  if (content && typeof content === 'object') {
    return content;
  }

  if (typeof content !== 'string') {
    return {};
  }

  const trimmedContent = content.trim();

  try {
    return JSON.parse(trimmedContent);
  } catch (_error) {
    const jsonMatch = trimmedContent.match(/\{[\s\S]*\}/);

    if (jsonMatch) {
      try {
        return JSON.parse(jsonMatch[0]);
      } catch (_nestedError) {
        return { definition: trimmedContent };
      }
    }

    return { definition: trimmedContent };
  }
}

function normalizeExampleSentences(value) {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map(sentence => sanitizeText(sentence))
    .filter(Boolean)
    .slice(0, 3);
}

function normalizeWordDefinition(word, rawContent) {
  const payload = extractStructuredPayload(rawContent);
  const definition =
    sanitizeText(payload.definition) ||
    sanitizeText(payload.explanation) ||
    sanitizeText(rawContent);
  const pronunciation = sanitizeText(payload.pronunciation) || sanitizeText(payload.phonetic);
  const partOfSpeech = sanitizeText(payload.partOfSpeech);
  const exampleSentences = normalizeExampleSentences(payload.exampleSentences || payload.examples);

  return {
    term: word,
    definition,
    pronunciation: pronunciation || null,
    partOfSpeech: partOfSpeech || null,
    exampleSentences,
    timestamp: new Date(),
  };
}

/**
 * Get word definition using DeepSeek Chat API
 * @param {string} word - The word to define
 * @param {string[]} unknownWords - Words to avoid in the definition
 * @returns {Promise<Object>} Word definition object
 */
async function getWordDefinition(word, unknownWords = []) {
  let prompt = `Define the word "${word}" in a simple way. `;

  if (unknownWords.length > 0) {
    prompt += `The student do NOT know these words: ${unknownWords.join(', ')}. `;
  }

  prompt +=
    'Return valid JSON only with exactly these keys: definition, pronunciation, partOfSpeech, exampleSentences. ' +
    'Use an IPA-style pronunciation string when possible. ' +
    'Set exampleSentences to an array of 2 short natural sentences that use the word clearly. ' +
    'Do not include markdown or extra commentary. If a field is unknown, use an empty string or an empty array.';

  console.log('Prompt:', prompt);

  const response = await axios.post(
    SILICONFLOW_API_URL,
    {
      model: 'deepseek-ai/DeepSeek-V3',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.3,
      max_tokens: 220,
    },
    {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${SILICONFLOW_API_KEY}`,
      },
    }
  );

  const definitionContent = response.data.choices[0].message.content.trim();
  const result = normalizeWordDefinition(word, definitionContent);

  console.log('Definition:', result.definition);
  return result;
}

module.exports = {
  getWordDefinition,
};
