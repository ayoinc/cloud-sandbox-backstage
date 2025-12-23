# ZooKeeper Ensemble Overview

## Architecture Deep Dive

### Consensus Protocol (ZAB)

ZooKeeper uses the ZooKeeper Atomic Broadcast (ZAB) protocol for consensus:

```d2
direction: down

title: Write Request Flow {
  shape: text
  near: top-center
  style: {
    font-size: 20
    bold: true
  }
}

client: Client {
  shape: person
}

step1: "1. Client sends write to any server" {
  shape: rectangle
  style.fill: "#E3F2FD"
}

step2: "2. Follower forwards to Leader" {
  shape: rectangle
  style.fill: "#E3F2FD"
}

step3: "3. Leader proposes transaction (ZXID)" {
  shape: rectangle
  style.fill: "#FFF8E1"
}

step4: "4. Followers ACK after writing to disk" {
  shape: rectangle
  style.fill: "#FFF8E1"
}

step5: "5. Leader commits after quorum (majority) ACKs" {
  shape: rectangle
  style.fill: "#E8F5E9"
}

step6: "6. Response returned to client" {
  shape: rectangle
  style.fill: "#E8F5E9"
}

client -> step1 -> step2 -> step3 -> step4 -> step5 -> step6
```

### Quorum Requirements

| Ensemble Size | Quorum | Fault Tolerance |
|---------------|--------|-----------------|
| 3 | 2 | 1 node failure |
| 5 | 3 | 2 node failures |
| 7 | 4 | 3 node failures |

**Recommendation**: Use odd numbers (3, 5, 7) to maximize fault tolerance.

### Session Management

```d2
direction: right

title: Session Lifecycle {
  shape: text
  near: top-center
  style: {
    font-size: 18
    bold: true
  }
}

connecting: CONNECTING {
  shape: rectangle
  style.fill: "#FFF8E1"
}

connected: CONNECTED {
  shape: rectangle
  style.fill: "#E8F5E9"
}

disconnected: DISCONNECTED {
  shape: rectangle
  style.fill: "#FFECB3"
}

expired: EXPIRED {
  shape: rectangle
  style.fill: "#FFCDD2"
}

closed: CLOSED {
  shape: rectangle
  style.fill: "#E0E0E0"
}

connecting -> connected
connecting -> expired: timeout
connected -> disconnected
disconnected -> connected: reconnect
disconnected -> closed
disconnected -> expired: session timeout
```

## Configuration

### Core Configuration (zoo.cfg)

```properties
# zoo.cfg - ZooKeeper Configuration

# Basic Settings
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/var/lib/zookeeper/data
dataLogDir=/var/lib/zookeeper/log
clientPort=2181

# Cluster Configuration
server.1=zk1.example.com:2888:3888
server.2=zk2.example.com:2888:3888
server.3=zk3.example.com:2888:3888

# Advanced Settings
maxClientCnxns=60
autopurge.snapRetainCount=3
autopurge.purgeInterval=1
admin.enableServer=true
admin.serverPort=8080

# Performance Tuning
preAllocSize=65536
snapCount=100000
globalOutstandingLimit=1000
maxSessionTimeout=60000
minSessionTimeout=4000

# 4-Letter Words (whitelist for monitoring)
4lw.commands.whitelist=stat, ruok, conf, isro, mntr, srvr

# Metrics
metricsProvider.className=org.apache.zookeeper.metrics.prometheus.PrometheusMetricsProvider
metricsProvider.httpPort=7000
metricsProvider.exportJvmInfo=true
```

### JVM Configuration

```bash
# zookeeper-env.sh
export SERVER_JVMFLAGS="-Xms2g -Xmx2g \
  -XX:+UseG1GC \
  -XX:MaxGCPauseMillis=200 \
  -XX:+ParallelRefProcEnabled \
  -XX:+UnlockExperimentalVMOptions \
  -XX:+DisableExplicitGC \
  -XX:+AlwaysPreTouch \
  -Djute.maxbuffer=4194304 \
  -Dcom.sun.management.jmxremote \
  -Dcom.sun.management.jmxremote.port=9999 \
  -Dcom.sun.management.jmxremote.local.only=false \
  -Dcom.sun.management.jmxremote.authenticate=false \
  -Dcom.sun.management.jmxremote.ssl=false"
```

### Configuration Parameters Reference

| Parameter | Default | Description |
|-----------|---------|-------------|
| `tickTime` | 2000 | Basic time unit in milliseconds |
| `initLimit` | 10 | Ticks for initial sync |
| `syncLimit` | 5 | Ticks for follower sync |
| `maxClientCnxns` | 60 | Max client connections per IP |
| `autopurge.purgeInterval` | 0 | Hours between purge (0=disabled) |
| `autopurge.snapRetainCount` | 3 | Snapshots to retain |
| `maxSessionTimeout` | 40000 | Max session timeout (ms) |
| `preAllocSize` | 65536 | Transaction log preallocation (KB) |
| `snapCount` | 100000 | Transactions per snapshot |

## Security Configuration

### SASL/Kerberos Authentication

```properties
# zoo.cfg - SASL Configuration
authProvider.1=org.apache.zookeeper.server.auth.SASLAuthenticationProvider
requireClientAuthScheme=sasl
jaasLoginRenew=3600000
```

```
// jaas.conf - JAAS Configuration
Server {
    com.sun.security.auth.module.Krb5LoginModule required
    useKeyTab=true
    keyTab="/etc/zookeeper/zookeeper.keytab"
    storeKey=true
    useTicketCache=false
    principal="zookeeper/zk1.example.com@EXAMPLE.COM";
};

Client {
    com.sun.security.auth.module.Krb5LoginModule required
    useKeyTab=true
    keyTab="/etc/zookeeper/client.keytab"
    storeKey=true
    useTicketCache=false
    principal="client@EXAMPLE.COM";
};
```

### TLS/SSL Configuration

```properties
# zoo.cfg - TLS Configuration
secureClientPort=2182
ssl.clientAuth=need
ssl.keyStore.location=/etc/zookeeper/ssl/keystore.jks
ssl.keyStore.password=changeit
ssl.trustStore.location=/etc/zookeeper/ssl/truststore.jks
ssl.trustStore.password=changeit
ssl.protocol=TLSv1.2
ssl.enabledProtocols=TLSv1.2,TLSv1.3
ssl.ciphersuites=TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
```

### ACL Configuration

```bash
# Create node with ACLs via zkCli.sh
create /secure-data "secret" sasl:admin:cdrwa

# Set ACL on existing node
setAcl /myapp world:anyone:r,sasl:admin:cdrwa

# Get ACLs
getAcl /myapp

# ACL Schemes
# world:anyone - all clients
# auth - authenticated users
# digest:user:password - digest auth
# sasl:user - SASL/Kerberos
# ip:addr/bits - IP-based
```

### ACL Permissions

| Permission | Symbol | Description |
|------------|--------|-------------|
| CREATE | c | Create child nodes |
| DELETE | d | Delete child nodes |
| READ | r | Read data and list children |
| WRITE | w | Set data |
| ADMIN | a | Set ACLs |

## Monitoring

### Prometheus Metrics

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'zookeeper'
    static_configs:
      - targets: ['zk1:7000', 'zk2:7000', 'zk3:7000']
```

### Key Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `zk_outstanding_requests` | Queued requests | > 10 |
| `zk_avg_latency` | Average latency (ms) | > 100 |
| `zk_max_latency` | Max latency (ms) | > 1000 |
| `zk_packets_received` | Packets received/sec | - |
| `zk_packets_sent` | Packets sent/sec | - |
| `zk_num_alive_connections` | Active connections | - |
| `zk_znode_count` | Total znodes | > 1000000 |
| `zk_watch_count` | Active watches | > 100000 |
| `zk_ephemerals_count` | Ephemeral nodes | - |
| `zk_approximate_data_size` | Data size (bytes) | > 1GB |
| `zk_followers` | Follower count (leader only) | < expected |
| `zk_synced_followers` | Synced followers | < quorum |

### 4-Letter Commands

```bash
# Check if server is running
echo ruok | nc zk1 2181
# Expected: imok

# Get server stats
echo stat | nc zk1 2181

# Check if read-only mode
echo isro | nc zk1 2181
# Expected: rw or ro

# Monitor statistics
echo mntr | nc zk1 2181

# Server configuration
echo conf | nc zk1 2181

# Connection info
echo cons | nc zk1 2181

# Watch summary
echo wchs | nc zk1 2181

# Environment info
echo envi | nc zk1 2181
```

### Grafana Dashboard

```json
{
  "dashboard": {
    "title": "ZooKeeper Ensemble",
    "panels": [
      {
        "title": "Outstanding Requests",
        "targets": [{"expr": "zk_outstanding_requests"}]
      },
      {
        "title": "Average Latency",
        "targets": [{"expr": "zk_avg_latency"}]
      },
      {
        "title": "Connection Count",
        "targets": [{"expr": "zk_num_alive_connections"}]
      },
      {
        "title": "ZNode Count",
        "targets": [{"expr": "zk_znode_count"}]
      },
      {
        "title": "Leader/Follower Status",
        "targets": [{"expr": "zk_server_state"}]
      }
    ]
  }
}
```

### Health Check Script

```bash
#!/bin/bash
# zk-health-check.sh

HOSTS="zk1:2181 zk2:2181 zk3:2181"
LEADER_COUNT=0
FOLLOWER_COUNT=0

for host in $HOSTS; do
  MODE=$(echo stat | nc -w 2 ${host%:*} ${host#*:} 2>/dev/null | grep Mode | awk '{print $2}')
  
  case $MODE in
    leader)
      echo "$host: LEADER"
      ((LEADER_COUNT++))
      ;;
    follower)
      echo "$host: FOLLOWER"
      ((FOLLOWER_COUNT++))
      ;;
    *)
      echo "$host: DOWN or UNKNOWN"
      ;;
  esac
done

echo "---"
echo "Leaders: $LEADER_COUNT, Followers: $FOLLOWER_COUNT"

if [ $LEADER_COUNT -ne 1 ]; then
  echo "ERROR: Expected 1 leader, found $LEADER_COUNT"
  exit 1
fi

TOTAL=$((LEADER_COUNT + FOLLOWER_COUNT))
if [ $TOTAL -lt 2 ]; then
  echo "ERROR: Quorum not met (need 2, have $TOTAL)"
  exit 1
fi

echo "Cluster is healthy"
exit 0
```

## Data Management

### Snapshot and Transaction Logs

```bash
# View transaction logs
java -cp /opt/zookeeper/lib/*:/opt/zookeeper/lib/*.jar \
  org.apache.zookeeper.server.LogFormatter \
  /var/lib/zookeeper/version-2/log.100000001

# View snapshots
java -cp /opt/zookeeper/lib/*:/opt/zookeeper/lib/*.jar \
  org.apache.zookeeper.server.SnapshotFormatter \
  /var/lib/zookeeper/version-2/snapshot.100000001

# Manual purge of old files
java -cp /opt/zookeeper/lib/*:/opt/zookeeper/lib/*.jar \
  org.apache.zookeeper.server.PurgeTxnLog \
  /var/lib/zookeeper/data /var/lib/zookeeper/log -n 3
```

### Backup and Recovery

```bash
#!/bin/bash
# zk-backup.sh

BACKUP_DIR="/backups/zookeeper/$(date +%Y%m%d)"
ZK_DATA="/var/lib/zookeeper"

mkdir -p $BACKUP_DIR

# Stop writes (if possible) or accept slight inconsistency
# Create snapshot
echo "Creating snapshot..."
tar -czf $BACKUP_DIR/zk-data.tar.gz -C $ZK_DATA .

# Backup configuration
cp /etc/zookeeper/zoo.cfg $BACKUP_DIR/
cp /etc/zookeeper/myid $BACKUP_DIR/

echo "Backup complete: $BACKUP_DIR"
```

```bash
#!/bin/bash
# zk-restore.sh

BACKUP_DIR=$1
ZK_DATA="/var/lib/zookeeper"

if [ -z "$BACKUP_DIR" ]; then
  echo "Usage: $0 /path/to/backup"
  exit 1
fi

# Stop ZooKeeper
systemctl stop zookeeper

# Clear existing data
rm -rf $ZK_DATA/version-2/*

# Restore data
tar -xzf $BACKUP_DIR/zk-data.tar.gz -C $ZK_DATA

# Restore config
cp $BACKUP_DIR/zoo.cfg /etc/zookeeper/

# Start ZooKeeper
systemctl start zookeeper

echo "Restore complete"
```

## Performance Tuning

### Disk I/O Optimization

```bash
# Use dedicated SSD for transaction logs
# Separate dataDir and dataLogDir

# In zoo.cfg
dataDir=/var/lib/zookeeper/data
dataLogDir=/mnt/ssd/zookeeper/log

# Disable atime updates
# /etc/fstab
/dev/sdb1 /mnt/ssd ext4 noatime,nodiratime 0 0
```

### Network Optimization

```bash
# Increase socket buffers
sysctl -w net.core.rmem_max=16777216
sysctl -w net.core.wmem_max=16777216
sysctl -w net.ipv4.tcp_rmem="4096 87380 16777216"
sysctl -w net.ipv4.tcp_wmem="4096 65536 16777216"

# Enable TCP keepalive
sysctl -w net.ipv4.tcp_keepalive_time=60
sysctl -w net.ipv4.tcp_keepalive_intvl=10
sysctl -w net.ipv4.tcp_keepalive_probes=6
```

### Resource Limits

```bash
# /etc/security/limits.d/zookeeper.conf
zookeeper soft nofile 65535
zookeeper hard nofile 65535
zookeeper soft nproc 32768
zookeeper hard nproc 32768
```

## Related Documentation

- [Index](index.md) - Quick start and features overview
- [Usage](usage.md) - Deployment examples and troubleshooting
