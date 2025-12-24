# MinIO Storage

High-performance, S3-compatible object storage for cloud-native applications, Kubernetes, and hybrid cloud environments.

## Quick Start

```bash
# Pull MinIO image
docker pull minio/minio:latest

# Run MinIO server
docker run -d --name minio \
  -p 9000:9000 \
  -p 9001:9001 \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin \
  -v minio_data:/data \
  minio/minio server /data --console-address ":9001"

# Access Console
open http://localhost:9001

# Install MinIO Client (mc)
brew install minio/stable/mc
# or
curl https://dl.min.io/client/mc/release/linux-amd64/mc -o mc && chmod +x mc

# Configure mc alias
mc alias set local http://localhost:9000 minioadmin minioadmin

# Basic operations
mc mb local/my-bucket              # Create bucket
mc cp file.txt local/my-bucket/    # Upload file
mc ls local/my-bucket/             # List objects
mc cat local/my-bucket/file.txt    # View content
mc rm local/my-bucket/file.txt     # Delete object
```

## Features

| Feature | Description | Use Case |
|---------|-------------|----------|
| **S3 Compatibility** | Full AWS S3 API support | Drop-in S3 replacement |
| **Erasure Coding** | Data protection without RAID | High durability (99.999999999%) |
| **Bitrot Protection** | HighwayHash checksum verification | Data integrity |
| **Encryption** | SSE-S3, SSE-C, SSE-KMS | Security compliance |
| **Object Locking** | WORM, governance, compliance | Regulatory compliance |
| **Versioning** | Object version history | Data protection |
| **Replication** | Site-to-site, bucket replication | Disaster recovery |
| **Tiering** | Hot/warm/cold data lifecycle | Cost optimization |
| **Identity Management** | LDAP, OIDC, IAM policies | Enterprise security |
| **Kubernetes Native** | Operator, CSI driver | Cloud-native deployment |

## Architecture

```d2
direction: down

cluster: MinIO Distributed Cluster {
  lb: Load Balancer (nginx / HAProxy / Traefik)
  
  servers: MinIO Servers {
    m1: MinIO 1 (:9000/9001) {
      shape: hexagon
    }
    m2: MinIO 2 (:9000/9001) {
      shape: hexagon
    }
    m3: MinIO 3 (:9000/9001) {
      shape: hexagon
    }
  }
  
  storage: Storage Layer {
    d1: Disks 1-4 {
      shape: cylinder
    }
    d2: Disks 1-4 {
      shape: cylinder
    }
    d3: Disks 1-4 {
      shape: cylinder
    }
  }
  
  lb -> servers.m1
  lb -> servers.m2
  lb -> servers.m3
  servers.m1 -> storage.d1
  servers.m2 -> storage.d2
  servers.m3 -> storage.d3
}

erasure: Erasure Coding (EC:4) {
  data: Data Blocks (D1-D8)
  parity: Parity Blocks (P1-P4)
}

clients: Clients {
  sdk: AWS SDK
  cli: mc CLI
  backstage: Backstage
}

clients -> cluster.lb: S3 API
cluster -> erasure: protects
```

## Erasure Coding

| Configuration | Data Drives | Parity Drives | Drive Tolerance |
|---------------|-------------|---------------|-----------------|
| EC:4 (default) | 8 | 4 | 4 drives can fail |
| EC:3 | 9 | 3 | 3 drives can fail |
| EC:2 | 10 | 2 | 2 drives can fail |

## Version Information

| Component | Version | Release Date |
|-----------|---------|--------------|
| MinIO Server | RELEASE.2024-01-29 | 2024 |
| MinIO Client (mc) | RELEASE.2024-01-28 | 2024 |
| MinIO Operator | 5.0.12 | 2024 |
| MinIO Console | Bundled | - |

## Ports Reference

| Port | Protocol | Purpose |
|------|----------|---------|
| 9000 | HTTP/HTTPS | S3 API endpoint |
| 9001 | HTTP/HTTPS | Console UI |

## Storage Requirements

| Deployment | Minimum Drives | Recommended |
|------------|---------------|-------------|
| Standalone | 1 | 4+ |
| Distributed | 4 | 16+ (across 4+ nodes) |
| Production | 8+ per node | 12-16 per node |

## Related Documentation

- [Overview](overview.md) - Architecture, configuration, security, and monitoring
- [Usage](usage.md) - Deployment examples, SDK usage, and troubleshooting
