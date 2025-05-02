// Mock environment variables for testing
process.env.NODE_ENV = 'test';
process.env.PORT = 3001;

// Mock the DeepSeek API key for testing
if (!process.env.DEEPSEEK_API_KEY) {
  process.env.DEEPSEEK_API_KEY = 'test_api_key';
}

// Mock axios implementation for API calls
jest.mock('axios', () => ({
  post: jest.fn().mockImplementation(() => Promise.resolve({
    data: {
      choices: [
        {
          message: {
            content: 'A test definition created as a mock response.'
          }
        }
      ]
    }
  }))
})); 