# Service Down

## Summary

This runbook covers response when ${{ values.serviceName }} is completely unavailable.

## Symptoms

- Alert: `ServiceDown` or `EndpointDown` triggered
- Health checks failing
- Users reporting complete inability to access service
- 5xx errors or connection refused

## Impact

- **SEV1**: Complete service outage
- Users cannot access the service
- Potential data processing delays

## Immediate Actions

### Step 1: Acknowledge and Communicate

```
🔴 Incident Started
Service: ${{ values.serviceName }}
Impact: Service completely unavailable
Status: Investigating
```

Post in: #incidents

### Step 2: Quick Health Check

```bash
# Check if service process is running
systemctl status ${{ values.serviceName }}

# Or for containers
kubectl get pods -l app=${{ values.serviceName }}

# Try to reach health endpoint
curl -v http://localhost:8080/health
```

### Step 3: Check Recent Changes

- Check deployment history
- Review recent config changes
- Check for infrastructure changes

```bash
# Kubernetes deployment history
kubectl rollout history deployment/${{ values.serviceName }}

# Recent deployments
kubectl get events --sort-by='.lastTimestamp' | tail -20
```

## Investigation Steps

### Check Logs

```bash
# Service logs
journalctl -u ${{ values.serviceName }} -n 100 --no-pager

# Kubernetes logs
kubectl logs -l app=${{ values.serviceName }} --tail=100

# Check for crash logs
kubectl logs -l app=${{ values.serviceName }} --previous
```

### Check Dependencies

```bash
# Database connectivity
nc -zv database.example.com 5432

# Cache connectivity
nc -zv redis.example.com 6379

# External API
curl -I https://api.external.com/health
```

### Check Resources

```bash
# Disk space
df -h

# Node resources (Kubernetes)
kubectl top nodes
kubectl describe node <node-name>
```

## Resolution Steps

### Option 1: Restart Service

```bash
# Simple restart
systemctl restart ${{ values.serviceName }}

# Kubernetes rollout restart
kubectl rollout restart deployment/${{ values.serviceName }}
```

### Option 2: Rollback Deployment

```bash
# Kubernetes rollback
kubectl rollout undo deployment/${{ values.serviceName }}

# Rollback to specific revision
kubectl rollout undo deployment/${{ values.serviceName }} --to-revision=2
```

### Option 3: Fix Configuration

```bash
# Check and fix ConfigMap
kubectl get configmap ${{ values.serviceName }}-config -o yaml

# Edit and apply fix
kubectl edit configmap ${{ values.serviceName }}-config

# Restart to pick up changes
kubectl rollout restart deployment/${{ values.serviceName }}
```

### Option 4: Scale Up/Replace Pods

```bash
# Delete stuck pods
kubectl delete pod <pod-name>

# Scale down and up
kubectl scale deployment ${{ values.serviceName }} --replicas=0
kubectl scale deployment ${{ values.serviceName }} --replicas=3
```

## Verification

```bash
# Check pods are running
kubectl get pods -l app=${{ values.serviceName }}

# Check all pods are ready
kubectl wait --for=condition=ready pod -l app=${{ values.serviceName }} --timeout=120s

# Verify health endpoint
curl http://localhost:8080/health

# Check error rate in metrics
# (Check your monitoring dashboard)
```

## Communication

**Update during investigation:**

```
🟡 Incident Update
Service: ${{ values.serviceName }}
Status: Root cause identified - [cause]
Action: [action being taken]
ETA: [estimate]
```

**Resolution:**

```
🟢 Incident Resolved
Service: ${{ values.serviceName }}
Duration: [X minutes]
Root Cause: [brief description]
RCA: Will be posted within 48 hours
```

## Escalation

Escalate immediately if:

- Cannot identify root cause within 15 minutes
- Impact is broader than initially assessed
- Rollback is not possible
- Data integrity concerns

## Post-Incident

- [ ] Create incident ticket
- [ ] Schedule post-mortem within 48 hours
- [ ] Document timeline and actions
- [ ] Identify prevention measures
