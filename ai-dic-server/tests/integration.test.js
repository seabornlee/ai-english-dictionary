require('dotenv').config(); // Load .env file at the very top

const request = require('supertest');
const {app} = require('../src/index'); // Assuming index exports the app or starts the server

describe('Dictionary API Integration Tests', () => {
  let expect;

  before(async () => {
    const chai = await import('chai');
    expect = chai.expect;
  });

  // Integration tests often benefit from cleaning state before/after
  beforeEach(async () => {
    // Clear vocabulary, favorites, history before each test
    // Note: This assumes DELETE endpoints work correctly, which should be covered by unit tests.
    try {
        await request(app).delete('/api/dictionary/history');
        const vocab = await request(app).get('/api/dictionary/vocabulary');
        for (const word of vocab.body) {
            await request(app).delete(`/api/dictionary/vocabulary/${word.term}`);
        }
        const favs = await request(app).get('/api/dictionary/favorites');
        for (const word of favs.body) {
            // Favorites are toggled via POST
            await request(app).post('/api/dictionary/favorites').send(word);
        }
    } catch (error) {
        console.error("Error during test setup cleanup:", error);
    }
  });

  it('Complete user workflow - define, add to favorites, add to vocabulary', async function() {
    // Increase timeout for this test
    this.timeout(10000);

    // 1. Define a word
    let defineResponse = await request(app)
      .post('/api/dictionary/define')
      .send({ word: 'integrate' });

    const word = defineResponse.body;
    expect(defineResponse.status).to.equal(200);
    expect(word).to.have.property('term', 'integrate');
    expect(word).to.have.property('definition');

    // 2. Verify it was added to history
    let historyResponse = await request(app).get('/api/dictionary/history');
    expect(historyResponse.status).to.equal(200);
    expect(historyResponse.body.some(h => h.term === 'integrate')).to.be.true;

    // 3. Add to favorites
    let favResponse = await request(app)
      .post('/api/dictionary/favorites')
      .send(word);

    expect(favResponse.status).to.equal(200);
    expect(favResponse.body).to.have.property('isFavorite', true);

    // 4. Verify it's in favorites
    favResponse = await request(app).get('/api/dictionary/favorites');
    expect(favResponse.status).to.equal(200);
    const favoriteExists = favResponse.body.some(item => item.term === 'integrate');
    expect(favoriteExists).to.be.true;

    // 5. Add to vocabulary
    let vocabResponse = await request(app)
      .post('/api/dictionary/vocabulary')
      .send(word);

    expect(vocabResponse.status).to.equal(201);

    // 6. Verify it's in vocabulary
    vocabResponse = await request(app).get('/api/dictionary/vocabulary');
    expect(vocabResponse.status).to.equal(200);
    const vocabExists = vocabResponse.body.some(item => item.term === 'integrate');
    expect(vocabExists).to.be.true;

    // 7. Define word with unknown words
    const response7 = await request(app)
      .post('/api/dictionary/define')
      .send({
        word: 'test',
        unknownWords: ['combine', 'incorporate']
      });

    expect(response7.status).to.equal(200);
    expect(response7.body).to.have.property('term', 'test');

    // 8. Remove from vocabulary
    let deleteResponse = await request(app).delete('/api/dictionary/vocabulary/integrate');
    expect(deleteResponse.status).to.equal(200);

    // 9. Verify it's removed from vocabulary
    vocabResponse = await request(app).get('/api/dictionary/vocabulary');
    const vocabRemoved = !vocabResponse.body.some(item => item.term === 'integrate');
    expect(vocabRemoved).to.be.true;

    // 10. Remove from favorites (toggle off)
    favResponse = await request(app)
      .post('/api/dictionary/favorites')
      .send(word);

    expect(favResponse.status).to.equal(200);
    expect(favResponse.body).to.have.property('isFavorite', false);

    // 11. Clear history
    deleteResponse = await request(app).delete('/api/dictionary/history');
    expect(deleteResponse.status).to.equal(200);

    // 12. Verify history is empty
    historyResponse = await request(app).get('/api/dictionary/history');
    expect(historyResponse.body.length).to.equal(0);
  });
});