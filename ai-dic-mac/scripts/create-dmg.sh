#!/bin/bash

# Create DMG for AI Dictionary Mac app
# Usage: ./scripts/create-dmg.sh [version]

set -e

VERSION=${1:-$(date +%Y.%m.%d)}
APP_NAME="AIDictionary"
APP_PATH="build/Export/${APP_NAME}.app"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
DMG_PATH="build/${DMG_NAME}"
VOLUME_NAME="AI Dictionary ${VERSION}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}❌ App not found. Run build-release.sh first.${NC}"
    exit 1
fi

echo -e "${GREEN}💿 Creating DMG: ${DMG_NAME}${NC}"

# Create temporary directory for DMG contents
TMP_DIR=$(mktemp -d)
cp -R "$APP_PATH" "$TMP_DIR/"

# Create Applications shortcut
ln -s /Applications "$TMP_DIR/Applications"

# Create the DMG
echo -e "${YELLOW}Creating DMG image...${NC}"
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$TMP_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

# Cleanup
rm -rf "$TMP_DIR"

echo -e "${GREEN}✅ DMG created: ${DMG_PATH}${NC}"
echo -e "${YELLOW}File size: $(du -h "$DMG_PATH" | cut -f1)${NC}"
