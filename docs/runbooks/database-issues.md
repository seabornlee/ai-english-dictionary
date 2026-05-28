# Runbook: Database Issues

## Symptoms
- Health check shows `mongo: "disconnected"`
- Slow API responses
- "MongoServerError" in logs
- Connection timeout errors

## Quick Diagnosis

### 1. Check MongoDB Connection State
```bash
flyctl ssh console -a ai-dic-server
# Inside container:
node -e "require('mongoose').connection.readyState"
```

States: 0=disconnected, 1=connected, 2=connecting, 3=disconnecting

### 2. Check MongoDB Atlas
1. Log into [MongoDB Atlas](https://cloud.mongodb.com)
2. Check cluster status (green = healthy)
3. Review "Real Time" metrics tab
4. Check "Alerts" for any triggered alerts

### 3. Test Connection Locally
```bash
cd server
node -e "
require('dotenv').config();
const mongoose = require('mongoose');
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('Connected'))
  .catch(err => console.error('Failed:', err.message));
"
```

## Common Issues

### Connection String Invalid
- Verify `MONGODB_URI` secret in Fly.io
- Ensure password doesn't have special chars that need encoding
- Check database name in URI

### IP Whitelist
- MongoDB Atlas may block Fly.io IPs
- Go to Atlas > Network Access > Add IP Address
- Add `0.0.0.0/0` for allow all (or Fly.io IP ranges)

### Connection Pool Exhausted
Signs: Intermittent connection failures
```bash
# Check current connections in Atlas
# Metrics > Connections
```

Fix: Increase pool size in connection options or reduce concurrent requests

### Slow Queries
```bash
# Check Atlas > Profiler for slow queries
# Enable profiling for queries > 100ms
```

## Recovery Steps

### 1. Restart Application
```bash
flyctl apps restart ai-dic-server
```

### 2. Verify Secrets
```bash
flyctl secrets list -a ai-dic-server
# Should show MONGODB_URI
```

### 3. Update Connection String
```bash
flyctl secrets set MONGODB_URI="mongodb+srv://..." -a ai-dic-server
```

## Escalation

If database issues persist:
1. Check MongoDB Atlas status page
2. Contact MongoDB support if Atlas issue
3. Contact @seabornlee

## Prevention

- Set up MongoDB Atlas alerts for:
  - Connections > 80% of limit
  - Query execution time > 1s
  - Disk usage > 80%
