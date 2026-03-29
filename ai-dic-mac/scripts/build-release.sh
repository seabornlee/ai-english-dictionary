#!/bin/bash

# Build and sign the AI Dictionary Mac app for distribution
# Usage: ./scripts/build-release.sh [version]

set -e

# Configuration
APP_NAME="AIDictionary"
BUNDLE_ID="site.waterlee.aidic.AIDictionary"
BUILD_DIR="build"
EXPORT_DIR="$BUILD_DIR/Export"
VERSION=${1:-$(date +%Y.%m.%d)}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🏗️  Building AI Dictionary v${VERSION}${NC}"

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$EXPORT_DIR"

# Build the app
echo -e "${YELLOW}Building app...${NC}"
xcodebuild \
  -project "${APP_NAME}.xcodeproj" \
  -scheme "${APP_NAME}" \
  -configuration Release \
  -archivePath "${BUILD_DIR}/${APP_NAME}.xcarchive" \
  archive \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM}"

# Export signed app
echo -e "${YELLOW}Exporting signed app...${NC}"
xcodebuild \
  -exportArchive \
  -archivePath "${BUILD_DIR}/${APP_NAME}.xcarchive" \
  -exportPath "${EXPORT_DIR}" \
  -exportOptionsPlist exportOptions.plist

# Verify code signing
echo -e "${YELLOW}Verifying code signature...${NC}"
codesign -dv --verbose=4 "${EXPORT_DIR}/${APP_NAME}.app"

echo -e "${GREEN}✅ Build complete: ${EXPORT_DIR}/${APP_NAME}.app${NC}"
