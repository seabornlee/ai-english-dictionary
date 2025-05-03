module.exports = {
  testEnvironment: 'node',
  verbose: true,
  collectCoverage: true,
  coverageDirectory: 'coverage',
  testTimeout: 10000,
  coveragePathIgnorePatterns: [
    '/node_modules/'
  ],
  testMatch: [
    '**/tests/**/*.test.js'
  ],
  reporters: [
    'default',
    'jest-junit'
  ],
  testResultsProcessor: 'jest-junit',
  'jest-junit': {
    outputDirectory: process.env.JEST_JUNIT_OUTPUT_DIR || '.',
    outputName: process.env.JEST_JUNIT_OUTPUT_NAME || 'junit.xml',
    classNameTemplate: '{classname}',
    titleTemplate: '{title}',
    ancestorSeparator: ' › ',
    usePathForSuiteName: 'true',
    suiteNameTemplate: '{filename}',
    includeConsoleOutput: true,
    includeShortE2EOutput: true
  }
};