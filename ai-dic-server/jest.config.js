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
    outputDirectory: 'test-reports/node',
    outputName: 'junit.xml',
    classNameTemplate: '{classname}',
    titleTemplate: '{title}',
    ancestorSeparator: ' › ',
    usePathForSuiteName: 'true'
  }
};