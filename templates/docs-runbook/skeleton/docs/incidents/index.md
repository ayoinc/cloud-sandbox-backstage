# Incident Runbooks

This section contains runbooks for responding to common incidents.

## Incident Quick Reference

| Incident          | Severity | Runbook                                  |
| ----------------- | -------- | ---------------------------------------- |
| High CPU Usage    | SEV2/3   | [high-cpu.md](high-cpu.md)               |
| High Memory Usage | SEV2/3   | [high-memory.md](high-memory.md)         |
| Service Down      | SEV1/2   | [service-down.md](service-down.md)       |
| Database Issues   | SEV1/2   | [database-issues.md](database-issues.md) |

## Incident Response Process

```d2
direction: right

alert: Alert {
  style.fill: "#ffcdd2"
}

triage: Triage {
  style.fill: "#fff9c4"
}

investigate: Investigate {
  style.fill: "#c8e6c9"
}

mitigate: Mitigate {
  style.fill: "#b3e5fc"
}

resolve: Resolve {
  style.fill: "#d1c4e9"
}

document: Document {
  style.fill: "#f5f5f5"
}

alert -> triage -> investigate -> mitigate -> resolve -> document
```

## Before You Start

1. Acknowledge the alert
2. Communicate in #incidents
3. Open the relevant dashboard
4. Follow the specific runbook

## General Troubleshooting

### Check Service Health

```bash
# Check service status
systemctl status ${{ values.serviceName }}

# Check recent logs
journalctl -u ${{ values.serviceName }} --since "10 minutes ago"

# Check resource usage
top -bn1 | head -20
```

### Check Connectivity

```bash
# Check if service is responding
curl -I http://localhost:8080/health

# Check DNS resolution
dig service.example.com

# Check network connectivity
nc -zv database.example.com 5432
```

## Need Help?

If you can't find the right runbook:

1. Search existing runbooks for keywords
2. Ask in #sre-support
3. Page the secondary on-call
4. Create a new runbook after resolution
