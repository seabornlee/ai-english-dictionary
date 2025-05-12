const express = require('express');
const router = express.Router();
const dictionaryController = require('../controllers/dictionaryController');

// Route to define a word
router.post('/define', dictionaryController.defineWord);

// Route to save a word to vocabulary
router.post('/vocabulary', dictionaryController.addToVocabulary);

// Route to get vocabulary list
router.get('/vocabulary', dictionaryController.getVocabulary);

// Route to delete a word from vocabulary
router.delete('/vocabulary/:term', dictionaryController.removeFromVocabulary);

// Route to manage favorites
router.post('/favorites', dictionaryController.toggleFavorite);
router.get('/favorites', dictionaryController.getFavorites);

// Route to get search history
router.get('/history', dictionaryController.getHistory);
router.delete('/history', dictionaryController.clearHistory);

// Route to get all unknown words
router.get('/unknown-words', dictionaryController.getUnknownWords);

module.exports = router;
