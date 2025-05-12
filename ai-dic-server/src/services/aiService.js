const axios = require('axios');

// SiliconFlow API configuration
const SILICONFLOW_API_URL = 'https://api.siliconflow.cn/v1/chat/completions';
const SILICONFLOW_API_KEY = process.env.SILICONFLOW_API_KEY;

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

  prompt += 'Do not use any markdown formatting or quotes in your response.';

  console.log('Prompt:', prompt);

  const response = await axios.post(
    SILICONFLOW_API_URL,
    {
      model: 'deepseek-ai/DeepSeek-V3',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.3,
      max_tokens: 100,
    },
    {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${SILICONFLOW_API_KEY}`,
      },
    }
  );

  const definition = response.data.choices[0].message.content.trim();

  console.log('Definition:', definition);
  return {
    term: word,
    definition: definition,
    timestamp: new Date(),
  };
}

module.exports = {
  getWordDefinition,
};
