#!/bin/bash
# Deploy to Fly.io - Run this script after installing flyctl

set -e

export PATH="$HOME/.fly/bin:$PATH"

echo "🚀 Deploying AI Dictionary Server to Fly.io"
echo "============================================"

# Check if logged in
echo "Step 1: Checking Fly.io authentication..."
if ! flyctl auth whoami > /dev/null 2>&1; then
    echo "Please login first: flyctl auth login"
    exit 1
fi

# Create app if not exists
echo "Step 2: Creating app..."
if ! flyctl apps list | grep -q "ai-dictionary-server"; then
    flyctl apps create ai-dictionary-server
fi

# Set secrets
echo "Step 3: Setting secrets..."
flyctl secrets set MONGODB_URI="mongodb+srv://hkliya_db_user:eQsJ8ZpRzDu58YAJ@cluster0.pt9s5un.mongodb.net/ai-dictionary?retryWrites=true&w=majority" --app ai-dictionary-server
flyctl secrets set SILICONFLOW_API_KEY="sk-d2e57570cdda41ff8ccb49715b74648c" --app ai-dictionary-server
flyctl secrets set NODE_ENV="production" --app ai-dictionary-server

# Deploy
echo "Step 4: Deploying..."
cd "$(dirname "$0")"
flyctl deploy --app ai-dictionary-server

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Your API is available at:"
echo "  https://ai-dictionary-server.fly.dev"
echo ""
echo "Test it:"
echo "  curl https://ai-dictionary-server.fly.dev/health"
