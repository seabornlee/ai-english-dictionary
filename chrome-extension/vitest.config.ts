import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    globals: true,
    reporter: 'verbose',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      include: ['src/lib/**/*.ts', 'src/**/*.ts'],
      exclude: ['src/**/*.test.ts', 'src/**/*.spec.ts', 'src/types/**'],
      thresholds: {
        lines: 5,
        functions: 3,
        branches: 5,
        statements: 5,
        perFile: {
          'src/lib/auth.ts': {
            lines: 70,
            functions: 80,
            branches: 70,
            statements: 70,
          },
          'src/lib/languages.ts': {
            lines: 90,
            functions: 90,
            branches: 90,
            statements: 90,
          },
        },
      },
    },
  },
})
