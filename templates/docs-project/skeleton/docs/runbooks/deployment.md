# Runbook: Deployment

## Overview
Standard deployment procedure for ${{ values.name }}.

## Prerequisites
- Access to CI/CD pipeline
- Deployment permissions
- Monitoring dashboard access

## Procedure

### 1. Pre-deployment Checks
- [ ] All tests passing
- [ ] Code review approved
- [ ] Changelog updated

### 2. Deploy to Staging
```bash
# Trigger staging deployment
git push origin main
```

### 3. Verify Staging
- [ ] Health checks passing
- [ ] Smoke tests passing
- [ ] No errors in logs

### 4. Deploy to Production
```bash
# Create release tag
git tag -a v1.x.x -m "Release v1.x.x"
git push origin v1.x.x
```

### 5. Post-deployment
- [ ] Monitor error rates
- [ ] Check performance metrics
- [ ] Update status page

## Verification
- Health endpoint returns 200
- No increase in error rates
- Response times within SLA

## Rollback
```bash
# Revert to previous version
git revert HEAD
git push origin main
```

## Contacts
- Primary: @platform-team
- Escalation: @on-call
