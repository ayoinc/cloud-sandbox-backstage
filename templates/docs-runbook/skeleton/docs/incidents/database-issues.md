# Database Issues

## Summary

This runbook covers troubleshooting database connectivity and performance issues affecting ${{ values.serviceName }}.

## Symptoms

- Connection timeout errors
- Slow query performance
- "Too many connections" errors
- Replication lag alerts
- Database not responding

## Impact

- Application errors on database operations
- Degraded performance
- Potential data inconsistency (replication issues)

## Investigation Steps

### Step 1: Check Database Connectivity

```bash
# Test basic connectivity
nc -zv database.example.com 5432

# Test with credentials
psql -h database.example.com -U app_user -d mydb -c "SELECT 1"

# Check DNS resolution
dig database.example.com
```

### Step 2: Check Database Status

```bash
# PostgreSQL: Check if running
pg_isready -h database.example.com

# Check connections
psql -c "SELECT count(*) FROM pg_stat_activity;"

# Check for locks
psql -c "SELECT * FROM pg_locks WHERE NOT granted;"
```

### Step 3: Check Application Connection Pool

```bash
# Check application logs for connection errors
kubectl logs -l app=${{ values.serviceName }} | grep -i "connection\|database\|pool"

# Check connection pool metrics (if exposed)
curl http://localhost:8080/metrics | grep db_pool
```

### Step 4: Check for Slow Queries

```sql
-- PostgreSQL: Find slow queries
SELECT pid, now() - pg_stat_activity.query_start AS duration, query
FROM pg_stat_activity
WHERE state = 'active' AND now() - pg_stat_activity.query_start > interval '30 seconds';

-- Check for long-running transactions
SELECT pid, now() - xact_start AS duration, query
FROM pg_stat_activity
WHERE state = 'active' AND xact_start IS NOT NULL
ORDER BY duration DESC;
```

## Resolution Steps

### Connection Issues

**Too Many Connections:**
```sql
-- Terminate idle connections
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE state = 'idle' 
AND query_start < now() - interval '10 minutes';

-- Increase max connections (requires restart)
ALTER SYSTEM SET max_connections = 200;
```

**Connection Timeout:**
```bash
# Check network path
traceroute database.example.com

# Check firewall rules
# (specific to your infrastructure)

# Restart application to reset connection pool
kubectl rollout restart deployment/${{ values.serviceName }}
```

### Performance Issues

**Kill Long-Running Queries:**
```sql
-- Find and kill query
SELECT pg_cancel_backend(pid) FROM pg_stat_activity 
WHERE query LIKE '%problematic_pattern%' AND state = 'active';

-- Force terminate if cancel doesn't work
SELECT pg_terminate_backend(pid) FROM pg_stat_activity 
WHERE pid = <pid>;
```

**Add Missing Index (temporary):**
```sql
-- Check for missing indexes
EXPLAIN ANALYZE <your_query>;

-- Create index (non-blocking)
CREATE INDEX CONCURRENTLY idx_name ON table_name(column_name);
```

### Replication Issues

```sql
-- Check replication lag (on replica)
SELECT now() - pg_last_xact_replay_timestamp() AS replication_lag;

-- Check replication status (on primary)
SELECT client_addr, state, sent_lsn, write_lsn, replay_lsn
FROM pg_stat_replication;
```

## Verification

```bash
# Test connectivity
psql -c "SELECT 1"

# Check connection count is normal
psql -c "SELECT count(*) FROM pg_stat_activity WHERE state = 'active';"

# Verify application is working
curl http://localhost:8080/health

# Check error rate in application logs
kubectl logs -l app=${{ values.serviceName }} --since=5m | grep -i error | wc -l
```

## Escalation

Escalate if:

- Database is completely unresponsive
- Data corruption suspected
- Replication is broken
- Issue requires DBA expertise

Contact: DBA on-call → Database Team Lead

## Prevention

- Monitor connection pool usage
- Set up slow query logging
- Regular query performance review
- Implement connection pooling (PgBouncer)
- Set appropriate timeouts
