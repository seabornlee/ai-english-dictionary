const request = require('supertest');
const axios = require('axios');
require('./setup');

const app = require('../src/index');

describe('Dictionary API Endpoints', () => {
  // Test data for reuse
  const testWord = {
    term: 'test',
    definition: 'A procedure intended to establish the quality, performance, or reliability of something.',
    timestamp: new Date()
  };

  // Test health check endpoint
  describe('Health Check', () => {
    test('GET /health should return status ok', async () => {
      const response = await request(app).get('/health');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('status', 'ok');
    });
  });

  // Test word definition endpoint
  describe('Word Definition', () => {
    test('POST /api/dictionary/define should return a word definition', async () => {
      const response = await request(app)
        .post('/api/dictionary/define')
        .send({ word: 'test' });
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('term', 'test');
      expect(response.body).toHaveProperty('definition');
      expect(response.body).toHaveProperty('timestamp');
    });

    test('POST /api/dictionary/define with avoid words should use the avoid list', async () => {
      const response = await request(app)
        .post('/api/dictionary/define')
        .send({ 
          word: 'test', 
          avoidWords: ['procedure', 'quality'] 
        });
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('term', 'test');
      expect(response.body).toHaveProperty('definition');
      expect(response.body).toHaveProperty('timestamp');
      
      // Check that axios was called with the avoid words in the prompt
      expect(axios.post).toHaveBeenCalled();
      const axiosCall = axios.post.mock.calls[axios.post.mock.calls.length - 1];
      const prompt = axiosCall[1].messages[0].content;
      
      expect(prompt).toContain('avoid using these words');
      expect(prompt).toContain('procedure, quality');
    });

    test('POST /api/dictionary/define should return 400 when no word is provided', async () => {
      const response = await request(app)
        .post('/api/dictionary/define')
        .send({ });
      
      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error', 'Word is required');
    });
  });

  // Test vocabulary endpoints
  describe('Vocabulary Endpoints', () => {
    test('POST /api/dictionary/vocabulary should add a word to vocabulary', async () => {
      const response = await request(app)
        .post('/api/dictionary/vocabulary')
        .send(testWord);
      
      expect(response.status).toBe(201);
      expect(response.body).toHaveProperty('term', testWord.term);
      expect(response.body).toHaveProperty('definition', testWord.definition);
    });

    test('POST /api/dictionary/vocabulary should return 400 when term or definition is missing', async () => {
      const response = await request(app)
        .post('/api/dictionary/vocabulary')
        .send({ term: 'test' });
      
      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error', 'Term and definition are required');
    });

    test('GET /api/dictionary/vocabulary should return the vocabulary list', async () => {
      const response = await request(app)
        .get('/api/dictionary/vocabulary');
      
      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
      
      // There should be at least the test word we added
      expect(response.body.length).toBeGreaterThan(0);
      expect(response.body[0]).toHaveProperty('term', testWord.term);
    });

    test('DELETE /api/dictionary/vocabulary/:term should remove a word', async () => {
      // First check that the word exists
      let response = await request(app).get('/api/dictionary/vocabulary');
      const initialLength = response.body.length;
      
      // Now delete it
      response = await request(app).delete(`/api/dictionary/vocabulary/${testWord.term}`);
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message', 'Word removed from vocabulary');
      
      // Verify it's gone
      response = await request(app).get('/api/dictionary/vocabulary');
      expect(response.body.length).toBe(initialLength - 1);
    });

    test('DELETE /api/dictionary/vocabulary/:term should return 404 for non-existent word', async () => {
      const response = await request(app)
        .delete('/api/dictionary/vocabulary/nonexistentword');
      
      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty('error', 'Word not found in vocabulary');
    });
  });

  // Test favorites endpoints
  describe('Favorites Endpoints', () => {
    test('POST /api/dictionary/favorites should add a word to favorites', async () => {
      const response = await request(app)
        .post('/api/dictionary/favorites')
        .send(testWord);
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message', 'Word added to favorites');
      expect(response.body).toHaveProperty('isFavorite', true);
    });

    test('POST /api/dictionary/favorites should return 400 when term or definition is missing', async () => {
      const response = await request(app)
        .post('/api/dictionary/favorites')
        .send({ term: 'test' });
      
      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error', 'Term and definition are required');
    });

    test('GET /api/dictionary/favorites should return the favorites list', async () => {
      const response = await request(app)
        .get('/api/dictionary/favorites');
      
      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
      
      // There should be at least the test word we added
      expect(response.body.length).toBeGreaterThan(0);
      expect(response.body[0]).toHaveProperty('term', testWord.term);
    });

    test('POST /api/dictionary/favorites should toggle a favorite off if called twice', async () => {
      // First call added the word (in previous test)
      // Second call should remove it
      const response = await request(app)
        .post('/api/dictionary/favorites')
        .send(testWord);
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message', 'Word removed from favorites');
      expect(response.body).toHaveProperty('isFavorite', false);
      
      // Verify it's gone from favorites
      const checkResponse = await request(app).get('/api/dictionary/favorites');
      const hasFavorite = checkResponse.body.some(word => word.term === testWord.term);
      expect(hasFavorite).toBe(false);
    });
  });

  // Test history endpoints
  describe('History Endpoints', () => {
    test('GET /api/dictionary/history should return search history', async () => {
      // Define a word first to create some history
      await request(app)
        .post('/api/dictionary/define')
        .send({ word: 'history' });
      
      const response = await request(app).get('/api/dictionary/history');
      
      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.length).toBeGreaterThan(0);
      
      // The most recent search should be 'history'
      expect(response.body[0]).toHaveProperty('term', 'history');
    });

    test('DELETE /api/dictionary/history should clear search history', async () => {
      // First check we have history
      let response = await request(app).get('/api/dictionary/history');
      expect(response.body.length).toBeGreaterThan(0);
      
      // Clear the history
      response = await request(app).delete('/api/dictionary/history');
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message', 'Search history cleared');
      
      // Verify it's cleared
      response = await request(app).get('/api/dictionary/history');
      expect(response.body.length).toBe(0);
    });
  });
}); 