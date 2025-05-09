const axios = require('axios');

// SiliconFlow API configuration
const SILICONFLOW_API_URL = 'https://api.siliconflow.cn/v1/chat/completions';
const SILICONFLOW_API_KEY = process.env.SILICONFLOW_API_KEY;

/**
 * Get word definition from SiliconFlow API
 * @param {string} word - The word to define
 * @param {string[]} avoidWords - Words to avoid in the definition
 * @returns {Promise<{term: string, definition: string, timestamp: Date}>}
 */
async function getWordDefinition(word, avoidWords = []) {
  let prompt = `You are a professional English teacher for Chinese students. Define the English word '${word}' in one clear, concise sentence of explanation. `;
  
  if (avoidWords.length > 0) {
    prompt += `The student do NOT know these words: ${avoidWords.join(', ')}. `;
  }
  
  prompt += "The explanation should be suitable for English language learners and avoid overly complex vocabulary unless necessary. Never use Chinese in the explanation. Never add comments in the explanation.";

  console.log('Prompt:', prompt);
  
  const response = await axios.post(
    SILICONFLOW_API_URL,
    {
      model: "deepseek-ai/DeepSeek-V3",
      messages: [
        { role: "user", content: prompt }
      ],
      temperature: 0.3,
      max_tokens: 100
    },
    {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${SILICONFLOW_API_KEY}`
      }
    }
  );
  
  const definition = response.data.choices[0].message.content.trim();
  
  console.log('Definition:', definition);
  return {
    term: word,
    definition: definition,
    timestamp: new Date()
  };
}

module.exports = {
  getWordDefinition
};