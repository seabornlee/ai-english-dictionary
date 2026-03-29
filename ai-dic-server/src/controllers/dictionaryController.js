const { getWordDefinition } = require('../services/aiService');
const UnknownWord = require('../models/UnknownWord');
const mongoose = require('mongoose');

// In-memory storage for vocabulary, favorites, and history (would be replaced with a database in production)
let vocabularyList = [];
let favorites = [];
let searchHistory = [];

function buildStoredWord(payload) {
  const {
    term,
    definition,
    pronunciation = null,
    partOfSpeech = null,
    exampleSentences = [],
  } = payload;

  return {
    term,
    definition,
    pronunciation,
    partOfSpeech,
    exampleSentences: Array.isArray(exampleSentences) ? exampleSentences : [],
    timestamp: new Date(),
  };
}

// Define a word using DeepSeek Chat API
exports.defineWord = async (req, res) => {
  try {
    const { word, unknownWords = [] } = req.body;

    if (!word) {
      return res.status(400).json({ error: 'Word is required' });
    }

    console.log('Define word request:', word);
    console.log('MongoDB connection state:', mongoose.connection.readyState);

    let unknownWordDoc = null;

    if (mongoose.connection.readyState === 1) {
      try {
        unknownWordDoc = await UnknownWord.findOne({ word });
        console.log('Found existing unknownWordDoc:', !!unknownWordDoc);
      } catch (dbError) {
        console.error('Database find error:', dbError.message);
        unknownWordDoc = null;
      }

      if (!unknownWordDoc) {
        unknownWordDoc = new UnknownWord({
          word,
          unknownWords: unknownWords,
        });
      } else {
        const updatedUnknownWords = [...new Set([...unknownWordDoc.unknownWords, ...unknownWords])];
        unknownWordDoc.unknownWords = updatedUnknownWords;
      }

      try {
        await unknownWordDoc.save();
        console.log('Saved to database');
      } catch (saveError) {
        console.error('Database save error:', saveError.message);
      }
    }

    let allUnknownWordsList = [];
    if (mongoose.connection.readyState === 1) {
      try {
        const allUnknownWords = await UnknownWord.find({});
        allUnknownWordsList = allUnknownWords.reduce((acc, doc) => {
          return [...acc, ...doc.unknownWords];
        }, []);
      } catch (dbError) {
        console.error('Database query error:', dbError.message);
      }
    }

    const result = await getWordDefinition(word, allUnknownWordsList);
    result.definition = stripMarkdown(result.definition);

    // Add to search history
    addToHistory(result);

    console.log('Result:', result);
    return res.status(200).json(result);
  } catch (error) {
    console.error('Error defining word:', error);
    return res.status(500).json({
      error: 'Error defining word',
      message: error.message,
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

    const word = buildStoredWord(req.body);

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

    const word = buildStoredWord(req.body);

    // Check if word is already a favorite
    const existingIndex = favorites.findIndex(item => item.term === term);

    if (existingIndex >= 0) {
      // Remove from favorites
      favorites.splice(existingIndex, 1);
      return res.status(200).json({
        message: 'Word removed from favorites',
        isFavorite: false,
      });
    } else {
      // Add to favorites
      favorites.push(word);
      return res.status(200).json({
        message: 'Word added to favorites',
        isFavorite: true,
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
    .replace(/\*\*/g, '') // Remove **
    .replace(/\*(.*?)\*/g, '$1') // Italic
    .replace(/_(.*?)_/g, '$1') // Underline
    .replace(/`(.*?)`/g, '$1') // Inline code
    .replace(/```[\s\S]*?```/g, '') // Code blocks
    .replace(/#{1,6}\s/g, '') // Headers
    .replace(/\[(.*?)\]\(.*?\)/g, '$1') // Links
    .replace(/["'](.*?)["']/g, '$1') // Quotes
    .replace(/\n/g, ' ') // Newlines to spaces
    .replace(/\s+/g, ' ') // Multiple spaces to single space
    .trim();
}

// Get search history
exports.getHistory = (req, res) => {
  return res.status(200).json(searchHistory);
};

// Clear search history
exports.clearHistory = async (req, res) => {
  try {
    searchHistory = [];

    // Check if mongoose is connected before attempting database operations
    if (mongoose.connection.readyState === 1) {
      await UnknownWord.deleteMany({});
      return res.status(200).json({ message: 'Search history cleared' });
    } else {
      console.warn('MongoDB not connected, skipping database cleanup');
      return res.status(200).json({
        message: 'Search history cleared (in-memory only)',
        warning: 'Database cleanup skipped due to connection issues',
      });
    }
  } catch (error) {
    console.error('Error clearing history:', error);
    return res.status(500).json({
      error: 'Error clearing history',
      message: error.message,
    });
  }
};

// Get all unknown words
exports.getUnknownWords = async (req, res) => {
  try {
    // Get all unknown words documents from database
    const allUnknownWords = await UnknownWord.find({});

    // Flatten and deduplicate the unknown words
    const uniqueUnknownWords = [
      ...new Set(
        allUnknownWords.reduce((acc, doc) => {
          return [...acc, ...doc.unknownWords];
        }, [])
      ),
    ];

    return res.status(200).json(uniqueUnknownWords);
  } catch (error) {
    console.error('Error fetching unknown words:', error);
    return res.status(500).json({
      error: 'Error fetching unknown words',
      message: error.message,
    });
  }
};
