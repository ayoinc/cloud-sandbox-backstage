# Overview

## Architecture Deep Dive

Nexus Repository Manager provides a flexible architecture for managing artifacts across multiple formats with enterprise-grade features.

### Component Architecture

```d2
direction: down

title: Nexus Repository Manager Components {
  shape: text
  near: top-center
  style.font-size: 24
}

nexus: Nexus Repository Manager {
  shape: rectangle
  style.fill: "#FAFAFA"
  
  app_layer: Application Layer {
    shape: rectangle
    style.fill: "#E3F2FD"
    
    rest_api: REST API {
      shape: rectangle
      style.fill: "#2196F3"
      style.font-color: white
      label: "/service/rest/*"
    }
    
    web_ui: Web UI {
      shape: rectangle
      style.fill: "#2196F3"
      style.font-color: white
      label: "React Frontend"
    }
    
    plugins: Format Plugins {
      shape: rectangle
      style.fill: "#2196F3"
      style.font-color: white
      label: "Maven, npm, Docker, PyPI..."
    }
  }
  
  core_layer: Core Services {
    shape: rectangle
    style.fill: "#C8E6C9"
    
    repo_mgr: Repository Manager {
      shape: rectangle
      style.fill: "#4CAF50"
      style.font-color: white
    }
    
    security_mgr: Security Manager {
      shape: rectangle
      style.fill: "#4CAF50"
      style.font-color: white
      label: "LDAP/SAML/RBAC"
    }
    
    scheduler: Scheduler {
      shape: rectangle
      style.fill: "#4CAF50"
      style.font-color: white
      label: "Tasks & Cleanup"
    }
  }
  
  data_layer: Data Layer {
    shape: rectangle
    style.fill: "#E1BEE7"
    
    orientdb: OrientDB {
      shape: cylinder
      style.fill: "#9C27B0"
      style.font-color: white
      label: "Metadata"
    }
    
    blobstore: Blob Store {
      shape: cylinder
      style.fill: "#9C27B0"
      style.font-color: white
      label: "Artifacts"
    }
    
    elasticsearch: Elasticsearch {
      shape: cylinder
      style.fill: "#9C27B0"
      style.font-color: white
      label: "Search (Pro)"
    }
  }
}

nexus.app_layer -> nexus.core_layer
nexus.core_layer -> nexus.data_layer
```

### Request Flow

```d2
direction: down

title: Client Request Flow {
  shape: text
  near: top-center
  style.font-size: 24
}

client: Client (Maven/npm/Docker) {
  shape: rectangle
  style.fill: "#E3F2FD"
}

lb: Load Balancer {
  shape: hexagon
  style.fill: "#FF9800"
  style.font-color: white
  label: "(optional)"
}

nexus: Nexus Repository Manager {
  shape: rectangle
  style.fill: "#FAFAFA"
  
  handler: Request Handler {
    shape: rectangle
    style.fill: "#C8E6C9"
    
    auth: Authentication Check
    authz: Authorization Check
    route: Route to Repository
  }
  
  repos: Repository Types {
    shape: rectangle
    style.fill: "#E1BEE7"
    
    hosted: Hosted Repo {
      shape: cylinder
      style.fill: "#81C784"
    }
    
    proxy: Proxy Repo {
      shape: cylinder
      style.fill: "#4FC3F7"
    }
    
    group: Group Repo {
      shape: cylinder
      style.fill: "#FFB74D"
    }
  }
  
  blobstore: Blob Store {
    shape: cylinder
    style.fill: "#9C27B0"
    style.font-color: white
    label: "Return Artifact"
  }
}

remote: Remote Repository {
  shape: cloud
  style.fill: "#B3E5FC"
  label: "(if not cached)"
}

client -> lb: Request
lb -> nexus.handler: Forward
nexus.handler -> nexus.repos: Route
nexus.repos.proxy -> remote: Fetch if miss
nexus.repos -> nexus.blobstore: Retrieve
```

## Configuration

### nexus.properties

```properties
# $install-dir/etc/nexus-default.properties

# Application settings
application-port=8081
application-host=0.0.0.0
nexus-context-path=/

# JVM settings
nexus-args=${jetty.etc}/jetty.xml,${jetty.etc}/jetty-http.xml,${jetty.etc}/jetty-requestlog.xml

# Karaf settings
karaf.startLocalConsole=false
karaf.startRemoteShell=false

# Data directory
karaf.data=./sonatype-work/nexus3

# Logging
java.util.logging.config.file=${karaf.data}/etc/java.util.logging.properties
```

### JVM Configuration

```properties
# $install-dir/bin/nexus.vmoptions

# Memory settings (adjust based on available RAM)
-Xms2703m
-Xmx2703m
-XX:MaxDirectMemorySize=2703m

# GC settings
-XX:+UseG1GC
-XX:MaxGCPauseMillis=200
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/nexus-data/jvm.hprof

# JMX monitoring
-Dcom.sun.management.jmxremote
-Dcom.sun.management.jmxremote.port=9090
-Dcom.sun.management.jmxremote.ssl=false
-Dcom.sun.management.jmxremote.authenticate=false

# Networking
-Djava.net.preferIPv4Stack=true
```

### Repository Configuration (REST API)

```bash
# Create Maven hosted repository
curl -X POST "http://localhost:8081/service/rest/v1/repositories/maven/hosted" \
  -H "Content-Type: application/json" \
  -u admin:admin123 \
  -d '{
    "name": "maven-internal",
    "online": true,
    "storage": {
      "blobStoreName": "default",
      "strictContentTypeValidation": true,
      "writePolicy": "ALLOW_ONCE"
    },
    "maven": {
      "versionPolicy": "RELEASE",
      "layoutPolicy": "STRICT"
    }
  }'

# Create npm proxy repository
curl -X POST "http://localhost:8081/service/rest/v1/repositories/npm/proxy" \
  -H "Content-Type: application/json" \
  -u admin:admin123 \
  -d '{
    "name": "npm-proxy",
    "online": true,
    "storage": {
      "blobStoreName": "default",
      "strictContentTypeValidation": true
    },
    "proxy": {
      "remoteUrl": "https://registry.npmjs.org",
      "contentMaxAge": 1440,
      "metadataMaxAge": 1440
    },
    "negativeCache": {
      "enabled": true,
      "timeToLive": 1440
    },
    "httpClient": {
      "blocked": false,
      "autoBlock": true
    }
  }'

# Create Docker hosted repository
curl -X POST "http://localhost:8081/service/rest/v1/repositories/docker/hosted" \
  -H "Content-Type: application/json" \
  -u admin:admin123 \
  -d '{
    "name": "docker-private",
    "online": true,
    "storage": {
      "blobStoreName": "docker-store",
      "strictContentTypeValidation": true,
      "writePolicy": "ALLOW"
    },
    "docker": {
      "v1Enabled": false,
      "forceBasicAuth": true,
      "httpPort": 5000
    }
  }'
```

## Security Configuration

### LDAP Integration

```json
{
  "name": "corporate-ldap",
  "protocol": "ldaps",
  "useTrustStore": true,
  "host": "ldap.company.com",
  "port": 636,
  "searchBase": "dc=company,dc=com",
  "authScheme": "SIMPLE",
  "authRealm": "",
  "authUsername": "cn=nexus,ou=services,dc=company,dc=com",
  "connectionTimeoutSeconds": 30,
  "connectionRetryDelaySeconds": 300,
  "maxIncidentsCount": 3,
  "userBaseDn": "ou=users",
  "userSubtree": true,
  "userObjectClass": "person",
  "userLdapFilter": "(memberOf=cn=nexus-users,ou=groups,dc=company,dc=com)",
  "userIdAttribute": "sAMAccountName",
  "userRealNameAttribute": "cn",
  "userEmailAddressAttribute": "mail",
  "userPasswordAttribute": "",
  "ldapGroupsAsRoles": true,
  "groupType": "dynamic",
  "groupBaseDn": "ou=groups",
  "groupSubtree": true,
  "groupObjectClass": "group",
  "groupIdAttribute": "cn",
  "groupMemberAttribute": "member",
  "groupMemberFormat": "${dn}",
  "userMemberOfAttribute": "memberOf"
}
```

### Role-Based Access Control

```bash
# Create role
curl -X POST "http://localhost:8081/service/rest/v1/security/roles" \
  -H "Content-Type: application/json" \
  -u admin:admin123 \
  -d '{
    "id": "developer-role",
    "name": "Developer Role",
    "description": "Read access to all repos, write to snapshots",
    "privileges": [
      "nx-repository-view-*-*-browse",
      "nx-repository-view-*-*-read",
      "nx-repository-view-maven2-maven-snapshots-*"
    ],
    "roles": []
  }'

# Create user
curl -X POST "http://localhost:8081/service/rest/v1/security/users" \
  -H "Content-Type: application/json" \
  -u admin:admin123 \
  -d '{
    "userId": "developer1",
    "firstName": "Dev",
    "lastName": "User",
    "emailAddress": "dev@company.com",
    "password": "secure-password",
    "status": "active",
    "roles": ["developer-role"]
  }'
```

### Content Selectors and Privileges

```bash
# Create content selector
curl -X POST "http://localhost:8081/service/rest/v1/security/content-selectors" \
  -H "Content-Type: application/json" \
  -u admin:admin123 \
  -d '{
    "name": "team-a-artifacts",
    "description": "Artifacts for Team A",
    "expression": "path =^ \"/com/company/team-a/\""
  }'

# Create privilege using selector
curl -X POST "http://localhost:8081/service/rest/v1/security/privileges/repository-content-selector" \
  -H "Content-Type: application/json" \
  -u admin:admin123 \
  -d '{
    "name": "team-a-read",
    "description": "Read Team A artifacts",
    "actions": ["browse", "read"],
    "format": "maven2",
    "repository": "*",
    "contentSelector": "team-a-artifacts"
  }'
```

## Cleanup Policies

```bash
# Create cleanup policy
curl -X POST "http://localhost:8081/service/rest/v1/cleanup-policies" \
  -H "Content-Type: application/json" \
  -u admin:admin123 \
  -d '{
    "name": "delete-old-snapshots",
    "format": "maven2",
    "notes": "Delete snapshots older than 30 days",
    "criteria": {
      "lastBlobUpdated": "30",
      "lastDownloaded": "30",
      "preRelease": "PRERELEASES"
    }
  }'

# Apply cleanup policy to repository
curl -X PUT "http://localhost:8081/service/rest/v1/repositories/maven/hosted/maven-snapshots" \
  -H "Content-Type: application/json" \
  -u admin:admin123 \
  -d '{
    "name": "maven-snapshots",
    "online": true,
    "storage": {
      "blobStoreName": "default",
      "strictContentTypeValidation": true,
      "writePolicy": "ALLOW"
    },
    "cleanup": {
      "policyNames": ["delete-old-snapshots"]
    },
    "maven": {
      "versionPolicy": "SNAPSHOT",
      "layoutPolicy": "STRICT"
    }
  }'
```

## Blob Store Configuration

### S3 Blob Store

```json
{
  "name": "s3-blobstore",
  "type": "S3",
  "attributes": {
    "s3": {
      "bucket": "nexus-artifacts",
      "prefix": "blobs",
      "region": "us-east-1",
      "accessKeyId": "AKIAIOSFODNN7EXAMPLE",
      "secretAccessKey": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
      "assumeRole": "",
      "sessionToken": "",
      "endpoint": "",
      "expiration": "3"
    }
  }
}
```

### Azure Blob Store

```json
{
  "name": "azure-blobstore",
  "type": "Azure Cloud Storage",
  "attributes": {
    "azure cloud storage": {
      "accountName": "nexusstorage",
      "containerName": "artifacts",
      "authenticationMethod": "ACCOUNTKEY",
      "accountKey": "your-account-key"
    }
  }
}
```

## Monitoring

### Health Check Endpoints

```bash
# System status
curl http://localhost:8081/service/rest/v1/status

# Read-only check
curl http://localhost:8081/service/rest/v1/read-only

# Available system status checks
curl http://localhost:8081/service/rest/v1/status/check
```

### Prometheus Metrics (Pro)

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'nexus'
    metrics_path: /service/metrics/prometheus
    static_configs:
      - targets: ['nexus:8081']
    basic_auth:
      username: 'admin'
      password: 'admin123'
```

### Key Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `nexus_repository_blob_count` | Total blob count | N/A (tracking) |
| `nexus_repository_total_size_bytes` | Total storage used | > 80% capacity |
| `nexus_request_duration_seconds` | Request latency | p95 > 1s |
| `nexus_component_upload_count` | Uploads per period | Anomaly detection |
| `jvm_memory_used_bytes` | JVM heap usage | > 80% |

## Scheduled Tasks

```bash
# Create scheduled task (compact blob store)
curl -X POST "http://localhost:8081/service/rest/v1/tasks" \
  -H "Content-Type: application/json" \
  -u admin:admin123 \
  -d '{
    "name": "Compact Default Blob Store",
    "typeId": "blobstore.compact",
    "enabled": true,
    "alertEmail": "ops@company.com",
    "schedule": {
      "type": "cron",
      "cron": "0 0 3 * * ?"
    },
    "properties": {
      "blobstoreName": "default"
    }
  }'
```

### Common Scheduled Tasks

| Task | Purpose | Recommended Schedule |
|------|---------|---------------------|
| `repository.cleanup` | Delete artifacts per cleanup policies | Daily, off-hours |
| `blobstore.compact` | Reclaim deleted blob space | Weekly |
| `db.backup` | Backup OrientDB | Daily |
| `repository.maven-remove-snapshots` | Remove old snapshots | Daily |
| `rebuild.browse` | Rebuild browse nodes | After major changes |
