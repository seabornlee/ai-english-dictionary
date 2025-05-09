const { getWordDefinition } = require('../services/aiService');

// In-memory storage for vocabulary, favorites, and history (would be replaced with a database in production)
let vocabularyList = [];
let favorites = [];
let searchHistory = [];
let wordAvoidWords = new Map(); // Store avoid words for each word

// DeepSeek Chat API configuration
const DEEPSEEK_API_URL = 'https://api.deepseek.com/v1/chat/completions';
const DEEPSEEK_API_KEY = process.env.DEEPSEEK_API_KEY;

// Define a word using DeepSeek Chat API
exports.defineWord = async (req, res) => {
  try {
    const { word, avoidWords = [] } = req.body;
    
    if (!word) {
      return res.status(400).json({ error: 'Word is required' });
    }
    
    // Get existing avoid words for this word
    const existingAvoidWords = wordAvoidWords.get(word) || [];
    
    // Add new avoid words to the existing ones
    const updatedAvoidWords = [...new Set([...existingAvoidWords, ...avoidWords])];
    
    // Update the avoid words map
    wordAvoidWords.set(word, updatedAvoidWords);
    
    const result = await getWordDefinition(word, updatedAvoidWords);
    result.definition = stripMarkdown(result.definition);
    
    // Add to search history
    addToHistory(result);
    
    console.log('Result:', result);
    return res.status(200).json(result);
  } catch (error) {
    console.error('Error defining word:', error);
    return res.status(500).json({ 
      error: 'Error defining word',
      message: error.message
    });
  }
};

// Add word to vocabulary list
exports.addToVocabulary = (req, res) => {
  try {
    const { term, definition } = req.body;
    
    if (!term || !definition) {
      return res.status(400).json({ error: 'Term and definition are required' });
    }
    
    const word = {
      term,
      definition,
      timestamp: new Date()
    };
    
    // Check if word already exists
    const existingIndex = vocabularyList.findIndex(item => item.term === term);
    if (existingIndex >= 0) {
      return res.status(200).json({ message: 'Word already in vocabulary', word });
    }
    
    vocabularyList.push(word);
    return res.status(201).json(word);
  } catch (error) {
    console.error('Error adding to vocabulary:', error);
    return res.status(500).json({ error: 'Error adding to vocabulary' });
  }
};

// Get vocabulary list
exports.getVocabulary = (req, res) => {
  return res.status(200).json(vocabularyList);
};

// Remove word from vocabulary
exports.removeFromVocabulary = (req, res) => {
  try {
    const { term } = req.params;
    
    const initialLength = vocabularyList.length;
    vocabularyList = vocabularyList.filter(word => word.term !== term);
    
    if (vocabularyList.length === initialLength) {
      return res.status(404).json({ error: 'Word not found in vocabulary' });
    }
    
    return res.status(200).json({ message: 'Word removed from vocabulary' });
  } catch (error) {
    console.error('Error removing from vocabulary:', error);
    return res.status(500).json({ error: 'Error removing from vocabulary' });
  }
};

// Toggle favorite status
exports.toggleFavorite = (req, res) => {
  try {
    const { term, definition } = req.body;
    
    if (!term || !definition) {
      return res.status(400).json({ error: 'Term and definition are required' });
    }
    
    const word = {
      term,
      definition,
      timestamp: new Date()
    };
    
    // Check if word is already a favorite
    const existingIndex = favorites.findIndex(item => item.term === term);
    
    if (existingIndex >= 0) {
      // Remove from favorites
      favorites.splice(existingIndex, 1);
      return res.status(200).json({ 
        message: 'Word removed from favorites', 
        isFavorite: false
      });
    } else {
      // Add to favorites
      favorites.push(word);
      return res.status(200).json({ 
        message: 'Word added to favorites', 
        isFavorite: true
      });
    }
  } catch (error) {
    console.error('Error toggling favorite:', error);
    return res.status(500).json({ error: 'Error toggling favorite' });
  }
};

// Get favorites
exports.getFavorites = (req, res) => {
  return res.status(200).json(favorites);
};

// Add to search history
function addToHistory(word) {
  // Remove if exists to avoid duplicates
  searchHistory = searchHistory.filter(item => item.term !== word.term);
  
  // Add to the beginning
  searchHistory.unshift(word);
  
  // Limit history size
  if (searchHistory.length > 100) {
    searchHistory = searchHistory.slice(0, 100);
  }
}

function stripMarkdown(text) {
  return text
    .replace(/\*\*/g, '')            // Remove **
    .replace(/\*(.*?)\*/g, '$1')     // Italic
    .replace(/_(.*?)_/g, '$1')       // Underline
    .replace(/`(.*?)`/g, '$1')       // Inline code
    .replace(/```[\s\S]*?```/g, '')  // Code blocks
    .replace(/#{1,6}\s/g, '')        // Headers
    .replace(/\[(.*?)\]\(.*?\)/g, '$1') // Links
    .replace(/["'](.*?)["']/g, '$1') // Quotes
    .replace(/\n/g, ' ')             // Newlines to spaces
    .replace(/\s+/g, ' ')            // Multiple spaces to single space
    .trim();
}

// Get search history
exports.getHistory = (req, res) => {
  return res.status(200).json(searchHistory);
};

// Clear search history
exports.clearHistory = (req, res) => {
  searchHistory = [];
  wordAvoidWords.clear(); // Also clear the avoid words map
  return res.status(200).json({ message: 'Search history cleared' });
}; 