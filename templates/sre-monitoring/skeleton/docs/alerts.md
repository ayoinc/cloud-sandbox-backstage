# Alerting Rules

This document describes all alerting rules configured for this monitoring stack.

## Alert Severity Levels

| Level | Description | Response |
|-------|-------------|----------|
| **critical** | Service is down or severely degraded | Immediate response required |
| **warning** | Service is degraded but functional | Investigate within 1 hour |
| **info** | Informational alert | Review during business hours |

## General Infrastructure Alerts

### HighCPUUsage

- **Severity**: warning / critical
- **Condition**: CPU usage exceeds ${{ values.warningThreshold }}% (warning) or ${{ values.criticalThreshold }}% (critical)
- **Duration**: 5 minutes
- **Runbook**: See [High CPU Runbook](runbooks.md#high-cpu-usage)

### HighMemoryUsage

- **Severity**: warning / critical
- **Condition**: Memory usage exceeds ${{ values.warningThreshold }}% (warning) or ${{ values.criticalThreshold }}% (critical)
- **Duration**: 5 minutes
- **Runbook**: See [High Memory Runbook](runbooks.md#high-memory-usage)

### DiskSpaceLow

- **Severity**: warning / critical
- **Condition**: Disk usage exceeds ${{ values.warningThreshold }}% (warning) or ${{ values.criticalThreshold }}% (critical)
- **Duration**: 10 minutes
- **Runbook**: See [Disk Space Runbook](runbooks.md#disk-space-low)

## Application Alerts

### HighErrorRate

- **Severity**: critical
- **Condition**: Error rate exceeds 5% over 5 minutes
- **Duration**: 2 minutes
- **Runbook**: See [High Error Rate Runbook](runbooks.md#high-error-rate)

### HighLatency

- **Severity**: warning / critical
- **Condition**: P99 latency exceeds 500ms (warning) or 1s (critical)
- **Duration**: 5 minutes
- **Runbook**: See [High Latency Runbook](runbooks.md#high-latency)

### ServiceDown

- **Severity**: critical
- **Condition**: No successful health checks for 1 minute
- **Duration**: 1 minute
- **Runbook**: See [Service Down Runbook](runbooks.md#service-down)

## SLO Alerts

### SLOBurnRateCritical

- **Severity**: critical
- **Condition**: Error budget burn rate exceeds 14.4x (2% budget in 1 hour)
- **Duration**: 2 minutes
- **Runbook**: See [SLO Burn Rate Runbook](runbooks.md#slo-burn-rate)

### SLOBurnRateWarning

- **Severity**: warning
- **Condition**: Error budget burn rate exceeds 6x (5% budget in 6 hours)
- **Duration**: 30 minutes
- **Runbook**: See [SLO Burn Rate Runbook](runbooks.md#slo-burn-rate)

## Modifying Alerts

To modify alert thresholds:

1. Edit the appropriate file in `alerts/`
2. Validate the rules: `promtool check rules alerts/*.yaml`
3. Commit and push changes
4. CI/CD will automatically apply the updates
