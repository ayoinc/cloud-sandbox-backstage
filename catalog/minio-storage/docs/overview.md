# MinIO Storage Overview

## Architecture Deep Dive

### Distributed Mode

MinIO distributed mode provides high availability and data protection through erasure coding:

```d2
direction: down

cluster: Distributed MinIO Cluster {
  style.fill: "#e3f2fd"

  flow: Write Request Flow {
    style.fill: "#e8f5e9"
    client: Client
    node: Any Node
    encode: Erasure Encode
    write: Write to All Drives

    client -> node -> encode -> write
  }

  erasure: Erasure Coding {
    style.fill: "#fff3e0"

    object: Original Object (100MB)
    coding: Reed-Solomon Encoding {
      style.fill: "#fce4ec"
    }

    shards: Data + Parity Shards {
      style.fill: "#f3e5f5"
      s1: "Shard 1 (Data)"
      s2: "Shard 2 (Data)"
      s3: "Shard 3 (Data)"
      s4: "Shard 4 (Data)"
      s5: "Shard 5 (Parity)"
      s6: "Shard 6 (Parity)"
      s7: "Shard 7 (Parity)"
      s8: "Shard 8 (Parity)"
    }

    object -> coding -> shards
  }

  nodes: Storage Nodes {
    style.fill: "#e0f7fa"
    node1: "Node 1 (2 drives)"
    node2: "Node 2 (2 drives)"
    node3: "Node 3 (2 drives)"
    node4: "Node 4 (2 drives)"
  }

  erasure.shards -> nodes
}
```

### Server Pools

```d2
direction: down

multipool: Multi-Pool Architecture {
  style.fill: "#e3f2fd"

  pools: Storage Pools {
    style.fill: "#f5f5f5"

    pool1: Pool 1 - Hot Storage (SSD) {
      style.fill: "#e8f5e9"
      node1: "Node 1 (4x drives)"
      node2: "Node 2 (4x drives)"
      node3: "Node 3 (4x drives)"
    }

    pool2: Pool 2 - Warm Storage (HDD) {
      style.fill: "#fff3e0"
      node4: "Node 4 (8x drives)"
      node5: "Node 5 (8x drives)"
      node6: "Node 6 (8x drives)"
    }
  }

  ilm: Lifecycle Rules (ILM Tiering) {
    style.fill: "#fce4ec"
  }

  pools.pool1 -> ilm: tier down
  pools.pool2 -> ilm: manage
}
```

## Configuration

### Environment Variables

```bash
# Core Configuration
MINIO_ROOT_USER=admin                    # Root user (access key)
MINIO_ROOT_PASSWORD=minio_secret_key     # Root password (secret key)

# Storage
MINIO_VOLUMES="/data{1...4}"             # Storage volumes
MINIO_STORAGE_CLASS_STANDARD="EC:4"      # Erasure coding parity
MINIO_STORAGE_CLASS_RRS="EC:2"           # Reduced redundancy

# Network
MINIO_SERVER_URL="https://minio.example.com:9000"
MINIO_BROWSER_REDIRECT_URL="https://console.minio.example.com"

# TLS
MINIO_OPTS="--certs-dir /certs"

# Identity
MINIO_IDENTITY_OPENID_CONFIG_URL="https://keycloak.example.com/realms/minio/.well-known/openid-configuration"
MINIO_IDENTITY_OPENID_CLIENT_ID="minio"
MINIO_IDENTITY_OPENID_CLAIM_NAME="policy"

# KMS (for encryption)
MINIO_KMS_KES_ENDPOINT="https://kes.example.com:7373"
MINIO_KMS_KES_KEY_FILE="/certs/minio.key"
MINIO_KMS_KES_CERT_FILE="/certs/minio.crt"
MINIO_KMS_KES_KEY_NAME="minio-key"

# Logging
MINIO_LOGGER_WEBHOOK_ENABLE_TARGET1="on"
MINIO_LOGGER_WEBHOOK_ENDPOINT_TARGET1="http://fluentd:8080"

# Prometheus
MINIO_PROMETHEUS_AUTH_TYPE="public"
MINIO_PROMETHEUS_URL="http://prometheus:9090"
```

### Configuration File

```yaml
# config.yaml (mc admin config export)
version: v1
region: us-east-1

storage_class:
  standard: 'EC:4'
  rrs: 'EC:2'

cache:
  drives: ['/mnt/cache1', '/mnt/cache2']
  expiry: 90
  quota: 80
  exclude: ['*.pdf', '*.zip']

compression:
  enable: true
  allow_encryption: false
  extensions: ['.txt', '.log', '.csv', '.json']
  mime_types: ['text/*', 'application/json']

identity_openid:
  config_url: 'https://keycloak.example.com/realms/minio/.well-known/openid-configuration'
  client_id: 'minio'
  claim_name: 'policy'
  claim_prefix: ''
  scopes: 'openid,profile,email'

notify_kafka:
  enable: true
  brokers: 'kafka1:9092,kafka2:9092'
  topic: 'minio-events'

audit_webhook:
  enable: true
  endpoint: 'http://audit-service:8080/logs'

heal:
  bitrotscan: true
  max_sleep: '1s'
  max_io: 10
```

### mc Admin Commands

```bash
# Configure alias
mc alias set myminio https://minio.example.com admin secretkey

# View/export configuration
mc admin config get myminio
mc admin config export myminio > config.txt

# Set configuration
mc admin config set myminio region name=us-east-1
mc admin config set myminio compression enable=on

# Restart to apply changes
mc admin service restart myminio

# Server info
mc admin info myminio

# Cluster health
mc admin heal myminio --recursive
```

## Security Configuration

### TLS Configuration

```bash
# Generate certificates
mkdir -p ~/.minio/certs

# Self-signed for testing
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ~/.minio/certs/private.key \
  -out ~/.minio/certs/public.crt \
  -subj "/CN=minio.example.com"

# Start with TLS
minio server --certs-dir ~/.minio/certs /data
```

### IAM Policies

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:ListBucket"],
      "Resource": ["arn:aws:s3:::my-bucket", "arn:aws:s3:::my-bucket/*"]
    }
  ]
}
```

```bash
# Create policy
mc admin policy create myminio readonly-policy policy.json

# Create user and attach policy
mc admin user add myminio readonly-user secretpassword
mc admin policy attach myminio readonly-policy --user readonly-user

# Create service account
mc admin user svcacct add myminio admin --access-key myaccesskey --secret-key mysecretkey

# Group management
mc admin group add myminio developers user1 user2
mc admin policy attach myminio readwrite --group developers
```

### Server-Side Encryption

```bash
# SSE-S3 (Server-managed keys)
mc cp --encrypt "s3" file.txt myminio/bucket/

# SSE-C (Customer-provided keys)
mc cp --encrypt "c:my-encryption-key" file.txt myminio/bucket/

# Set default encryption on bucket
mc encrypt set sse-s3 myminio/bucket

# Enable encryption with KMS
mc admin kms key create myminio my-key
mc encrypt set sse-kms my-key myminio/bucket
```

### Object Locking (WORM)

```bash
# Create bucket with object locking
mc mb --with-lock myminio/compliance-bucket

# Set default retention
mc retention set --default GOVERNANCE "30d" myminio/compliance-bucket

# Set compliance mode (cannot be overridden)
mc retention set --default COMPLIANCE "7y" myminio/archive-bucket

# Enable legal hold
mc legalhold set myminio/compliance-bucket/document.pdf
```

## Bucket Management

### Lifecycle Rules (ILM)

```json
{
  "Rules": [
    {
      "ID": "expire-temp-files",
      "Status": "Enabled",
      "Filter": {
        "Prefix": "temp/"
      },
      "Expiration": {
        "Days": 7
      }
    },
    {
      "ID": "transition-to-glacier",
      "Status": "Enabled",
      "Filter": {
        "Prefix": "logs/"
      },
      "Transition": {
        "Days": 30,
        "StorageClass": "GLACIER"
      }
    },
    {
      "ID": "delete-old-versions",
      "Status": "Enabled",
      "NoncurrentVersionExpiration": {
        "NoncurrentDays": 90
      }
    }
  ]
}
```

```bash
# Apply lifecycle rules
mc ilm import myminio/my-bucket < lifecycle.json

# List rules
mc ilm ls myminio/my-bucket

# Tier to remote storage
mc admin tier add myminio s3 WARM_TIER \
  --endpoint https://s3.amazonaws.com \
  --access-key AKIAIOSFODNN7EXAMPLE \
  --secret-key wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY \
  --bucket warm-bucket \
  --prefix archive/
```

### Versioning

```bash
# Enable versioning
mc version enable myminio/my-bucket

# List versions
mc ls --versions myminio/my-bucket/file.txt

# Get specific version
mc cp myminio/my-bucket/file.txt?versionId=abc123 ./

# Delete specific version
mc rm myminio/my-bucket/file.txt --version-id abc123
```

### Replication

```bash
# Configure replication (bucket to bucket)
mc replicate add myminio/source-bucket \
  --remote-bucket https://admin:password@remote.example.com/target-bucket \
  --replicate "delete,delete-marker,existing-objects"

# Site-to-site replication
mc admin replicate add myminio1 myminio2

# Check replication status
mc replicate status myminio/source-bucket
```

## Monitoring

### Prometheus Metrics

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'minio'
    metrics_path: /minio/v2/metrics/cluster
    scheme: http
    static_configs:
      - targets: ['minio1:9000', 'minio2:9000', 'minio3:9000']
    bearer_token: 'prometheus-token'
```

### Key Metrics

| Metric                                | Description           | Alert Threshold |
| ------------------------------------- | --------------------- | --------------- |
| `minio_cluster_health`                | Cluster health status | != 1            |
| `minio_cluster_disk_total_free_bytes` | Free disk space       | < 10% total     |
| `minio_cluster_disk_offline_total`    | Offline disks         | > 0             |
| `minio_node_disk_latency_us`          | Disk latency          | > 10000         |
| `minio_s3_requests_total`             | Total S3 requests     | -               |
| `minio_s3_requests_errors_total`      | Request errors        | > 1% of total   |
| `minio_s3_traffic_received_bytes`     | Ingress traffic       | -               |
| `minio_s3_traffic_sent_bytes`         | Egress traffic        | -               |
| `minio_heal_objects_total`            | Objects needing heal  | > 0             |

### Health Check Endpoints

```bash
# Liveness probe
curl http://minio:9000/minio/health/live

# Readiness probe
curl http://minio:9000/minio/health/ready

# Cluster health
curl http://minio:9000/minio/health/cluster

# Read quorum check
curl "http://minio:9000/minio/health/cluster?maintenance=true"
```

### Audit Logging

```bash
# Enable audit logging to webhook
mc admin config set myminio audit_webhook \
  endpoint="http://audit-server:8080/logs" \
  enable="on"

# View audit logs
mc admin logs myminio --type audit

# Stream logs
mc admin logs myminio --follow
```

### mc Admin Commands for Monitoring

```bash
# Server information
mc admin info myminio

# Real-time statistics
mc admin trace myminio -a -v

# Top-like view
mc admin top locks myminio

# Disk usage
mc admin du myminio/bucket

# Profiling
mc admin profile start myminio --type cpu
# Wait...
mc admin profile stop myminio

# Scanner status (healing)
mc admin scanner status myminio
```

## Performance Tuning

### Disk Configuration

```bash
# Use XFS filesystem
mkfs.xfs /dev/sdb
mount -o noatime,nodiratime /dev/sdb /data1

# fstab entry
/dev/sdb /data1 xfs noatime,nodiratime 0 0

# RAID configuration (use JBOD, not RAID)
# MinIO's erasure coding replaces RAID

# NVMe optimization
echo 'none' > /sys/block/nvme0n1/queue/scheduler
```

### Network Optimization

```bash
# Increase socket buffers
sysctl -w net.core.rmem_max=16777216
sysctl -w net.core.wmem_max=16777216
sysctl -w net.ipv4.tcp_rmem="4096 87380 16777216"
sysctl -w net.ipv4.tcp_wmem="4096 65536 16777216"

# Connection backlog
sysctl -w net.core.somaxconn=4096
sysctl -w net.ipv4.tcp_max_syn_backlog=4096
```

### MinIO Tuning

```bash
# Increase open file limits
# /etc/security/limits.d/minio.conf
minio soft nofile 65536
minio hard nofile 65536

# Memory-mapped I/O
MINIO_OPTS="--json"

# API rate limiting
mc admin config set myminio api requests_max=0 requests_deadline=10s

# Caching (for hybrid deployments)
mc admin config set myminio cache \
  drives="/mnt/cache1,/mnt/cache2" \
  expiry=90 \
  quota=80
```

## Related Documentation

- [Index](index.md) - Quick start and features overview
- [Usage](usage.md) - Deployment examples and troubleshooting
