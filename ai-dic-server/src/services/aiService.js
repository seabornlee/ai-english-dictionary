const axios = require('axios');

// DeepSeek Chat API configuration
const DEEPSEEK_API_URL = 'https://api.deepseek.com/v1/chat/completions';
const DEEPSEEK_API_KEY = process.env.DEEPSEEK_API_KEY;

/**
 * Get word definition from DeepSeek Chat API
 * @param {string} word - The word to define
 * @param {string[]} avoidWords - Words to avoid in the definition
 * @returns {Promise<{term: string, definition: string, timestamp: Date}>}
 */
async function getWordDefinition(word, avoidWords = []) {
  let prompt = `Define the English word '${word}' in one clear, concise sentence of explanation. `;
  
  if (avoidWords.length > 0) {
    prompt += `Please avoid using these words in your explanation: ${avoidWords.join(', ')}. `;
  }
  
  prompt += "The explanation should be suitable for English language learners and avoid overly complex vocabulary unless necessary.";
  
  const response = await axios.post(
    DEEPSEEK_API_URL,
    {
      model: "deepseek-chat",
      messages: [
        { role: "user", content: prompt }
      ],
      temperature: 0.3,
      max_tokens: 100
    },
    {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${DEEPSEEK_API_KEY}`
      }
    }
  );
  
  const definition = response.data.choices[0].message.content.trim();
  
  return {
    term: word,
    definition: definition,
    timestamp: new Date()
  };
}

module.exports = {
  getWordDefinition
}; 