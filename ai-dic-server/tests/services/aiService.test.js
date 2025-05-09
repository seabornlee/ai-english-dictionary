require('dotenv').config();
const { getWordDefinition } = require('../../src/services/aiService.js');

// Make the outer describe async to allow top-level await for import()
describe('AI Service', async function() {
  let expect; // Declare expect here

  // Import chai dynamically before tests run
  before(async () => {
    const chai = await import('chai');
    expect = chai.expect; // Assign expect after import
  });

  // Increase timeout for all tests in this suite
  this.timeout(10000); // 10 seconds timeout

  describe('getWordDefinition', () => {
    it('should return word definition when API call is successful', async () => {
      const result = await getWordDefinition('cat');

      expect(result).to.have.property('term', 'cat');
      expect(result).to.have.property('definition');
      expect(result.definition).to.be.a('string');
      expect(result.definition.length).to.be.greaterThan(0);
      expect(result).to.have.property('timestamp');
      expect(result.timestamp).to.be.instanceOf(Date);
    });

    it('should include unknown words in the definition', async () => {
      const unknownWords = ['animal', 'pet'];
      const result = await getWordDefinition('cat', unknownWords);

      expect(result).to.have.property('term', 'cat');
      expect(result).to.have.property('definition');
      expect(result.definition).to.be.a('string');
      
      // Check that unknown words are not in the definition
      unknownWords.forEach(word => {
        expect(result.definition.toLowerCase()).to.not.include(word.toLowerCase());
      });
    });

    it('should handle API errors gracefully', async () => {
      // Test with an invalid API key to trigger an error
      process.env.DEEPSEEK_API_KEY = 'invalid_key';
      
      try {
        await getWordDefinition('cat');
        expect.fail('Should have thrown an error');
      } catch (error) {
        expect(error).to.be.an('error');
        expect(error.message).to.be.a('string');
      }
    });

    it('should strip markdown formatting from the definition', async () => {
      const result = await getWordDefinition('cat');
    
      expect(result.definition).to.not.include('**');
      expect(result.definition).to.not.include('*');
      expect(result.definition).to.not.include('_');
      expect(result.definition).to.not.include('#');
      expect(result.definition).to.not.include('```');
    });
  });
});