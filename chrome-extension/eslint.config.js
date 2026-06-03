import js from '@eslint/js'
import globals from 'globals'
import tseslint from 'typescript-eslint'
import prettier from 'eslint-config-prettier'

export default tseslint.config(
  {
    ignores: [
      'dist/**',
      'node_modules/**',
      'test-results/**',
      'playwright-report/**',
      'lexis-dict-v1.0.0/**',
      'store-assets/**',
    ],
  },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: ['**/*.{ts,tsx}'],
    languageOptions: {
      parserOptions: {
        project: './tsconfig.eslint.json',
        tsconfigRootDir: import.meta.dirname,
      },
    },
    rules: {
      complexity: ['error', { max: 12 }],
      'max-lines': ['error', { max: 500, skipBlankLines: true, skipComments: true }],
      'no-warning-comments': [
        'warn',
        {
          terms: ['TODO', 'FIXME', 'HACK'],
          location: 'start',
        },
      ],
      '@typescript-eslint/consistent-type-imports': ['error', { prefer: 'type-imports' }],
      '@typescript-eslint/no-floating-promises': 'error',
      '@typescript-eslint/no-misused-promises': 'error',
      '@typescript-eslint/naming-convention': [
        'error',
        {
          selector: 'default',
          format: ['camelCase'],
          leadingUnderscore: 'allow',
        },
        {
          selector: 'variable',
          format: ['camelCase', 'PascalCase', 'UPPER_CASE'],
          leadingUnderscore: 'allow',
        },
        {
          selector: 'function',
          format: ['camelCase', 'PascalCase'],
        },
        {
          selector: 'typeLike',
          format: ['PascalCase'],
        },
        {
          selector: 'property',
          format: null,
        },
      ],
    },
  },
  {
    files: ['src/**/*.{ts,tsx}', 'vite.config.ts', 'playwright.config.ts'],
    languageOptions: {
      globals: {
        ...globals.browser,
        chrome: 'readonly',
      },
    },
  },
  {
    files: ['api/**/*.js'],
    languageOptions: {
      globals: {
        ...globals.node,
        fetch: 'readonly',
        URLSearchParams: 'readonly',
      },
    },
  },
  {
    // Remotion promo composition: single file with 8 inline scenes
    files: ['src/video/Root.tsx'],
    rules: {
      'max-lines': ['error', { max: 800, skipBlankLines: true, skipComments: true }],
    },
  },
  {
    files: ['e2e/**/*.ts'],
    languageOptions: {
      globals: {
        ...globals.node,
      },
    },
  },
  prettier,
)
