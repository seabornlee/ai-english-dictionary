require('dotenv').config(); // Load .env file at the very top

const request = require('supertest');
const axios = require('axios');
const sinon = require('sinon');
const mongoose = require('mongoose');
const AvoidWord = require('../src/models/AvoidWord');
const { app, server } = require('../src/index');

// Set test environment variables
process.env.NODE_ENV = 'test';
process.env.MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/ai-dictionary';

describe('Dictionary API Endpoints', async () => {
  let expect;
  let axiosPostStub;

  before(async () => {
    const chai = await import('chai');
    expect = chai.expect;
  });

  after(async () => {
    try {
      // Clear in-memory data
      searchHistory = [];
    } catch (error) {
      console.error('Error in after hook:', error);
      // Don't throw error here to avoid masking test failures
    }
  });

  beforeEach(async () => {
    try {
      // Clear in-memory data
      searchHistory = [];
      
      // Clear database if connected
      if (mongoose.connection.readyState === 1) {
        await AvoidWord.deleteMany({});
      } else {
        console.warn('MongoDB not connected during test setup, skipping database operations');
      }
      
      axiosPostStub = sinon.stub(axios, 'post').resolves({
        data: {
          choices: [{ message: { content: 'A simulated definition.' } }]
        }
      });
    } catch (error) {
      console.error('Error in beforeEach hook:', error);
      throw error;
    }
  });

  afterEach(() => {
    sinon.restore();
  });

  const testWord = {
    term: 'test',
    definition: 'A procedure intended to establish the quality, performance, or reliability of something.',
    timestamp: new Date().toISOString()
  };

  describe('Health Check', () => {
    it('GET /health should return status ok', async () => {
      const response = await request(app).get('/health');
      expect(response.status).to.equal(200);
      expect(response.body).to.have.property('status', 'ok');
    });
  });

  describe('Word Definition', () => {
    it('POST /api/dictionary/define should return a word definition without markdown and quotes', async () => {
      // Mock response with markdown and quotes
      axiosPostStub.resolves({
        data: {
          choices: [{ message: { content: '**"A simulated definition with markdown and quotes."**' } }]
        }
      });

      const response = await request(app)
        .post('/api/dictionary/define')
        .send({ word: 'test' });

      expect(response.status).to.equal(200);
      expect(response.body).to.have.property('term', 'test');
      expect(response.body.definition).to.not.include('**');
      expect(response.body.definition).to.not.include('"');
      expect(response.body.definition).to.equal('A simulated definition with markdown and quotes.');
    });

    it('POST /api/dictionary/define with avoid words should use the avoid list', async () => {
      const response = await request(app)
        .post('/api/dictionary/define')
        .send({
          word: 'test',
          avoidWords: ['procedure', 'quality']
        });

      expect(response.status).to.equal(200);
      expect(response.body).to.have.property('term', 'test');
      expect(response.body).to.have.property('definition');
      expect(response.body).to.have.property('timestamp');

      expect(axiosPostStub.called).to.be.true;
      const lastCallArgs = axiosPostStub.lastCall.args;
      const prompt = lastCallArgs[1].messages[0].content;

      expect(prompt).to.include('avoid using these words');
      expect(prompt).to.include('procedure, quality');
    });

    it('POST /api/dictionary/define should return 400 when no word is provided', async () => {
      const response = await request(app)
        .post('/api/dictionary/define')
        .send({ });

      expect(response.status).to.equal(400);
      expect(response.body).to.have.property('error', 'Word is required');
    });

    it('POST /api/dictionary/define should accumulate avoidWords across multiple requests for the same word', async () => {
      // First request with initial avoid words
      const firstResponse = await request(app)
        .post('/api/dictionary/define')
        .send({
          word: 'test',
          avoidWords: ['first', 'second']
        });

      expect(firstResponse.status).to.equal(200);
      expect(firstResponse.body).to.have.property('term', 'test');
      expect(firstResponse.body).to.have.property('definition');
      expect(firstResponse.body).to.have.property('timestamp');

      // Verify first request was saved to database
      const firstAvoidWord = await AvoidWord.findOne({ word: 'test' });
      expect(firstAvoidWord).to.exist;
      expect(firstAvoidWord.avoidWords).to.have.members(['first', 'second']);

      // Second request with additional avoid words
      const secondResponse = await request(app)
        .post('/api/dictionary/define')
        .send({
          word: 'test',
          avoidWords: ['third', 'fourth']
        });

      expect(secondResponse.status).to.equal(200);
      expect(secondResponse.body).to.have.property('term', 'test');
      expect(secondResponse.body).to.have.property('definition');
      expect(secondResponse.body).to.have.property('timestamp');

      // Verify second request updated database
      const secondAvoidWord = await AvoidWord.findOne({ word: 'test' });
      expect(secondAvoidWord).to.exist;
      expect(secondAvoidWord.avoidWords).to.have.members(['first', 'second', 'third', 'fourth']);

      // Verify that all avoid words were used in the prompt
      expect(axiosPostStub.called).to.be.true;
      const lastCallArgs = axiosPostStub.lastCall.args;
      const prompt = lastCallArgs[1].messages[0].content;

      expect(prompt).to.include('avoid using these words');
      expect(prompt).to.include('first, second, third, fourth');
    });

    it('POST /api/dictionary/define should handle database errors gracefully', async () => {
      // Simulate database error
      const dbError = new Error('Database connection error');
      sinon.stub(AvoidWord, 'findOne').rejects(dbError);

      const response = await request(app)
        .post('/api/dictionary/define')
        .send({
          word: 'test',
          avoidWords: ['error']
        });

      expect(response.status).to.equal(500);
      expect(response.body).to.have.property('error', 'Error defining word');
      expect(response.body).to.have.property('message', dbError.message);

      // Restore stub
      AvoidWord.findOne.restore();
    });
  });

  // Rest of the test cases remain unchanged...
  // Test vocabulary endpoints
  describe('Vocabulary Endpoints', () => {
    it('POST /api/dictionary/vocabulary should add a word to vocabulary', async () => {
      await request(app).delete(`/api/dictionary/vocabulary/${testWord.term}`);

      const response = await request(app)
        .post('/api/dictionary/vocabulary')
        .send(testWord);

      expect(response.status).to.equal(201);
      expect(response.body).to.have.property('term', testWord.term);
    });

    it('POST /api/dictionary/vocabulary should return 400 when term or definition is missing', async () => {
      const response = await request(app)
        .post('/api/dictionary/vocabulary')
        .send({ term: 'test' });

      expect(response.status).to.equal(400);
      expect(response.body).to.have.property('error', 'Term and definition are required');
    });

    it('GET /api/dictionary/vocabulary should return the vocabulary list', async () => {
      await request(app).post('/api/dictionary/vocabulary').send(testWord);

      const response = await request(app).get('/api/dictionary/vocabulary');

      expect(response.status).to.equal(200);
      expect(response.body).to.be.an('array');
      const found = response.body.some(word => word.term === testWord.term);
      expect(found).to.be.true;
    });

    it('DELETE /api/dictionary/vocabulary/:term should remove a word', async () => {
      await request(app).post('/api/dictionary/vocabulary').send(testWord);

      let getResponse = await request(app).get('/api/dictionary/vocabulary');
      const initialLength = getResponse.body.length;
      expect(getResponse.body.some(word => word.term === testWord.term)).to.be.true;

      const deleteResponse = await request(app).delete(`/api/dictionary/vocabulary/${testWord.term}`);
      expect(deleteResponse.status).to.equal(200);
      expect(deleteResponse.body).to.have.property('message', 'Word removed from vocabulary');

      getResponse = await request(app).get('/api/dictionary/vocabulary');
      expect(getResponse.body.length).to.equal(initialLength - 1);
      expect(getResponse.body.some(word => word.term === testWord.term)).to.be.false;
    });

    it('DELETE /api/dictionary/vocabulary/:term should return 404 for non-existent word', async () => {
      await request(app).delete(`/api/dictionary/vocabulary/nonexistentword`);

      const response = await request(app)
        .delete('/api/dictionary/vocabulary/nonexistentword');

      expect(response.status).to.equal(404);
      expect(response.body).to.have.property('error', 'Word not found in vocabulary');
    });
  });

  describe('Favorites Endpoints', () => {
    beforeEach(async () => {
      const favResponse = await request(app).get('/api/dictionary/favorites');
      for (const fav of favResponse.body) {
        await request(app).post('/api/dictionary/favorites').send(fav);
      }
    });

    it('POST /api/dictionary/favorites should add a word to favorites', async () => {
      const response = await request(app)
        .post('/api/dictionary/favorites')
        .send(testWord);

      expect(response.status).to.equal(200);
      expect(response.body).to.have.property('message', 'Word added to favorites');
      expect(response.body).to.have.property('isFavorite', true);

      const getResponse = await request(app).get('/api/dictionary/favorites');
      expect(getResponse.body.some(fav => fav.term === testWord.term)).to.be.true;
    });

    it('POST /api/dictionary/favorites should return 400 when term or definition is missing', async () => {
      const response = await request(app)
        .post('/api/dictionary/favorites')
        .send({ term: 'test' });

      expect(response.status).to.equal(400);
      expect(response.body).to.have.property('error', 'Term and definition are required');
    });

    it('GET /api/dictionary/favorites should return the favorites list', async () => {
      await request(app).post('/api/dictionary/favorites').send(testWord);

      const response = await request(app).get('/api/dictionary/favorites');

      expect(response.status).to.equal(200);
      expect(response.body).to.be.an('array');
      expect(response.body.some(fav => fav.term === testWord.term)).to.be.true;
    });

    it('POST /api/dictionary/favorites should toggle a favorite off if called twice', async () => {
      await request(app).post('/api/dictionary/favorites').send(testWord);
      let getResponse = await request(app).get('/api/dictionary/favorites');
      expect(getResponse.body.some(fav => fav.term === testWord.term)).to.be.true;

      const toggleResponse = await request(app)
        .post('/api/dictionary/favorites')
        .send(testWord);

      expect(toggleResponse.status).to.equal(200);
      expect(toggleResponse.body).to.have.property('message', 'Word removed from favorites');
      expect(toggleResponse.body).to.have.property('isFavorite', false);

      getResponse = await request(app).get('/api/dictionary/favorites');
      expect(getResponse.body.some(fav => fav.term === testWord.term)).to.be.false;
    });
  });

  describe('History Endpoints', () => {
    beforeEach(async () => {
      await request(app).delete('/api/dictionary/history');
    });

    it('GET /api/dictionary/history should return search history', async () => {
      await request(app)
        .post('/api/dictionary/define')
        .send({ word: 'history' });

      const response = await request(app).get('/api/dictionary/history');

      expect(response.status).to.equal(200);
      expect(response.body).to.be.an('array');
      expect(response.body.length).to.be.greaterThan(0);
      expect(response.body[0]).to.have.property('term', 'history');
    });

    it('DELETE /api/dictionary/history should clear search history', async () => {
      await request(app).post('/api/dictionary/define').send({ word: 'some history' });

      let response = await request(app).get('/api/dictionary/history');
      expect(response.body.length).to.be.greaterThan(0);

      const deleteResponse = await request(app).delete('/api/dictionary/history');
      expect(deleteResponse.status).to.equal(200);
      expect(deleteResponse.body).to.have.property('message', 'Search history cleared');

      response = await request(app).get('/api/dictionary/history');
      expect(response.body.length).to.equal(0);
    });
  });
}); 