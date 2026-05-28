---
name: troubleshooting
description: Troubleshooting guide for common issues in AI English Dictionary. Use when debugging errors, fixing build failures, or resolving configuration problems.
---

# AI English Dictionary Troubleshooting

## Server Issues

### MongoDB Connection Failed
```bash
cd server
npm run docker:status  # Check if MongoDB is running
npm run docker:restart # Restart MongoDB container
npm run docker:logs    # View MongoDB logs
```

### API Key Issues
- Ensure `SILICONFLOW_API_KEY` is set in `server/.env`
- Copy from `server/src/config/example.env` if missing

### Port Already in Use
```bash
# Find process using port 3000
lsof -i :3000
# Kill the process
kill -9 <PID>
```

### Tests Failing
```bash
cd server
npm run docker:start   # Ensure MongoDB is running
npm test               # Run tests
npm run docker:stop    # Stop MongoDB after tests
```

## macOS App Issues

### Build Failures
1. Clean build folder: `Cmd+Shift+K` in Xcode
2. Delete derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. Re-open project in Xcode

### Code Signing Issues
- Ensure correct Development Team in project settings
- Check entitlements file exists at `AIDictionary/AIDictionary.entitlements`

### SwiftLint/SwiftFormat Not Found
```bash
brew install swiftlint swiftformat
```

## Pre-commit Hook Issues

### Hook Not Running
```bash
cd /path/to/repo
npm install            # Reinstall husky
chmod +x .husky/pre-commit  # Ensure executable
```

### Skipping Hooks (Not Recommended)
```bash
git commit --no-verify -m "message"
```

## TypeScript Errors

### Type Check Failing
```bash
cd server
npm run typecheck      # See all type errors
```

Common fixes:
- Add JSDoc type annotations
- Use type assertions: `/** @type {TypeName} */`
- Add `// @ts-ignore` for unavoidable issues

## Dependency Issues

### npm install Fails
```bash
rm -rf node_modules package-lock.json
npm cache clean --force
npm install
```

### Outdated Dependencies
```bash
npm outdated           # See outdated packages
npm update             # Update within semver range
```
