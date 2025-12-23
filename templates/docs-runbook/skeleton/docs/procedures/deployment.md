# Deployment Procedure

## Summary

This procedure covers deploying new versions of ${{ values.serviceName }} to production.

## Prerequisites

- [ ] Code changes merged to main branch
- [ ] CI/CD pipeline passed
- [ ] Change request approved (for production)
- [ ] Rollback plan documented
- [ ] Communication sent to stakeholders

## Pre-Deployment Checklist

- [ ] Verify the build artifact exists
- [ ] Review changelog/release notes
- [ ] Check for database migrations
- [ ] Verify feature flags configured
- [ ] Confirm monitoring is functional

## Deployment Steps

### Step 1: Prepare

```bash
# Verify the version to deploy
kubectl get deployment ${{ values.serviceName }} -o jsonpath='{.spec.template.spec.containers[0].image}'

# Check current pod status
kubectl get pods -l app=${{ values.serviceName }}
```

### Step 2: Deploy to Staging

```bash
# Update image in staging
kubectl set image deployment/${{ values.serviceName }} \
  ${{ values.serviceName }}=myregistry.com/${{ values.serviceName }}:v1.2.3 \
  -n staging

# Monitor rollout
kubectl rollout status deployment/${{ values.serviceName }} -n staging
```

### Step 3: Verify Staging

```bash
# Check pods are healthy
kubectl get pods -l app=${{ values.serviceName }} -n staging

# Run smoke tests
curl https://staging.example.com/health

# Check error rates in monitoring
# (Wait 10 minutes for metrics)
```

### Step 4: Deploy to Production

```bash
# Update image in production
kubectl set image deployment/${{ values.serviceName }} \
  ${{ values.serviceName }}=myregistry.com/${{ values.serviceName }}:v1.2.3 \
  -n production

# Monitor rollout
kubectl rollout status deployment/${{ values.serviceName }} -n production
```

### Step 5: Verify Production

```bash
# Check pods are healthy
kubectl get pods -l app=${{ values.serviceName }} -n production

# Check health endpoint
curl https://api.example.com/health

# Monitor error rates for 15 minutes
```

## Post-Deployment

- [ ] Update deployment ticket
- [ ] Notify stakeholders of completion
- [ ] Monitor for 30 minutes
- [ ] Close change request

## Rollback Trigger

Rollback immediately if:

- Error rate exceeds 1%
- Response time exceeds SLA
- Critical functionality is broken
- Database migrations fail

See [Rollback Procedure](rollback.md) for steps.

## Troubleshooting

**Pods not starting:**
```bash
kubectl describe pod <pod-name> -n production
kubectl logs <pod-name> -n production
```

**Rollout stuck:**
```bash
kubectl rollout status deployment/${{ values.serviceName }} -n production
kubectl get events --sort-by='.lastTimestamp' -n production
```
