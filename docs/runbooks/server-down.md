# Runbook: Server Down

## Symptoms
- Health check endpoint returns non-200 status
- API requests timing out
- Users reporting "Unable to connect"

## Quick Diagnosis

### 1. Check Fly.io Status
```bash
flyctl status -a ai-dic-server
flyctl logs -a ai-dic-server --tail
```

### 2. Check Health Endpoint
```bash
curl -s https://ai-dic-server.fly.dev/health | jq .
```

Expected response:
```json
{
  "status": "ok",
  "mongo": "connected",
  "state": 1
}
```

### 3. Check MongoDB Connection
If `mongo: "disconnected"`:
- Verify MongoDB Atlas cluster is running
- Check connection string in Fly.io secrets
- Review MongoDB Atlas alerts

## Recovery Steps

### Restart Application
```bash
flyctl apps restart ai-dic-server
```

### Check Logs for Errors
```bash
flyctl logs -a ai-dic-server | grep -i error
```

### Scale Up if Needed
```bash
flyctl scale count 2 -a ai-dic-server
```

### Rollback Deployment
```bash
flyctl releases -a ai-dic-server
flyctl deploy --image <previous-image> -a ai-dic-server
```

## Escalation

If unable to resolve within 30 minutes:
1. Check MongoDB Atlas status page
2. Check Fly.io status page
3. Contact @seabornlee

## Post-Incident

1. Document root cause
2. Update this runbook if needed
3. Create follow-up issues for prevention
