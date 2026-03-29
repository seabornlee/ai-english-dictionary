require('dotenv').config();

const request = require('supertest');
const sinon = require('sinon');
const axios = require('axios');
const { app } = require('../src/index');

describe('Learning content payload', () => {
  let expect;

  before(async () => {
    const chai = await import('chai');
    expect = chai.expect;
  });

  afterEach(() => {
    sinon.restore();
  });

  it('returns pronunciation metadata and explanation sentences for a lookup', async () => {
    sinon.stub(axios, 'post').resolves({
      data: {
        choices: [
          {
            message: {
              content: JSON.stringify({
                definition: 'Giving off a soft, clear light.',
                pronunciation: 'ˈluːmɪnəs',
                partOfSpeech: 'adjective',
                exampleSentences: [
                  'The hallway became luminous at sunrise.',
                  'Her luminous smile calmed the room.',
                ],
              }),
            },
          },
        ],
      },
    });

    const response = await request(app).post('/api/dictionary/define').send({ word: 'luminous' });

    expect(response.status).to.equal(200);
    expect(response.body).to.include({
      term: 'luminous',
      definition: 'Giving off a soft, clear light.',
      pronunciation: 'ˈluːmɪnəs',
      partOfSpeech: 'adjective',
    });
    expect(response.body.exampleSentences).to.deep.equal([
      'The hallway became luminous at sunrise.',
      'Her luminous smile calmed the room.',
    ]);
  });

  it('preserves pronunciation metadata in favorites and vocabulary collections', async () => {
    const storedWord = {
      term: 'luminous',
      definition: 'Giving off a soft, clear light.',
      pronunciation: 'ˈluːmɪnəs',
      partOfSpeech: 'adjective',
      exampleSentences: [
        'The hallway became luminous at sunrise.',
        'Her luminous smile calmed the room.',
      ],
    };

    const favoriteResponse = await request(app).post('/api/dictionary/favorites').send(storedWord);
    expect(favoriteResponse.status).to.equal(200);
    expect(favoriteResponse.body).to.include({ isFavorite: true });

    const favorites = await request(app).get('/api/dictionary/favorites');
    expect(favorites.status).to.equal(200);
    expect(favorites.body[0]).to.include({
      term: storedWord.term,
      definition: storedWord.definition,
      pronunciation: storedWord.pronunciation,
      partOfSpeech: storedWord.partOfSpeech,
    });
    expect(favorites.body[0].exampleSentences).to.deep.equal(storedWord.exampleSentences);

    const vocabularyResponse = await request(app)
      .post('/api/dictionary/vocabulary')
      .send(storedWord);
    expect(vocabularyResponse.status).to.equal(201);
    expect(vocabularyResponse.body).to.include({
      term: storedWord.term,
      definition: storedWord.definition,
      pronunciation: storedWord.pronunciation,
      partOfSpeech: storedWord.partOfSpeech,
    });
    expect(vocabularyResponse.body.exampleSentences).to.deep.equal(storedWord.exampleSentences);

    const vocabulary = await request(app).get('/api/dictionary/vocabulary');
    expect(vocabulary.status).to.equal(200);
    expect(vocabulary.body[0]).to.include({
      term: storedWord.term,
      definition: storedWord.definition,
      pronunciation: storedWord.pronunciation,
      partOfSpeech: storedWord.partOfSpeech,
    });
    expect(vocabulary.body[0].exampleSentences).to.deep.equal(storedWord.exampleSentences);
  });
});
