# Runbooks

This directory contains operational runbooks for incident response and common operational tasks.

## Available Runbooks

| Runbook | Description |
|---------|-------------|
| [Server Down](server-down.md) | Steps to diagnose and recover from server outages |
| [Database Issues](database-issues.md) | MongoDB connection and performance issues |
| [High Latency](high-latency.md) | Diagnosing slow API responses |
| [Deployment](deployment.md) | Manual deployment procedures |

## Incident Response Process

1. **Acknowledge** - Acknowledge the alert within 5 minutes
2. **Assess** - Determine severity and impact
3. **Communicate** - Update status page / notify stakeholders
4. **Mitigate** - Apply temporary fix if needed
5. **Resolve** - Implement permanent fix
6. **Review** - Post-incident review within 48 hours

## Severity Levels

| Level | Description | Response Time |
|-------|-------------|---------------|
| P0 | Complete outage | Immediate |
| P1 | Major feature broken | 15 minutes |
| P2 | Minor feature broken | 1 hour |
| P3 | Non-critical issue | 24 hours |

## Useful Links

- [Fly.io Dashboard](https://fly.io/apps/ai-dic-server)
- [MongoDB Atlas](https://cloud.mongodb.com)
- [GitHub Actions](https://github.com/seabornlee/ai-english-dictionary/actions)
