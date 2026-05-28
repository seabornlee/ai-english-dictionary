# AI Dictionary Server - Production Deployment Guide

## Quick Start (5 minutes)

### Step 1: Install Fly.io CLI

```bash
# macOS/Linux
curl -L https://fly.io/install.sh | sh

# Add to PATH
export PATH="$HOME/.fly/bin:$PATH"

# Verify installation
flyctl --version
```

### Step 2: Login to Fly.io

```bash
flyctl auth login
```

### Step 3: Set up MongoDB Atlas (Free Tier)

1. Go to https://www.mongodb.com/cloud/atlas/register
2. Create a free account
3. Create a new cluster (M0 Sandbox - free forever)
4. Click "Connect" → "Drivers" → "Node.js"
5. Copy the connection string (looks like):
   ```
   mongodb+srv://username:password@cluster.mongodb.net/ai-dictionary?retryWrites=true&w=majority
   ```
6. Replace `<password>` with your database user password

### Step 4: Get DeepSeek API Key

1. Go to https://platform.deepseek.com/
2. Create an account
3. Generate an API key

### Step 5: Deploy

```bash
cd ai-dic-server

# Deploy with automated script
./deploy.sh

# Or deploy manually:
flyctl deploy --app ai-dictionary-server

# Set secrets
flyctl secrets set MONGODB_URI="your_mongodb_uri" --app ai-dictionary-server
flyctl secrets set SILICONFLOW_API_KEY="your_api_key" --app ai-dictionary-server
```

### Step 6: Verify Deployment

```bash
# Check health
curl https://ai-dictionary-server.fly.dev/health

# Test API
curl -X POST https://ai-dictionary-server.fly.dev/api/dictionary/define \
  -H "Content-Type: application/json" \
  -d '{"word":"happiness"}'
```

## Manual Deployment Steps

If the script doesn't work, follow these manual steps:

### 1. Build Docker Image

```bash
cd ai-dic-server
docker build -t ai-dictionary-server .
```

### 2. Create Fly.io App

```bash
flyctl apps create ai-dictionary-server
```

### 3. Set Environment Variables

```bash
flyctl secrets set MONGODB_URI="mongodb+srv://..." --app ai-dictionary-server
flyctl secrets set SILICONFLOW_API_KEY="sk-..." --app ai-dictionary-server
flyctl secrets set NODE_ENV="production" --app ai-dictionary-server
```

### 4. Deploy

```bash
flyctl deploy --app ai-dictionary-server
```

### 5. Check Logs

```bash
flyctl logs --app ai-dictionary-server
```

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `MONGODB_URI` | MongoDB Atlas connection string | Yes |
| `SILICONFLOW_API_KEY` | DeepSeek/SiliconFlow API key | Yes |
| `NODE_ENV` | Set to "production" | Yes |
| `PORT` | Port (default: 3000) | No |

## Troubleshooting

### Issue: "failed to fetch an image or build from source"

**Solution:** Make sure Docker is running
```bash
docker info
```

### Issue: "connection refused" to MongoDB

**Solution:** Check your MongoDB Atlas connection string:
1. Make sure you've whitelisted all IPs (0.0.0.0/0) in Atlas
2. Verify the password is URL-encoded
3. Ensure the database user has read/write permissions

### Issue: API returns 500 errors

**Solution:** Check logs
```bash
flyctl logs --app ai-dictionary-server
```

### Issue: "app not found"

**Solution:** Create the app first
```bash
flyctl apps create ai-dictionary-server
```

## Updating the Deployment

After making changes to the code:

```bash
cd ai-dic-server
flyctl deploy --app ai-dictionary-server
```

## Scaling (if needed)

```bash
# Scale to 2 machines for redundancy
flyctl scale count 2 --app ai-dictionary-server

# Scale memory
flyctl scale memory 512 --app ai-dictionary-server
```

## Cost

- **Fly.io**: Free tier includes 3 shared-cpu-1x VMs, 3GB persistent volumes
- **MongoDB Atlas**: M0 cluster is free forever (512MB storage)
- **DeepSeek API**: Pay-as-you-go (~$0.002 per 1K tokens)

Total monthly cost: **$0** (for low usage)

## Next Steps

After deployment:
1. Update the Mac app's `APIService.swift` to point to `https://ai-dictionary-server.fly.dev`
2. Build and distribute the Mac app
3. Set up monitoring (optional)

## Support

- Fly.io docs: https://fly.io/docs/
- MongoDB Atlas docs: https://docs.atlas.mongodb.com/
- DeepSeek API docs: https://platform.deepseek.com/
