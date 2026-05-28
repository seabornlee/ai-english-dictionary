const express = require('express');

const router = express.Router();

// All routes require auth middleware (applied in index.js)

// Get vocabulary
router.get('/vocabulary', async (req, res) => {
  try {
    res.json({ vocabulary: req.user.vocabulary || [] });
  } catch (error) {
    console.error('Get vocabulary error:', error);
    res.status(500).json({ error: 'Failed to get vocabulary', code: 'GET_VOCABULARY_ERROR' });
  }
});

// Update vocabulary (full replace)
router.put('/vocabulary', async (req, res) => {
  try {
    const { vocabulary } = req.body;

    if (!Array.isArray(vocabulary)) {
      return res.status(400).json({ error: 'Vocabulary must be an array', code: 'INVALID_VOCABULARY' });
    }

    req.user.vocabulary = vocabulary;
    await req.user.save();

    res.json({ success: true, count: vocabulary.length });
  } catch (error) {
    console.error('Update vocabulary error:', error);
    res.status(500).json({ error: 'Failed to update vocabulary', code: 'UPDATE_VOCABULARY_ERROR' });
  }
});

// Get history
router.get('/history', async (req, res) => {
  try {
    res.json({ history: req.user.history || [] });
  } catch (error) {
    console.error('Get history error:', error);
    res.status(500).json({ error: 'Failed to get history', code: 'GET_HISTORY_ERROR' });
  }
});

// Update history (full replace)
router.put('/history', async (req, res) => {
  try {
    const { history } = req.body;

    if (!Array.isArray(history)) {
      return res.status(400).json({ error: 'History must be an array', code: 'INVALID_HISTORY' });
    }

    req.user.history = history;
    await req.user.save();

    res.json({ success: true, count: history.length });
  } catch (error) {
    console.error('Update history error:', error);
    res.status(500).json({ error: 'Failed to update history', code: 'UPDATE_HISTORY_ERROR' });
  }
});

// Get favorites
router.get('/favorites', async (req, res) => {
  try {
    res.json({ favorites: req.user.favorites || [] });
  } catch (error) {
    console.error('Get favorites error:', error);
    res.status(500).json({ error: 'Failed to get favorites', code: 'GET_FAVORITES_ERROR' });
  }
});

// Update favorites (full replace)
router.put('/favorites', async (req, res) => {
  try {
    const { favorites } = req.body;

    if (!Array.isArray(favorites)) {
      return res.status(400).json({ error: 'Favorites must be an array', code: 'INVALID_FAVORITES' });
    }

    req.user.favorites = favorites;
    await req.user.save();

    res.json({ success: true, count: favorites.length });
  } catch (error) {
    console.error('Update favorites error:', error);
    res.status(500).json({ error: 'Failed to update favorites', code: 'UPDATE_FAVORITES_ERROR' });
  }
});

module.exports = router;