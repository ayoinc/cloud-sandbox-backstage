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

```
┌─────────────────────────────────────────────────────────────────┐
│                     MinIO Distributed Cluster                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    Load Balancer                          │  │
│  │              (nginx / HAProxy / Traefik)                  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                              │                                  │
│         ┌────────────────────┼────────────────────┐             │
│         │                    │                    │             │
│         ▼                    ▼                    ▼             │
│  ┌─────────────┐      ┌─────────────┐      ┌─────────────┐      │
│  │   MinIO 1   │      │   MinIO 2   │      │   MinIO 3   │      │
│  │  :9000/9001 │      │  :9000/9001 │      │  :9000/9001 │      │
│  └──────┬──────┘      └──────┬──────┘      └──────┬──────┘      │
│         │                    │                    │             │
│         ▼                    ▼                    ▼             │
│  ┌─────────────┐      ┌─────────────┐      ┌─────────────┐      │
│  │   Disk 1    │      │   Disk 1    │      │   Disk 1    │      │
│  │   Disk 2    │      │   Disk 2    │      │   Disk 2    │      │
│  │   Disk 3    │      │   Disk 3    │      │   Disk 3    │      │
│  │   Disk 4    │      │   Disk 4    │      │   Disk 4    │      │
│  └─────────────┘      └─────────────┘      └─────────────┘      │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                     Erasure Coding (EC:4)                       │
│         ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐       │
│         │D1 │D2 │D3 │D4 │D5 │D6 │D7 │D8 │P1 │P2 │P3 │P4 │       │
│         └───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┘       │
│                     Data Blocks    Parity Blocks                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │              Clients                     │
        │  ┌───────┐  ┌───────┐  ┌───────────┐    │
        │  │AWS SDK│  │ mc CLI│  │ Backstage │    │
        │  └───────┘  └───────┘  └───────────┘    │
        └─────────────────────────────────────────┘
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
