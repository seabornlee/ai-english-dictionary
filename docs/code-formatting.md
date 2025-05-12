# Code Formatting Guidelines

This document outlines the code formatting setup and guidelines for the AI Dictionary project.

## Backend (Node.js) Formatting

The backend server uses Prettier for code formatting. Prettier is a code formatter that enforces a consistent style across your codebase.

### Setup

The project is already configured with Prettier. The configuration can be found in:
- `.prettierrc` - Prettier configuration
- `.prettierignore` - Files and directories to ignore

### Usage

To format your code:

```bash
# Format all files
npm run format

# Check if files are formatted correctly (useful for CI)
npm run format:check
```

### Configuration

Current Prettier settings:
```json
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false,
  "bracketSpacing": true,
  "arrowParens": "avoid",
  "endOfLine": "lf"
}
```

### Ignored Files

The following files and directories are ignored by Prettier:
- `node_modules/`
- `coverage/`
- `.nyc_output/`
- `test-reports/`
- `build/`
- `dist/`
- `*.log`
- `package-lock.json`

## Mac App (Swift) Formatting

The Mac app uses SwiftFormat for code formatting.

### Setup

Install SwiftFormat using Homebrew:
```bash
brew install swiftformat
```

### Usage

To format your Swift code:
```bash
cd ai-dic-mac
swiftformat .
```

## IDE Integration

### VS Code

For the best experience, install the following extensions:
- Prettier - Code formatter
- SwiftFormat

### Xcode

For Xcode, you can set up SwiftFormat to run on save:
1. Install SwiftFormat
2. In Xcode, go to Preferences > Behaviors
3. Add a new behavior for "Saves"
4. Add a Run Script action with:
   ```bash
   swiftformat "${SRCROOT}"
   ```

## CI Integration

The formatting check is integrated into the CI pipeline:
- Backend: `npm run format:check` is run during CI
- Mac App: SwiftFormat is run during the build process

## Best Practices

1. Always format your code before committing
2. Run formatting checks locally before pushing
3. Keep the formatting configuration consistent across the team
4. If you need to modify formatting rules, discuss with the team first 