#!/bin/bash

# Notarize the AI Dictionary Mac app
# Usage: ./scripts/notarize.sh [app-path]

set -e

APP_PATH=${1:-"build/Export/LexisDic.app"}
BUNDLE_ID="site.waterlee.aidic"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}❌ App not found at ${APP_PATH}${NC}"
    exit 1
fi

# Skip notarization if secrets are not set (for Homebrew distribution)
if [ -z "$APPLE_ID" ] || [ -z "$TEAM_ID" ] || [ -z "$APPLE_APP_PASSWORD" ]; then
    echo -e "${YELLOW}⚠️ Notarization skipped - Apple credentials not configured${NC}"
    echo -e "${YELLOW}For Homebrew distribution, notarization is optional${NC}"
    exit 0
fi

echo -e "${GREEN}📦 Notarizing ${APP_PATH}${NC}"

# Create zip for notarization
echo -e "${YELLOW}Creating zip archive...${NC}"
ditto -c -k --keepParent "$APP_PATH" "${APP_PATH}.zip"

# Submit for notarization
echo -e "${YELLOW}Submitting to Apple for notarization...${NC}"
xcrun notarytool submit "${APP_PATH}.zip" \
  --apple-id "${APPLE_ID}" \
  --team-id "${TEAM_ID}" \
  --password "${APPLE_APP_PASSWORD}" \
  --wait

# Staple the notarization ticket
echo -e "${YELLOW}Stapling notarization ticket...${NC}"
xcrun stapler staple "$APP_PATH"

# Verify notarization
echo -e "${YELLOW}Verifying notarization...${NC}"
spctl -a -vv -t install "$APP_PATH"

# Cleanup
rm "${APP_PATH}.zip"

echo -e "${GREEN}✅ Notarization complete${NC}"
