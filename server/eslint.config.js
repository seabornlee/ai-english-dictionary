const js = require('@eslint/js');

module.exports = [
  js.configs.recommended,
  {
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'commonjs',
      globals: {
        console: 'readonly',
        process: 'readonly',
        module: 'readonly',
        require: 'readonly',
        __dirname: 'readonly',
        Buffer: 'readonly',
        setTimeout: 'readonly',
        clearTimeout: 'readonly',
        setInterval: 'readonly',
        clearInterval: 'readonly',
      },
    },
    rules: {
      // Cyclomatic complexity and code metrics
      // These rules help maintain readable, maintainable code
      complexity: ['error', { max: 15 }], // Cyclomatic complexity threshold
      'max-depth': ['warn', { max: 4 }], // Maximum block nesting depth
      'max-lines': ['warn', { max: 400, skipBlankLines: true, skipComments: true }], // File length
      'max-lines-per-function': ['warn', { max: 60, skipBlankLines: true, skipComments: true }],
      'max-params': ['warn', { max: 5 }], // Function parameter count
      'max-nested-callbacks': ['warn', { max: 4 }], // Callback nesting depth

      // Code quality
      'no-unused-vars': [
        'error',
        {
          argsIgnorePattern: '^_',
          varsIgnorePattern: '^_',
          caughtErrorsIgnorePattern: '^_',
        },
      ],
      'no-console': 'off', // Allow console for server logging
      eqeqeq: ['error', 'always'],
      curly: ['error', 'multi-line'],
      'no-var': 'error',
      'prefer-const': 'error',

      // Naming conventions
      camelcase: [
        'error',
        {
          properties: 'never',
          ignoreDestructuring: false,
          ignoreImports: false,
          ignoreGlobals: false,
          allow: ['^UNSAFE_', '^_id$', '^_v$'], // Allow MongoDB fields and React UNSAFE_ prefix
        },
      ],
      'new-cap': [
        'error',
        {
          newIsCap: true,
          capIsNew: false, // Allow calling capitalized functions without new (e.g., express.Router())
          properties: true,
        },
      ],
      'no-underscore-dangle': [
        'warn',
        {
          allow: ['_id', '_v', '__v', '__dirname', '__filename', '_next'],
          allowAfterThis: true,
          allowAfterSuper: true,
          enforceInMethodNames: false,
        },
      ],
      'id-length': [
        'warn',
        {
          min: 2,
          max: 40,
          exceptions: ['i', 'j', 'k', 'x', 'y', 'z', 'a', 'b', 'c', 'e', 'h', 't', 'n', '_'],
          properties: 'never',
        },
      ],
      'id-match': [
        'warn',
        '^[a-zA-Z_$][a-zA-Z0-9_$]*$', // Valid JavaScript identifiers
        {
          properties: false,
          onlyDeclarations: true,
        },
      ],
    },
  },
  // Test files config
  {
    files: ['tests/**/*.js'],
    languageOptions: {
      globals: {
        describe: 'readonly',
        it: 'readonly',
        before: 'readonly',
        after: 'readonly',
        beforeEach: 'readonly',
        afterEach: 'readonly',
        searchHistory: 'writable',
      },
    },
    rules: {
      'max-lines-per-function': 'off', // Test files can be longer
      'max-lines': 'off',
    },
  },
  {
    ignores: ['node_modules/**', 'coverage/**', 'test-reports/**'],
  },
];
