const request = require('supertest');
require('./setup');

const app = require('../src/index');

describe('Dictionary API Integration Tests', () => {
  test('Complete user workflow - define, add to favorites, add to vocabulary', async () => {
    // 1. Define a word
    let response = await request(app)
      .post('/api/dictionary/define')
      .send({ word: 'integrate' });
    
    const word = response.body;
    expect(response.status).toBe(200);
    expect(word).toHaveProperty('term', 'integrate');
    expect(word).toHaveProperty('definition');
    
    // 2. Verify it was added to history
    response = await request(app).get('/api/dictionary/history');
    expect(response.status).toBe(200);
    expect(response.body[0]).toHaveProperty('term', 'integrate');
    
    // 3. Add to favorites
    response = await request(app)
      .post('/api/dictionary/favorites')
      .send(word);
    
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('isFavorite', true);
    
    // 4. Verify it's in favorites
    response = await request(app).get('/api/dictionary/favorites');
    expect(response.status).toBe(200);
    const favoriteExists = response.body.some(item => item.term === 'integrate');
    expect(favoriteExists).toBe(true);
    
    // 5. Add to vocabulary
    response = await request(app)
      .post('/api/dictionary/vocabulary')
      .send(word);
    
    expect(response.status).toBe(201);
    
    // 6. Verify it's in vocabulary
    response = await request(app).get('/api/dictionary/vocabulary');
    expect(response.status).toBe(200);
    const vocabExists = response.body.some(item => item.term === 'integrate');
    expect(vocabExists).toBe(true);
    
    // 7. Define word with avoid words
    response = await request(app)
      .post('/api/dictionary/define')
      .send({ 
        word: 'integrate', 
        avoidWords: ['combine', 'incorporate']
      });
    
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('term', 'integrate');
    
    // 8. Remove from vocabulary
    response = await request(app).delete('/api/dictionary/vocabulary/integrate');
    expect(response.status).toBe(200);
    
    // 9. Verify it's removed from vocabulary
    response = await request(app).get('/api/dictionary/vocabulary');
    const vocabRemoved = !response.body.some(item => item.term === 'integrate');
    expect(vocabRemoved).toBe(true);
    
    // 10. Remove from favorites
    response = await request(app)
      .post('/api/dictionary/favorites')
      .send(word);
    
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('isFavorite', false);
    
    // 11. Clear history
    response = await request(app).delete('/api/dictionary/history');
    expect(response.status).toBe(200);
    
    // 12. Verify history is empty
    response = await request(app).get('/api/dictionary/history');
    expect(response.body.length).toBe(0);
  });
}); 