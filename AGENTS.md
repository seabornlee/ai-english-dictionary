# Agent Instructions for AI English Dictionary

This document helps autonomous coding agents work effectively with this codebase.

## Project Overview

AI English Dictionary is a macOS application that helps users learn English through pure English explanations (no translations). It consists of:

- **ai-dic-mac**: SwiftUI macOS app with global text selection (Command+D)
- **ai-dic-server**: Node.js Express backend proxying DeepSeek AI API

## Quick Start

### Server (Node.js)

```bash
cd ai-dic-server
npm install
cp src/config/example.env .env
# Add your SILICONFLOW_API_KEY to .env
npm run dev
```

### macOS App (Swift)

```bash
open ai-dic-mac/AIDictionary.xcodeproj
# Build and run in Xcode (Cmd+R)
```

### Local Services

```bash
cd ai-dic-server
docker-compose up -d  # Starts MongoDB on localhost:27017
```

## Build Commands

| Task | Command |
|------|---------|
| Server dev | `cd ai-dic-server && npm run dev` |
| Server tests | `cd ai-dic-server && npm test` |
| Server tests (CI) | `cd ai-dic-server && npm run test:ci` |
| Format code | `cd ai-dic-server && npm run format` |
| Check formatting | `cd ai-dic-server && npm run format:check` |
| Mac app build | `cd ai-dic-mac && swift build` |
| Mac app test | `cd ai-dic-mac && swift test` |

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

### JavaScript (Server)

- Prettier for formatting (config in `.prettierrc`)
- Single quotes, 2-space indent, trailing commas
- Run `npm run format` before committing

### Swift (macOS)

- Follow Apple's Swift API Design Guidelines
- Use SwiftUI for all new views
- Keep views small and composable

## Project Structure

```
ai-dic-repos/
├── ai-dic-mac/           # macOS SwiftUI application
│   ├── AIDictionary/     # Main app source
│   ├── AIDictionaryTests/# Unit tests
│   └── Package.swift     # Swift package manifest
├── ai-dic-server/        # Node.js backend
│   ├── src/
│   │   ├── controllers/  # Request handlers
│   │   ├── models/       # Mongoose schemas
│   │   ├── routes/       # Express routes
│   │   ├── services/     # Business logic
│   │   └── middleware/   # Express middleware
│   └── tests/            # Mocha tests
├── landing-page/         # Marketing site (static HTML)
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

1. Create route handler in `ai-dic-server/src/routes/`
2. Add controller logic in `ai-dic-server/src/controllers/`
3. Write tests in `ai-dic-server/tests/`
4. Run `npm test` to verify

### Adding a New View (macOS)

1. Create SwiftUI view in `ai-dic-mac/AIDictionary/`
2. Follow existing patterns (see `ContentView.swift`)
3. Add tests in `AIDictionaryTests/`
4. Build and test in Xcode

## Troubleshooting

### MongoDB Connection Issues

```bash
cd ai-dic-server
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
