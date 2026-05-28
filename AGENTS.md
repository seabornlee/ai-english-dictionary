# Agent Instructions for AI English Dictionary

This document helps autonomous coding agents work effectively with this codebase.

## Project Overview

AI English Dictionary is a macOS application that helps users learn English through pure English explanations (no translations). It consists of:

- **mac-app**: SwiftUI macOS app with global text selection (Command+D)
- **server**: Node.js Express backend proxying DeepSeek AI API
- **chrome-extension**: Chrome extension for browser integration

## Quick Start

### Server (Node.js)

```bash
cd server
npm install
cp src/config/example.env .env
# Add your SILICONFLOW_API_KEY to .env
npm run dev
```

### macOS App (Swift)

```bash
open mac-app/AIDictionary.xcodeproj
# Build and run in Xcode (Cmd+R)
```

### Local Services

```bash
cd server
docker-compose up -d  # Starts MongoDB on localhost:27017
```

## Build Commands

| Task | Command |
|------|---------|
| Server dev | `cd server && npm run dev` |
| Server tests | `cd server && npm test` |
| Server tests (CI) | `cd server && npm run test:ci` |
| Format code | `cd server && npm run format` |
| Check formatting | `cd server && npm run format:check` |
| Find dead code | `cd server && npm run find-dead-code` |
| Find duplicates | `cd server && npm run find-duplicates` |
| Mac app build | `cd mac-app && swift build` |
| Mac app test | `cd mac-app && swift test` |
| Mac app format | `cd mac-app && swiftformat AIDictionary --config .swiftformat` |
| Mac app format (check) | `cd mac-app && swiftformat AIDictionary --config .swiftformat --lint` |
| Mac app lint | `cd mac-app && swiftlint lint --config .swiftlint.yml` |
| Mac app lint (strict) | `cd mac-app && swiftlint lint --config .swiftlint.yml --strict` |
| Server typecheck | `cd server && npm run typecheck` |

## Testing

### Server Tests

```bash
cd ai-dic-server
npm run docker:start   # Start MongoDB
npm test               # Run tests
npm run docker:stop    # Stop MongoDB
```

Tests are in `ai-dic-server/tests/`:
- `dictionary.test.js` - Dictionary API endpoints
- `integration.test.js` - Integration tests
- `learning-content.test.js` - Learning content features
- `services/aiService.test.js` - AI service unit tests

### macOS Tests

```bash
cd ai-dic-mac
swift test
```

Tests are in `ai-dic-mac/AIDictionaryTests/`.

## Code Style

### Pre-commit Hooks

The repository uses Husky + lint-staged to enforce code quality on every commit:
- **JavaScript/TypeScript files**: ESLint + Prettier auto-fix
- **Swift files**: SwiftFormat + SwiftLint

Pre-commit hooks run automatically. To skip (not recommended): `git commit --no-verify`

### JavaScript/TypeScript (Server)

- TypeScript for type checking with strict mode (`tsconfig.json`)
- Run `npm run typecheck` before committing
- Prettier for formatting (config in `.prettierrc`)
- Single quotes, 2-space indent, trailing commas
- Run `npm run format` before committing
- Use JSDoc annotations for type hints in JavaScript files

**Naming Conventions (enforced by ESLint):**
- Variables and functions: `camelCase` (e.g., `getUserById`, `isValid`)
- Classes and constructors: `PascalCase` (e.g., `UserService`, `ApiError`)
- Constants: `camelCase` or `SCREAMING_SNAKE_CASE` for true constants (e.g., `maxRetries`, `API_VERSION`)
- Private/internal: prefix with `_` only when necessary (e.g., `_internalHelper`)
- File names: `camelCase.js` for modules, `PascalCase.js` for classes
- MongoDB fields: `_id`, `__v` are allowed exceptions

**Code Complexity Limits (enforced by ESLint):**
- Cyclomatic complexity: max 15 per function (error)
- Max nesting depth: 4 levels (warning)
- Max lines per function: 60 (warning)
- Max file length: 400 lines (warning)
- Max function parameters: 5 (warning)

### Swift (macOS)

- SwiftFormat for code formatting (config in `mac-app/.swiftformat`)
- SwiftLint for linting (config in `mac-app/.swiftlint.yml`)
- Run `swiftformat AIDictionary --config .swiftformat` to format code
- Run `swiftlint lint --config .swiftlint.yml` before committing
- Follow Apple's Swift API Design Guidelines
- Use SwiftUI for all new views
- Keep views small and composable

## Project Structure

```
ai-dic-repos/
├── mac-app/              # macOS SwiftUI application
│   ├── AIDictionary/     # Main app source
│   ├── AIDictionaryTests/# Unit tests
│   ├── .swiftlint.yml    # SwiftLint configuration
│   ├── .swiftformat      # SwiftFormat configuration
│   └── Package.swift     # Swift package manifest
├── server/               # Node.js backend
│   ├── src/
│   │   ├── controllers/  # Request handlers
│   │   ├── models/       # Mongoose schemas
│   │   ├── routes/       # Express routes
│   │   ├── services/     # Business logic
│   │   └── middleware/   # Express middleware
│   ├── tests/            # Mocha tests
│   ├── eslint.config.js  # ESLint configuration
│   ├── tsconfig.json     # TypeScript configuration
│   └── knip.json         # Dead code detection config
├── chrome-extension/     # Browser extension
├── landing-page/         # Marketing site (static HTML)
├── .github/              # GitHub configuration
│   ├── workflows/        # CI/CD workflows
│   ├── ISSUE_TEMPLATE/   # Issue templates
│   ├── CODEOWNERS        # Code ownership
│   ├── dependabot.yml    # Dependency updates
│   └── pull_request_template.md
└── docs/                 # Documentation
```

## Environment Variables

### Server (.env)

| Variable | Description | Required |
|----------|-------------|----------|
| `PORT` | Server port (default: 3000) | No |
| `NODE_ENV` | Environment (development/production) | No |
| `SILICONFLOW_API_KEY` | DeepSeek AI API key | Yes |
| `MONGODB_URI` | MongoDB connection string | Yes |

## API Endpoints

### Dictionary

- `GET /api/dictionary/define/:word` - Get word definition
- `GET /api/dictionary/unknown-words` - List unknown words
- `POST /api/dictionary/unknown-words` - Add unknown word
- `DELETE /api/dictionary/unknown-words/:word` - Remove unknown word

### Health

- `GET /health` - Health check (returns MongoDB status)

## CI/CD

- **Jenkins**: Builds and tests both apps on macOS agent
- **GitHub Actions**: Release workflow for tagged versions
  - Builds DMG, notarizes, creates GitHub release
  - Deploys server to Fly.io
  - Updates Homebrew tap

## Common Tasks

### Adding a New API Endpoint

1. Create route handler in `server/src/routes/`
2. Add controller logic in `server/src/controllers/`
3. Write tests in `server/tests/`
4. Run `npm test` to verify

### Adding a New View (macOS)

1. Create SwiftUI view in `mac-app/AIDictionary/`
2. Follow existing patterns (see `ContentView.swift`)
3. Add tests in `AIDictionaryTests/`
4. Build and test in Xcode

## Troubleshooting

### MongoDB Connection Issues

```bash
cd server
npm run docker:status  # Check if MongoDB is running
npm run docker:logs    # View MongoDB logs
npm run docker:restart # Restart MongoDB
```

### Xcode Build Issues

1. Clean build folder: `Cmd+Shift+K`
2. Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
3. Re-open project in Xcode

## Security Notes

- Never commit `.env` files or API keys
- Use `example.env` as template for required variables
- Server uses `helmet` for security headers
- All API routes require license validation middleware

## Additional Documentation

- [Architecture Overview](docs/architecture.md) - System design, data flow, and deployment
- [Runbooks](docs/runbooks/) - Incident response and operational procedures
- [Skills](.factory/skills/) - Development workflow and troubleshooting guides

## Observability

### Logging
The server uses [Pino](https://github.com/pinojs/pino) for structured logging with automatic sensitive data redaction.

```javascript
const { logger } = require('./lib/logger');
logger.info({ userId: '123' }, 'User action completed');
```

Redacted fields: password, token, authorization, apiKey, secret, creditCard, ssn, email

### Health Check
```bash
curl https://ai-dic-server.fly.dev/health
# Returns: { "status": "ok", "mongo": "connected", "state": 1 }
```
