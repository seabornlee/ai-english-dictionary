require('dotenv').config(); // Load .env file at the very top

const request = require('supertest');
const axios = require('axios');
// Use dynamic import for Chai
// const chai = require('chai'); 
const sinon = require('sinon');
// We will get expect from chai after importing it
// const expect = chai.expect;

const app = require('../src/index');

// Make the outer describe async to allow top-level await for import()
describe('Dictionary API Endpoints', async () => {
  let expect; // Declare expect here
  let axiosPostStub;

  // Import chai dynamically before tests run
  before(async () => {
    const chai = await import('chai');
    expect = chai.expect; // Assign expect after import
  });

  // Setup stubs before tests and restore after
  beforeEach(() => {
    // Stub axios.post to simulate API calls
    axiosPostStub = sinon.stub(axios, 'post').resolves({
      data: {
        choices: [{ message: { content: 'A simulated definition.' } }]
      }
    });
    // Clear any in-memory data if necessary (depends on app implementation)
    // e.g., clear vocabulary, history, favorites arrays/maps in your app logic
  });

  afterEach(() => {
    sinon.restore(); // Restore original functionality
  });

  // Test data for reuse
  const testWord = {
    term: 'test',
    definition: 'A procedure intended to establish the quality, performance, or reliability of something.',
    timestamp: new Date().toISOString() // Use ISO string for consistency
  };

  // Test health check endpoint
  describe('Health Check', () => {
    it('GET /health should return status ok', async () => { // Changed test to it
      const response = await request(app).get('/health');

      expect(response.status).to.equal(200); // Chai assertion
      expect(response.body).to.have.property('status', 'ok'); // Chai assertion
    });
  });

  // Test word definition endpoint
  describe('Word Definition', () => {
    it('POST /api/dictionary/define should return a word definition', async () => { // Changed test to it
      const response = await request(app)
        .post('/api/dictionary/define')
        .send({ word: 'test' });

      expect(response.status).to.equal(200); // Chai assertion
      expect(response.body).to.have.property('term', 'test'); // Chai assertion
      expect(response.body).to.have.property('definition'); // Chai assertion
      expect(response.body).to.have.property('timestamp'); // Chai assertion
    });

    it('POST /api/dictionary/define with avoid words should use the avoid list', async () => { // Changed test to it
      const response = await request(app)
        .post('/api/dictionary/define')
        .send({
          word: 'test',
          avoidWords: ['procedure', 'quality']
        });

      expect(response.status).to.equal(200); // Chai assertion
      expect(response.body).to.have.property('term', 'test'); // Chai assertion
      expect(response.body).to.have.property('definition'); // Chai assertion
      expect(response.body).to.have.property('timestamp'); // Chai assertion

      // Check that axios was called with the avoid words in the prompt using Sinon
      expect(axiosPostStub.called).to.be.true; // Check if stub was called
      const lastCallArgs = axiosPostStub.lastCall.args; // Get arguments of the last call
      const prompt = lastCallArgs[1].messages[0].content; // Assuming structure is [url, data, config]

      expect(prompt).to.include('avoid using these words'); // Chai assertion
      expect(prompt).to.include('procedure, quality'); // Chai assertion
    });

    it('POST /api/dictionary/define should return 400 when no word is provided', async () => { // Changed test to it
      const response = await request(app)
        .post('/api/dictionary/define')
        .send({ });

      expect(response.status).to.equal(400); // Chai assertion
      expect(response.body).to.have.property('error', 'Word is required'); // Chai assertion
    });
  });

  // Test vocabulary endpoints
  describe('Vocabulary Endpoints', () => {
    // Note: These tests assume some in-memory storage in your app.
    // You might need before/after hooks to manage this state.

    it('POST /api/dictionary/vocabulary should add a word to vocabulary', async () => { // Changed test to it
        // Ensure the word is not present before adding
        await request(app).delete(`/api/dictionary/vocabulary/${testWord.term}`);

        const response = await request(app)
            .post('/api/dictionary/vocabulary')
            .send(testWord);

        expect(response.status).to.equal(201); // Chai assertion
        expect(response.body).to.have.property('term', testWord.term); // Chai assertion
        // Comparing dates directly can be tricky, consider checking if it's a valid date string if needed
        // expect(response.body).to.have.property('definition', testWord.definition);
    });


    it('POST /api/dictionary/vocabulary should return 400 when term or definition is missing', async () => { // Changed test to it
      const response = await request(app)
        .post('/api/dictionary/vocabulary')
        .send({ term: 'test' }); // Missing definition

      expect(response.status).to.equal(400); // Chai assertion
      expect(response.body).to.have.property('error', 'Term and definition are required'); // Chai assertion
    });

    it('GET /api/dictionary/vocabulary should return the vocabulary list', async () => { // Changed test to it
        // Add a word first to ensure the list is not empty
        await request(app).post('/api/dictionary/vocabulary').send(testWord);

        const response = await request(app).get('/api/dictionary/vocabulary');

        expect(response.status).to.equal(200); // Chai assertion
        expect(response.body).to.be.an('array'); // Chai assertion

        // Check if the test word is in the array
        const found = response.body.some(word => word.term === testWord.term);
        expect(found).to.be.true;
    });

    it('DELETE /api/dictionary/vocabulary/:term should remove a word', async () => { // Changed test to it
        // Add the word first to ensure it exists
        await request(app).post('/api/dictionary/vocabulary').send(testWord);

        // Check initial state
        let getResponse = await request(app).get('/api/dictionary/vocabulary');
        const initialLength = getResponse.body.length;
        expect(getResponse.body.some(word => word.term === testWord.term)).to.be.true;


        // Now delete it
        const deleteResponse = await request(app).delete(`/api/dictionary/vocabulary/${testWord.term}`);
        expect(deleteResponse.status).to.equal(200); // Chai assertion
        expect(deleteResponse.body).to.have.property('message', 'Word removed from vocabulary'); // Chai assertion

        // Verify it's gone
        getResponse = await request(app).get('/api/dictionary/vocabulary');
        expect(getResponse.body.length).to.equal(initialLength - 1); // Chai assertion
        expect(getResponse.body.some(word => word.term === testWord.term)).to.be.false;
    });


    it('DELETE /api/dictionary/vocabulary/:term should return 404 for non-existent word', async () => { // Changed test to it
       // Ensure the word doesn't exist first
       await request(app).delete(`/api/dictionary/vocabulary/nonexistentword`);

      const response = await request(app)
        .delete('/api/dictionary/vocabulary/nonexistentword');

      expect(response.status).to.equal(404); // Chai assertion
      expect(response.body).to.have.property('error', 'Word not found in vocabulary'); // Chai assertion
    });
  });

  // Test favorites endpoints
  describe('Favorites Endpoints', () => {
      // Assume favorites state is managed similarly to vocabulary

      beforeEach(async () => {
          // Clean up favorites before each test in this suite
          const favResponse = await request(app).get('/api/dictionary/favorites');
          for (const fav of favResponse.body) {
              await request(app).post('/api/dictionary/favorites').send(fav); // Toggle off
          }
      });

      it('POST /api/dictionary/favorites should add a word to favorites', async () => { // Changed test to it
          const response = await request(app)
              .post('/api/dictionary/favorites')
              .send(testWord);

          expect(response.status).to.equal(200); // Chai assertion
          expect(response.body).to.have.property('message', 'Word added to favorites'); // Chai assertion
          expect(response.body).to.have.property('isFavorite', true); // Chai assertion

          // Verify it's in the list
           const getResponse = await request(app).get('/api/dictionary/favorites');
           expect(getResponse.body.some(fav => fav.term === testWord.term)).to.be.true;
      });

      it('POST /api/dictionary/favorites should return 400 when term or definition is missing', async () => { // Changed test to it
          const response = await request(app)
              .post('/api/dictionary/favorites')
              .send({ term: 'test' }); // Missing definition

          expect(response.status).to.equal(400); // Chai assertion
          expect(response.body).to.have.property('error', 'Term and definition are required'); // Chai assertion
      });

      it('GET /api/dictionary/favorites should return the favorites list', async () => { // Changed test to it
          // Add a favorite first
          await request(app).post('/api/dictionary/favorites').send(testWord);

          const response = await request(app).get('/api/dictionary/favorites');

          expect(response.status).to.equal(200); // Chai assertion
          expect(response.body).to.be.an('array'); // Chai assertion
          expect(response.body.some(fav => fav.term === testWord.term)).to.be.true;
      });

       it('POST /api/dictionary/favorites should toggle a favorite off if called twice', async () => { // Changed test to it
           // First call adds the word
           await request(app).post('/api/dictionary/favorites').send(testWord);
           let getResponse = await request(app).get('/api/dictionary/favorites');
           expect(getResponse.body.some(fav => fav.term === testWord.term)).to.be.true;


           // Second call should remove it
           const toggleResponse = await request(app)
               .post('/api/dictionary/favorites')
               .send(testWord);

           expect(toggleResponse.status).to.equal(200); // Chai assertion
           expect(toggleResponse.body).to.have.property('message', 'Word removed from favorites'); // Chai assertion
           expect(toggleResponse.body).to.have.property('isFavorite', false); // Chai assertion

           // Verify it's gone from favorites
           getResponse = await request(app).get('/api/dictionary/favorites');
           expect(getResponse.body.some(fav => fav.term === testWord.term)).to.be.false;
       });

  });

  // Test history endpoints
  describe('History Endpoints', () => {
      // Assume history is managed in-memory

      beforeEach(async () => {
        // Clear history before each test
        await request(app).delete('/api/dictionary/history');
      });

      it('GET /api/dictionary/history should return search history', async () => { // Changed test to it
          // Define a word first to create some history
          await request(app)
              .post('/api/dictionary/define')
              .send({ word: 'history' });

          const response = await request(app).get('/api/dictionary/history');

          expect(response.status).to.equal(200); // Chai assertion
          expect(response.body).to.be.an('array'); // Chai assertion
          expect(response.body.length).to.be.greaterThan(0); // Chai assertion

          // The most recent search should be 'history'
          expect(response.body[0]).to.have.property('term', 'history'); // Chai assertion
      });


      it('DELETE /api/dictionary/history should clear search history', async () => { // Changed test to it
          // Add some history first
          await request(app).post('/api/dictionary/define').send({ word: 'some history' });

          // Check we have history
          let response = await request(app).get('/api/dictionary/history');
          expect(response.body.length).to.be.greaterThan(0); // Chai assertion

          // Clear the history
          const deleteResponse = await request(app).delete('/api/dictionary/history');
          expect(deleteResponse.status).to.equal(200); // Chai assertion
          expect(deleteResponse.body).to.have.property('message', 'Search history cleared'); // Chai assertion

          // Verify it's cleared
          response = await request(app).get('/api/dictionary/history');
          expect(response.body.length).to.equal(0); // Chai assertion
      });
  });
}); 