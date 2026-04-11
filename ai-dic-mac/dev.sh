#!/bin/bash

# Development script: watch Swift files and rebuild/restart automatically
# Usage: ./dev.sh

APP_NAME="AIDictionary"
PID=""
WATCH_DIRS=("AIDictionary")

kill_app() {
    if [ -n "$PID" ]; then
        kill $PID 2>/dev/null
        wait $PID 2>/dev/null
    fi
    pkill -x "$APP_NAME" 2>/dev/null
}

run_app() {
    echo ""
    echo "🔨 Building..."
    if swift build 2>&1; then
        echo "✅ Build successful"
        echo "🚀 Starting app..."
        ./.build/arm64-apple-macosx/debug/$APP_NAME &
        PID=$!
        echo "✨ App running (PID: $PID)"
        echo "👀 Watching for changes (Ctrl+C to stop)..."
    else
        echo "❌ Build failed"
        echo "👀 Watching for changes (fix errors and save)..."
    fi
}

cleanup() {
    echo ""
    echo "🛑 Stopping..."
    kill_app
    exit 0
}

trap cleanup SIGINT SIGTERM

# Initial run
run_app

# Watch for changes
echo ""
fswatch -o "${WATCH_DIRS[@]}" 2>/dev/null | while read -r; do
    echo ""
    echo "📝 Changes detected..."
    kill_app
    sleep 0.3
    run_app
done
