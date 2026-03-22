# Deployment Guide — AI Dictionary

This document provides instructions for deploying the AI Dictionary Mac app and server infrastructure.

## Overview

- **Mac App**: Distributed as signed and notarized DMG via GitHub Releases
- **Server**: Containerized and deployed to Fly.io
- **Landing Page**: Static HTML site (deploy to Vercel, Netlify, or GitHub Pages)

## Prerequisites

### Mac App Distribution

1. **Apple Developer Account** with Developer ID certificate
2. **App-specific password** for notarization
3. **GitHub repository** with Actions enabled

### Server Deployment

1. **Fly.io account** (sign up at fly.io)
2. **MongoDB Atlas** database (or self-hosted MongoDB)
3. **DeepSeek API key**

## Server Deployment

### 1. Configure Environment Variables

```bash
cd ai-dic-server
cp src/config/example.env .env
```

Edit `.env` with your production values:
```
PORT=3000
NODE_ENV=production
SILICONFLOW_API_KEY=your_deepseek_api_key
MONGODB_URI=your_mongodb_atlas_uri
```

### 2. Deploy to Fly.io

```bash
# Install flyctl (if not already installed)
brew install flyctl

# Login to Fly.io
fly auth login

# Launch the app (first time only)
fly launch

# Set secrets
fly secrets set SILICONFLOW_API_KEY=your_key
fly secrets set MONGODB_URI=your_uri

# Deploy
fly deploy
```

### 3. Verify Deployment

```bash
# Check status
fly status

# View logs
fly logs

# Test health endpoint
curl https://your-app.fly.dev/health
```

## Mac App Build & Distribution

### Manual Build

```bash
cd ai-dic-mac

# Set environment variables
export DEVELOPMENT_TEAM=YOUR_TEAM_ID
export APPLE_ID=your@email.com
export TEAM_ID=YOUR_TEAM_ID
export APPLE_APP_PASSWORD=your-app-specific-password

# Build
./scripts/build-release.sh 1.0.0

# Notarize
./scripts/notarize.sh

# Create DMG
./scripts/create-dmg.sh 1.0.0
```

### Automated Release (GitHub Actions)

1. Push a version tag:
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```

2. GitHub Actions will automatically:
   - Build the app
   - Sign and notarize
   - Create DMG
   - Deploy server
   - Create GitHub Release with DMG attached

### Required GitHub Secrets

Add these secrets to your GitHub repository:

- `DEVELOPMENT_TEAM` — Apple Developer Team ID
- `APPLE_ID` — Apple ID email
- `TEAM_ID` — Same as DEVELOPMENT_TEAM
- `APPLE_APP_PASSWORD` — App-specific password from Apple ID
- `FLY_API_TOKEN` — Fly.io API token (get with `fly auth token`)

## Landing Page Deployment

The landing page is a static HTML file located at `landing-page/index.html`.

### Deploy to Vercel

```bash
cd landing-page
npx vercel --prod
```

### Deploy to Netlify

```bash
cd landing-page
npx netlify deploy --prod --dir=.
```

### Deploy to GitHub Pages

1. Enable GitHub Pages in repository settings
2. Set source to `/landing-page` folder on main branch
3. Site will be available at `https://yourusername.github.io/ai-dictionary`

## Post-Deployment Checklist

### Server

- [ ] Health endpoint returns 200 OK
- [ ] API endpoints respond correctly
- [ ] MongoDB connection stable
- [ ] Logs show no errors
- [ ] SSL certificate valid

### Mac App

- [ ] App launches without warnings
- [ ] Code signature valid (`codesign -dv AIDictionary.app`)
- [ ] Notarization ticket stapled (`spctl -a -vv AIDictionary.app`)
- [ ] DMG mounts and app copies correctly
- [ ] Auto-update mechanism works (if Sparkle enabled)

### Landing Page

- [ ] Site loads over HTTPS
- [ ] Download links point to correct DMG
- [ ] Responsive on mobile devices
- [ ] Analytics tracking (if enabled)

## Troubleshooting

### Notarization Failed

Check notarization history:
```bash
xcrun notarytool history --apple-id YOUR_EMAIL --team-id TEAM_ID
```

### Fly.io Deployment Failed

Check logs:
```bash
fly logs --app ai-dictionary-server
```

### App Shows "Damaged" Warning

The app is not properly notarized. Run:
```bash
xcrun stapler staple AIDictionary.app
```

## Rollback

### Server Rollback

```bash
fly deploy --image flyio/ai-dictionary-server:previous-tag
```

### Mac App Rollback

Delete the problematic GitHub Release and re-run the workflow from the previous tag.

## Support

For deployment issues:
- Check GitHub Actions logs for build errors
- Review Fly.io dashboard for server issues
- Consult Apple Developer documentation for code signing
