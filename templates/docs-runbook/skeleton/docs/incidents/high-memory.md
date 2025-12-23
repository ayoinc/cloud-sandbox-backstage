# High Memory Usage

## Summary

This runbook covers troubleshooting and resolving high memory usage on ${{ values.serviceName }}.

## Symptoms

- Alert: `HighMemoryUsage` triggered
- Memory usage above 85%
- OOM (Out of Memory) kills
- Service restarts unexpectedly

## Impact

- Service crashes due to OOM
- Degraded performance
- Potential data loss if not handled properly

## Investigation Steps

### Step 1: Check Current Memory Status

```bash
# Check overall memory
free -h

# Detailed memory info
cat /proc/meminfo | head -20

# Check swap usage
swapon --show
```

### Step 2: Identify Memory Consumers

```bash
# Top memory consumers
ps aux --sort=-%mem | head -10

# Memory by process
smem -t -k -c "pid user command swap uss pss rss"
```

### Step 3: Check for Memory Leaks

```bash
# Check if memory has been growing over time
# Review metrics in your monitoring system

# For Java applications
jmap -heap <pid>

# Check for OOM events
dmesg | grep -i "out of memory"
journalctl | grep -i oom
```

### Step 4: Analyze Application Memory

```bash
# Java heap dump
jmap -dump:format=b,file=/tmp/heap.hprof <pid>

# Check GC activity (Java)
jstat -gcutil <pid> 1000 10
```

## Resolution Steps

### Option 1: Clear Caches

```bash
# Clear system caches (use with caution)
sync; echo 3 > /proc/sys/vm/drop_caches

# Application-specific cache clearing
curl -X POST http://localhost:8080/admin/cache/clear
```

### Option 2: Restart Service

```bash
# Graceful restart to reclaim memory
systemctl restart ${{ values.serviceName }}

# For Kubernetes
kubectl rollout restart deployment/${{ values.serviceName }}
```

### Option 3: Scale Horizontally

```bash
# Add more instances to distribute memory load
kubectl scale deployment ${{ values.serviceName }} --replicas=5
```

### Option 4: Increase Memory Limits

```bash
# For Kubernetes, edit deployment
kubectl edit deployment ${{ values.serviceName }}
# Increase resources.limits.memory

# For systemd services
systemctl edit ${{ values.serviceName }}
# Add: MemoryMax=4G
```

## Verification

```bash
# Check memory is back to normal
free -h

# Verify service is healthy
curl http://localhost:8080/health

# Check no OOM events
dmesg | tail -20 | grep -i oom
```

## Escalation

Escalate if:

- Memory leak is confirmed (requires code fix)
- OOM kills continue after restart
- Issue affects multiple services

## Prevention

- Implement memory limits in container/service config
- Set up alerting before critical thresholds
- Regular performance testing and profiling
- Review code for memory leak patterns
