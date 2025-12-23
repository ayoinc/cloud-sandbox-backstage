# Scaling Procedure

## Summary

This procedure covers scaling ${{ values.serviceName }} horizontally (replicas) and vertically (resources).

## When to Scale

**Scale Up:**
- High CPU/memory utilization
- Increased traffic
- Before planned high-traffic events
- Response time degradation

**Scale Down:**
- After traffic decreases
- Cost optimization
- During maintenance windows

## Horizontal Scaling (Replicas)

### Check Current State

```bash
# Current replica count
kubectl get deployment ${{ values.serviceName }} -n production

# Current pod status
kubectl get pods -l app=${{ values.serviceName }} -n production

# Resource usage
kubectl top pods -l app=${{ values.serviceName }} -n production
```

### Scale Up

```bash
# Scale to specific number
kubectl scale deployment ${{ values.serviceName }} --replicas=5 -n production

# Verify scaling
kubectl get pods -l app=${{ values.serviceName }} -n production -w
```

### Scale Down

```bash
# Scale down (minimum 2 for HA)
kubectl scale deployment ${{ values.serviceName }} --replicas=2 -n production

# Verify pods are terminating gracefully
kubectl get pods -l app=${{ values.serviceName }} -n production -w
```

### Auto-Scaling

Check and configure HPA:

```bash
# View current HPA
kubectl get hpa ${{ values.serviceName }} -n production

# Describe HPA for details
kubectl describe hpa ${{ values.serviceName }} -n production

# Update HPA limits
kubectl patch hpa ${{ values.serviceName }} -n production \
  -p '{"spec":{"maxReplicas":10}}'
```

## Vertical Scaling (Resources)

### Check Current Resources

```bash
# View current resource limits
kubectl get deployment ${{ values.serviceName }} -n production \
  -o jsonpath='{.spec.template.spec.containers[0].resources}'

# Check actual usage
kubectl top pods -l app=${{ values.serviceName }} -n production
```

### Update Resources

```bash
# Edit deployment to update resources
kubectl edit deployment ${{ values.serviceName }} -n production

# Or patch directly
kubectl patch deployment ${{ values.serviceName }} -n production -p '
{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "${{ values.serviceName }}",
          "resources": {
            "requests": {"cpu": "500m", "memory": "512Mi"},
            "limits": {"cpu": "1000m", "memory": "1Gi"}
          }
        }]
      }
    }
  }
}'
```

⚠️ **Note**: Changing resources triggers a rolling restart.

## Verification

After scaling, verify:

```bash
# All pods are running
kubectl get pods -l app=${{ values.serviceName }} -n production

# Pods are healthy
kubectl get pods -l app=${{ values.serviceName }} -n production \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}'

# Service is responding
curl https://api.example.com/health

# Load is distributed
kubectl top pods -l app=${{ values.serviceName }} -n production
```

## Guidelines

### Minimum Replicas

| Environment | Minimum | Recommended |
|-------------|---------|-------------|
| Production | 2 | 3 |
| Staging | 1 | 2 |
| Development | 1 | 1 |

### Resource Guidelines

| Size | CPU Request | CPU Limit | Memory Request | Memory Limit |
|------|-------------|-----------|----------------|--------------|
| Small | 250m | 500m | 256Mi | 512Mi |
| Medium | 500m | 1000m | 512Mi | 1Gi |
| Large | 1000m | 2000m | 1Gi | 2Gi |

## Troubleshooting

**Pods stuck in Pending:**
```bash
kubectl describe pod <pod-name> -n production
# Check for resource constraints or node issues
```

**Pods crashing after resource change:**
```bash
kubectl logs <pod-name> -n production
# May need to increase memory limits
```
