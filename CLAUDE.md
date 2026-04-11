# AI English Dictionary

## Project Structure

- `ai-dic-mac/` — SwiftUI macOS app (Swift, SPM via Package.swift)
- `ai-dic-server/` — Node.js Express backend (JavaScript)

## Quick Start

```bash
# Server
cd ai-dic-server && npm install && npm run dev

# Mac app — open in Xcode
open ai-dic-mac/AIDictionary.xcodeproj
```

## Build & Test

```bash
# Server tests
cd ai-dic-server && npm test

# CI pipeline
# See Jenkinsfile for full build (Swift + Node.js)
```

## Key Technical Details

- DeepSeek Chat API for word definitions (key in `ai-dic-server/.env`)
- Server: Express + RESTful API on port 3000
- Mac app: SwiftUI, global keyboard shortcuts, `APIService.swift` for server communication

## Rules

- Read files before editing
- Run tests after changes: `cd ai-dic-server && npm test`
- Never commit `.env` or secrets
