const axios = require('axios');

// SiliconFlow API configuration
const SILICONFLOW_API_URL = 'https://api.siliconflow.cn/v1/chat/completions';
const SILICONFLOW_API_KEY = process.env.SILICONFLOW_API_KEY;

const LANGUAGE_INSTRUCTIONS = {
  'zh-CN': 'You MUST respond in Simplified Chinese.',
  en: 'You MUST respond in English.',
  ja: 'You MUST respond in Japanese.',
  ko: 'You MUST respond in Korean.',
  es: 'You MUST respond in Spanish.',
};

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

function normalizeCollocations(value) {
  if (!Array.isArray(value)) return null;

  return value
    .filter(item => item && (item.phrase || item.word))
    .map(item => ({
      phrase: sanitizeText(item.phrase || item.word || ''),
      meaning: sanitizeText(item.meaning || item.definition || ''),
    }))
    .filter(item => item.phrase)
    .slice(0, 3);
}

function normalizeWordDefinition(word, rawContent, language = 'en') {
  const payload = extractStructuredPayload(rawContent);
  const definition =
    sanitizeText(payload.definition) ||
    sanitizeText(payload.explanation) ||
    sanitizeText(rawContent);
  const pronunciation = sanitizeText(payload.pronunciation) || sanitizeText(payload.phonetic);
  const partOfSpeech = sanitizeText(payload.partOfSpeech);
  const exampleSentences = normalizeExampleSentences(payload.exampleSentences || payload.examples);
  const simpleDefinition = payload.simpleDefinition ? sanitizeText(payload.simpleDefinition) : null;
  const examples = payload.examples ? normalizeExampleSentences(payload.examples) : null;
  const collocations = payload.collocations ? normalizeCollocations(payload.collocations) : null;

  return {
    term: word,
    definition,
    pronunciation: pronunciation || null,
    partOfSpeech: partOfSpeech || null,
    exampleSentences,
    simpleDefinition,
    examples,
    collocations,
    language,
    timestamp: new Date(),
  };
}

/**
 * Get word definition using DeepSeek Chat API
 * @param {string} word - The word to define
 * @param {string[]} [unknownWords=[]] - Words to avoid in the definition
 * @param {string} [language='en'] - Output language (zh-CN, en, ja, ko, es)
 * @param {object} [options={}] - Additional options
 * @param {object} [options.explanationSections={}] - Which sections to include
 * @param {boolean} [options.explanationSections.simple=false] - Include simpler wording
 * @param {boolean} [options.explanationSections.examples=false] - Include example sentences
 * @param {boolean} [options.explanationSections.collocations=false] - Include common collocations
 * @returns {Promise<Object>} Word definition object
 */
async function getWordDefinition(word, unknownWords = [], language = 'en', options = {}) {
  const { explanationSections = {} } = options;
  const { simple = false, examples = false, collocations = false } = explanationSections;

  const languageInstruction = LANGUAGE_INSTRUCTIONS[language] || LANGUAGE_INSTRUCTIONS.en;

  let avoidClause = '';
  if (unknownWords.length > 0) {
    avoidClause = ` The student does NOT know these words, so do NOT use them: ${unknownWords.join(', ')}.`;
  }

  const sectionsInstruction = [`"definition"`, `"pronunciation"`, `"partOfSpeech"`, `"exampleSentences"`];
  if (simple) sectionsInstruction.push(`"simpleDefinition"`);
  if (examples) sectionsInstruction.push(`"examples"`);
  if (collocations) sectionsInstruction.push(`"collocations"`);

  const prompt = `Define "${word}" simply.${avoidClause}
${languageInstruction}
You MUST respond with ONLY a JSON object (no markdown, no backticks, no commentary) using exactly these keys: ${sectionsInstruction.join(', ')}.

Field descriptions:
"definition": One concise, easy-to-understand sentence explaining the word.
"pronunciation": IPA transcription (e.g. "həˈloʊ").
"partOfSpeech": one of noun, verb, adjective, adverb, etc.
"exampleSentences": array of 2 short natural sentences using the word.${simple ? `
"simpleDefinition": Even simpler wording using very basic vocabulary.` : ''}${examples ? `
"examples": Array of 1-2 short example sentences.` : ''}${collocations ? `
"collocations": Array of objects with "phrase" and "meaning" keys, 1-3 common collocations.` : ''}`;

  console.log('Prompt:', prompt);

  const response = await axios.post(
    SILICONFLOW_API_URL,
    {
      model: 'deepseek-ai/DeepSeek-V3',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.3,
      max_tokens: 800,
      response_format: { type: 'json_object' },
    },
    {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${SILICONFLOW_API_KEY}`,
      },
    }
  );

  const definitionContent = response.data.choices[0].message.content.trim();
  const result = normalizeWordDefinition(word, definitionContent, language);

  console.log('Definition:', result.definition);
  return result;
}

module.exports = {
  getWordDefinition,
};