# Rollback Procedure

## Summary

This procedure covers rolling back ${{ values.serviceName }} to a previous version.

## When to Rollback

Rollback immediately when:

- Error rate exceeds threshold after deployment
- Critical functionality is broken
- Performance severely degraded
- Data integrity issues detected

## Quick Rollback (Emergency)

For immediate rollback, use:

```bash
# Rollback to previous version
kubectl rollout undo deployment/${{ values.serviceName }} -n production

# Verify rollback is progressing
kubectl rollout status deployment/${{ values.serviceName }} -n production
```

## Detailed Rollback Steps

### Step 1: Communicate

Post in #incidents:

```
🔴 Initiating Rollback
Service: ${{ values.serviceName }}
Reason: [describe issue]
Action: Rolling back to previous version
```

### Step 2: Check Rollout History

```bash
# View deployment history
kubectl rollout history deployment/${{ values.serviceName }} -n production

# Check specific revision
kubectl rollout history deployment/${{ values.serviceName }} -n production --revision=2
```

### Step 3: Execute Rollback

```bash
# Rollback to previous revision
kubectl rollout undo deployment/${{ values.serviceName }} -n production

# Or rollback to specific revision
kubectl rollout undo deployment/${{ values.serviceName }} -n production --to-revision=2
```

### Step 4: Monitor Rollback

```bash
# Watch rollback progress
kubectl rollout status deployment/${{ values.serviceName }} -n production

# Check pods
kubectl get pods -l app=${{ values.serviceName }} -n production -w
```

### Step 5: Verify

```bash
# Confirm version
kubectl get deployment ${{ values.serviceName }} -n production \
  -o jsonpath='{.spec.template.spec.containers[0].image}'

# Check health
curl https://api.example.com/health

# Verify error rate is decreasing
```

### Step 6: Communicate Resolution

```
🟢 Rollback Complete
Service: ${{ values.serviceName }}
Rolled back to: [version]
Status: Service stable
Next Steps: Investigation ongoing
```

## Database Rollback

If the deployment included database migrations:

⚠️ **Warning**: Database rollbacks can cause data loss. Consult DBA before proceeding.

```bash
# Check migration status
kubectl exec -it ${{ values.serviceName }}-pod -- ./manage.py showmigrations

# Rollback migration (if reversible)
kubectl exec -it ${{ values.serviceName }}-pod -- ./manage.py migrate app_name 0002
```

## Post-Rollback Actions

- [ ] Create incident ticket
- [ ] Document the issue that triggered rollback
- [ ] Schedule investigation meeting
- [ ] Block the bad deployment from being redeployed
- [ ] Update stakeholders

## Prevention

- Always test in staging first
- Use canary deployments for risky changes
- Implement feature flags for gradual rollout
- Ensure database migrations are reversible
