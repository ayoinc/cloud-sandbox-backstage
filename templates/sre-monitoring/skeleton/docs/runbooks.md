# Runbooks

This document provides step-by-step procedures for responding to alerts.

## High CPU Usage

**Alert**: `HighCPUUsage`

### Symptoms

- Alert firing for CPU usage above threshold
- Slow response times
- Increased latency

### Investigation

1. Identify the affected host/pod:
   ```bash
   # Kubernetes
   kubectl top pods -A --sort-by=cpu
   
   # Linux
   top -o %CPU
   ```

2. Check for unusual processes:
   ```bash
   ps aux --sort=-%cpu | head -20
   ```

3. Review recent deployments or changes

### Resolution

1. **If caused by a runaway process**: Kill or restart the process
2. **If caused by legitimate load**: Scale horizontally
3. **If caused by a bug**: Roll back recent deployment

---

## High Memory Usage

**Alert**: `HighMemoryUsage`

### Symptoms

- Alert firing for memory usage above threshold
- OOM kills in logs
- Application crashes

### Investigation

1. Identify memory consumers:
   ```bash
   # Kubernetes
   kubectl top pods -A --sort-by=memory
   
   # Linux
   ps aux --sort=-%mem | head -20
   ```

2. Check for memory leaks:
   ```bash
   # View memory trends
   free -h
   vmstat 1 10
   ```

### Resolution

1. **If memory leak**: Restart affected service, investigate code
2. **If legitimate usage**: Increase memory limits or scale
3. **If cache bloat**: Clear caches or adjust cache policies

---

## Disk Space Low

**Alert**: `DiskSpaceLow`

### Symptoms

- Alert firing for disk usage above threshold
- Write failures in application logs
- Database errors

### Investigation

1. Check disk usage:
   ```bash
   df -h
   du -sh /* | sort -hr | head -20
   ```

2. Identify large files:
   ```bash
   find / -type f -size +100M 2>/dev/null | head -20
   ```

### Resolution

1. **Clean up logs**: `journalctl --vacuum-time=7d`
2. **Remove old containers/images**: `docker system prune -a`
3. **Archive old data**: Move to object storage
4. **Expand disk**: Resize volume if cloud-based

---

## High Error Rate

**Alert**: `HighErrorRate`

### Symptoms

- Error rate exceeds 5%
- User-facing errors
- Failed transactions

### Investigation

1. Check error logs:
   ```bash
   kubectl logs -l app=myapp --tail=100 | grep -i error
   ```

2. Review error breakdown in Grafana dashboard

3. Check dependent services:
   ```bash
   kubectl get pods -A | grep -v Running
   ```

### Resolution

1. **If deployment related**: Roll back to previous version
2. **If dependency failure**: Check and restore dependencies
3. **If rate limiting**: Adjust limits or scale

---

## High Latency

**Alert**: `HighLatency`

### Symptoms

- P99 latency above threshold
- Slow user experience
- Timeouts

### Investigation

1. Check slow queries/operations:
   ```sql
   -- PostgreSQL
   SELECT query, calls, mean_time FROM pg_stat_statements 
   ORDER BY mean_time DESC LIMIT 10;
   ```

2. Review trace data in observability platform

3. Check for resource contention

### Resolution

1. **If database related**: Optimize queries, add indexes
2. **If network related**: Check network policies, DNS
3. **If resource related**: Scale or optimize resource usage

---

## Service Down

**Alert**: `ServiceDown`

### Symptoms

- Health check failures
- Service unreachable
- Connection refused errors

### Investigation

1. Check pod/service status:
   ```bash
   kubectl get pods -l app=myapp
   kubectl describe pod <pod-name>
   kubectl logs <pod-name> --previous
   ```

2. Check events:
   ```bash
   kubectl get events --sort-by='.lastTimestamp'
   ```

### Resolution

1. **If crash loop**: Fix code issue, roll back
2. **If OOM killed**: Increase memory limits
3. **If stuck**: Delete pod to force restart
4. **If image pull failure**: Check registry credentials

---

## SLO Burn Rate

**Alert**: `SLOBurnRateCritical` / `SLOBurnRateWarning`

### Symptoms

- Error budget being consumed too quickly
- Risk of missing SLO target

### Investigation

1. Review SLO dashboard for trend
2. Identify contributing errors
3. Check for correlation with deployments/changes

### Resolution

1. **Immediate**: Address any active incidents
2. **Short-term**: Implement fixes for top error sources
3. **Long-term**: Review SLO targets and system reliability
