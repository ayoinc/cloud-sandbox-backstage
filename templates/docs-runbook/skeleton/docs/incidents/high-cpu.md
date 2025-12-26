# High CPU Usage

## Summary

This runbook covers troubleshooting and resolving high CPU usage on ${{ values.serviceName }}.

## Symptoms

- Alert: `HighCPUUsage` triggered
- CPU usage consistently above 80%
- Slow response times
- Request timeouts

## Impact

- Degraded service performance
- Increased latency for users
- Potential service unavailability if not addressed

## Prerequisites

- SSH access to affected hosts
- Access to monitoring dashboards

## Investigation Steps

### Step 1: Identify the Affected Host

Check the alert details or monitoring dashboard to identify which host(s) are affected.

```bash
# Check current CPU usage
top -bn1 | head -20

# Or use htop for interactive view
htop
```

### Step 2: Identify the Process

Find which process is consuming CPU:

```bash
# List top CPU consumers
ps aux --sort=-%cpu | head -10

# For the service specifically
ps aux | grep ${{ values.serviceName }}
```

### Step 3: Check for Anomalies

```bash
# Check for unusual number of processes
ps aux | wc -l

# Check for zombie processes
ps aux | grep Z

# Check load average
uptime
```

### Step 4: Analyze the Cause

Common causes and checks:

**Traffic Spike:**

```bash
# Check request rate
# (Adjust based on your metrics system)
curl -s http://localhost:9090/metrics | grep http_requests_total
```

**Memory Pressure (causing GC):**

```bash
# Check memory usage
free -m
```

**Runaway Loop/Bug:**

```bash
# Get stack trace (for Java)
jstack <pid>

# For Node.js
kill -USR1 <pid>  # Sends trace to log
```

## Resolution Steps

### Option 1: Scale Up (if traffic-related)

```bash
# Add more instances (adjust for your orchestration)
kubectl scale deployment ${{ values.serviceName }} --replicas=5
```

### Option 2: Restart Service (if process is stuck)

```bash
# Graceful restart
systemctl restart ${{ values.serviceName }}

# Or for containers
kubectl rollout restart deployment/${{ values.serviceName }}
```

### Option 3: Kill Runaway Process

```bash
# Identify and kill specific process
kill -15 <pid>

# Force kill if necessary
kill -9 <pid>
```

## Verification

After taking action, verify the issue is resolved:

```bash
# Check CPU has dropped
top -bn1 | head -5

# Verify service is healthy
curl http://localhost:8080/health

# Check for errors in logs
journalctl -u ${{ values.serviceName }} --since "5 minutes ago" | grep -i error
```

## Escalation

Escalate if:

- CPU remains high after restart
- Issue recurs within 1 hour
- Root cause is unclear

Contact: Secondary on-call → Team Lead → Engineering Manager

## Prevention

- Set up auto-scaling based on CPU metrics
- Review and optimize CPU-intensive code paths
- Implement rate limiting for traffic spikes
