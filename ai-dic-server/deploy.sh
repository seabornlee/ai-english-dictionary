#!/bin/bash
# Deploy AI Dictionary Server to Fly.io
# Run this script after setting up MongoDB Atlas

set -e

echo "🚀 AI Dictionary Server Deployment Script"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_flyctl() {
    if ! command -v flyctl &> /dev/null; then
        echo -e "${YELLOW}flyctl not found. Installing...${NC}"
        curl -L https://fly.io/install.sh | sh
        export PATH="$HOME/.fly/bin:$PATH"
    fi
}

check_docker() {
    if ! docker info &> /dev/null; then
        echo -e "${RED}Error: Docker is not running${NC}"
        exit 1
    fi
}

echo "Step 1: Checking prerequisites..."
check_flyctl
check_docker
echo -e "${GREEN}✓ Prerequisites OK${NC}"
echo ""

echo "Step 2: Building Docker image..."
cd "$(dirname "$0")"
docker build -t ai-dictionary-server:latest .
echo -e "${GREEN}✓ Docker image built${NC}"
echo ""

echo "Step 3: Checking Fly.io authentication..."
if ! flyctl auth whoami &> /dev/null; then
    echo -e "${YELLOW}Please login to Fly.io:${NC}"
    flyctl auth login
fi
echo -e "${GREEN}✓ Authenticated with Fly.io${NC}"
echo ""

echo "Step 4: Creating Fly.io app (if not exists)..."
if ! flyctl apps list | grep -q "ai-dictionary-server"; then
    flyctl apps create ai-dictionary-server
fi
echo -e "${GREEN}✓ Fly.io app ready${NC}"
echo ""

echo "Step 5: Setting up secrets..."
echo -e "${YELLOW}You'll need to provide:${NC}"
echo "  1. MongoDB Atlas connection string"
echo "  2. DeepSeek/SiliconFlow API key"
echo ""

read -p "MongoDB Atlas URI (mongodb+srv://...): " MONGODB_URI
read -p "SiliconFlow API Key: " SILICONFLOW_API_KEY

flyctl secrets set MONGODB_URI="$MONGODB_URI" --app ai-dictionary-server
flyctl secrets set SILICONFLOW_API_KEY="$SILICONFLOW_API_KEY" --app ai-dictionary-server

echo -e "${GREEN}✓ Secrets configured${NC}"
echo ""

echo "Step 6: Deploying to Fly.io..."
flyctl deploy --app ai-dictionary-server

echo ""
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo "Your API is available at:"
echo "  https://ai-dictionary-server.fly.dev"
echo ""
echo "Test it:"
echo "  curl https://ai-dictionary-server.fly.dev/health"
