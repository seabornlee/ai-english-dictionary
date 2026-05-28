---
name: dev-workflow
description: Development workflow for AI English Dictionary. Use when setting up, building, testing, or deploying the application.
---

# AI English Dictionary Development Workflow

This skill guides development tasks for the AI English Dictionary monorepo.

## Project Overview

- **mac-app**: SwiftUI macOS application
- **server**: Node.js Express backend
- **chrome-extension**: Browser extension

## Quick Commands

### Server Development
```bash
cd server
npm install
npm run dev          # Start development server
npm test             # Run tests
npm run lint         # Check code style
npm run typecheck    # TypeScript validation
npm run find-dead-code  # Find unused code
```

### macOS App Development
```bash
cd mac-app
swift build          # Build the app
swift test           # Run tests
swiftlint lint --config .swiftlint.yml  # Lint Swift code
swiftformat AIDictionary --config .swiftformat  # Format code
```

### Pre-commit Checks
All commits automatically run:
- ESLint + Prettier for JavaScript
- SwiftFormat + SwiftLint for Swift

## Code Style

### JavaScript/TypeScript
- camelCase for variables and functions
- PascalCase for classes
- Max complexity: 15 per function
- Max file length: 400 lines

### Swift
- Follow Apple's Swift API Design Guidelines
- Max complexity: 15 (warning), 25 (error)
- Use SwiftUI for all new views

## Testing

### Server
- Mocha + Chai for unit tests
- Supertest for API integration tests
- Coverage threshold: 50%
- Tests run in parallel

### macOS
- XCTest for unit tests
- UI tests in AIDictionaryTests/

## Deployment

### Server
- Deployed to Fly.io via GitHub Actions
- Tagged releases trigger deployment

### macOS App
- DMG built and notarized via GitHub Actions
- Distributed via Homebrew tap
