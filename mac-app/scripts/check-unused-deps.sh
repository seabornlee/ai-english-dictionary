#!/usr/bin/bash
# check-unused-deps.sh — Verify Xcode-managed packages are imported in Swift source
# Usage: ./scripts/check-unused-deps.sh

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SWIFT_DIR="$PROJECT_DIR/AIDictionary"

if [ ! -d "$SWIFT_DIR" ]; then
    echo "Error: Swift source directory not found at $SWIFT_DIR"
    exit 1
fi

# Known Xcode-managed packages and their import names
declare -A PACKAGE_IMPORTS=(
    ["FirebaseAnalytics"]="FirebaseAnalytics"
    ["FirebaseAuth"]="FirebaseAuth"
    ["FirebaseCore"]="FirebaseCore"
    ["GoogleSignIn"]="GoogleSignIn"
    ["AuthenticationServices"]="AuthenticationServices"
)

UNUSED_COUNT=0

for package in "${!PACKAGE_IMPORTS[@]}"; do
    import_name="${PACKAGE_IMPORTS[$package]}"
    if ! rg -q "import ${import_name}" "$SWIFT_DIR" --type swift 2>/dev/null; then
        echo "⚠️  Package '$package' (import ${import_name}) is not used in any Swift source file"
        UNUSED_COUNT=$((UNUSED_COUNT + 1))
    else
        echo "✅ Package '$package' is imported in Swift source"
    fi
done

if [ "$UNUSED_COUNT" -gt 0 ]; then
    echo ""
    echo "Found $UNUSED_COUNT unused package(s). Consider removing them from Xcode package dependencies."
    exit 1
else
    echo ""
    echo "All Xcode-managed packages are used in Swift source files."
    exit 0
fi
