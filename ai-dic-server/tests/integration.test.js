require('dotenv').config(); // Load .env file at the very top

const request = require('supertest');
const axios = require('axios'); // Need axios to stub it
const sinon = require('sinon'); // Need sinon for stubbing
// Use dynamic import for Chai
// const chai = require('chai');
// We will get expect from chai after importing it
// const expect = chai.expect;

const app = require('../src/index'); // Assuming index exports the app or starts the server

// Make the outer describe async to allow top-level await for import()
describe('Dictionary API Integration Tests', async () => {
  let expect; // Declare expect here
  let axiosPostStub; // Declare stub variable

  // Import chai dynamically before tests run
  before(async () => {
    const chai = await import('chai');
    expect = chai.expect; // Assign expect after import
  });

  // Integration tests often benefit from cleaning state before/after
  beforeEach(async () => {
    // Stub axios.post to prevent real API calls
    axiosPostStub = sinon.stub(axios, 'post').resolves({
      data: {
        choices: [{ message: { content: 'A simulated integration definition.' } }]
      }
    });

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

  // Restore axios after each test
  afterEach(() => {
    sinon.restore();
  });

  it('Complete user workflow - define, add to favorites, add to vocabulary', async () => { // Changed test to it
    // 1. Define a word
    let defineResponse = await request(app)
      .post('/api/dictionary/define')
      .send({ word: 'integrate' });

    const word = defineResponse.body;
    expect(defineResponse.status).to.equal(200); // Chai assertion
    expect(word).to.have.property('term', 'integrate'); // Chai assertion
    expect(word).to.have.property('definition'); // Chai assertion

    // 2. Verify it was added to history
    let historyResponse = await request(app).get('/api/dictionary/history');
    expect(historyResponse.status).to.equal(200); // Chai assertion
    // Check if the word is present in history (order might not be guaranteed)
    expect(historyResponse.body.some(h => h.term === 'integrate')).to.be.true;

    // 3. Add to favorites
    let favResponse = await request(app)
      .post('/api/dictionary/favorites')
      .send(word);

    expect(favResponse.status).to.equal(200); // Chai assertion
    expect(favResponse.body).to.have.property('isFavorite', true); // Chai assertion

    // 4. Verify it's in favorites
    favResponse = await request(app).get('/api/dictionary/favorites');
    expect(favResponse.status).to.equal(200); // Chai assertion
    const favoriteExists = favResponse.body.some(item => item.term === 'integrate');
    expect(favoriteExists).to.be.true; // Chai assertion

    // 5. Add to vocabulary
    let vocabResponse = await request(app)
      .post('/api/dictionary/vocabulary')
      .send(word);

    expect(vocabResponse.status).to.equal(201); // Chai assertion

    // 6. Verify it's in vocabulary
    vocabResponse = await request(app).get('/api/dictionary/vocabulary');
    expect(vocabResponse.status).to.equal(200); // Chai assertion
    const vocabExists = vocabResponse.body.some(item => item.term === 'integrate');
    expect(vocabExists).to.be.true; // Chai assertion

    // 7. Define word with avoid words (Re-defining won't change existing stored word, just history)
    defineResponse = await request(app)
      .post('/api/dictionary/define')
      .send({
        word: 'integrate',
        avoidWords: ['combine', 'incorporate']
      });

    expect(defineResponse.status).to.equal(200); // Chai assertion
    expect(defineResponse.body).to.have.property('term', 'integrate'); // Chai assertion

    // 8. Remove from vocabulary
    let deleteResponse = await request(app).delete('/api/dictionary/vocabulary/integrate');
    expect(deleteResponse.status).to.equal(200); // Chai assertion

    // 9. Verify it's removed from vocabulary
    vocabResponse = await request(app).get('/api/dictionary/vocabulary');
    const vocabRemoved = !vocabResponse.body.some(item => item.term === 'integrate');
    expect(vocabRemoved).to.be.true; // Chai assertion

    // 10. Remove from favorites (toggle off)
    favResponse = await request(app)
      .post('/api/dictionary/favorites')
      .send(word);

    expect(favResponse.status).to.equal(200); // Chai assertion
    expect(favResponse.body).to.have.property('isFavorite', false); // Chai assertion

    // 11. Clear history
    deleteResponse = await request(app).delete('/api/dictionary/history');
    expect(deleteResponse.status).to.equal(200); // Chai assertion

    // 12. Verify history is empty
    historyResponse = await request(app).get('/api/dictionary/history');
    expect(historyResponse.body.length).to.equal(0); // Chai assertion
  });
}); 