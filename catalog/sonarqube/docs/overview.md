# Overview

## Architecture Deep Dive

SonarQube uses a 3-tier architecture with the Web Server, Compute Engine, and Elasticsearch for fast searching.

### Component Architecture

```d2
direction: down

web: Web Server {
  api: REST API (/api/*) {
    shape: hexagon
  }
  ui: Web UI (React)
  auth: Authentication (SAML/LDAP/OAuth) {
    shape: hexagon
  }
}

compute: Compute Engine {
  analyzers: Analyzers (Per Lang) {
    shape: hexagon
  }
  rules: Rules Engine {
    shape: hexagon
  }
  issues: Issue Detection & Quality Gate Eval {
    shape: hexagon
  }
  analyzers -> rules: apply
  rules -> issues: detect
}

storage: Data Storage {
  elastic: Elasticsearch {
    shape: cylinder
  }
  postgres: PostgreSQL {
    shape: cylinder
  }
}

web -> compute: submit analysis
compute -> storage: persist results
```

### Analysis Flow

```d2
direction: down

scanner_phase: 1. Scanner Phase {
  source: Source Code {
    shape: document
  }
  scanner: SonarScanner {
    shape: hexagon
  }
  report: Analysis Report (.scannerwork/) {
    shape: document
  }
  source -> scanner -> report
}

submission: 2. Submission Phase {
  upload: HTTP Upload to SonarQube Server {
    shape: rectangle
  }
  api: POST /api/ce/submit {
    shape: rectangle
  }
  upload -> api
}

processing: 3. Compute Engine Processing {
  unzip: Unzip & Parse {
    shape: hexagon
  }
  rules: Run Rules Engine {
    shape: hexagon
  }
  evaluate: Evaluate Quality Gate {
    shape: hexagon
  }
  unzip -> rules -> evaluate
}

results: 4. Results {
  issues: Issues stored in PostgreSQL {
    shape: cylinder
  }
  metrics: Metrics calculated
  gate: Quality Gate status updated
  webhooks: Webhooks triggered
}

scanner_phase -> submission -> processing -> results
```

## Configuration

### Server Configuration (sonar.properties)

```properties
# Database Configuration
sonar.jdbc.username=sonarqube
sonar.jdbc.password=sonarqube_password
sonar.jdbc.url=jdbc:postgresql://postgres:5432/sonarqube

# Web Server
sonar.web.host=0.0.0.0
sonar.web.port=9000
sonar.web.context=/sonarqube

# Compute Engine
sonar.ce.workerCount=2

# Elasticsearch
sonar.search.host=127.0.0.1
sonar.search.port=9001
sonar.search.javaOpts=-Xmx512m -Xms512m

# Authentication
sonar.forceAuthentication=true
sonar.security.realm=LDAP

# LDAP Configuration
sonar.security.ldap.url=ldap://ldap.example.com:389
sonar.security.ldap.bindDn=cn=admin,dc=example,dc=com
sonar.security.ldap.bindPassword=admin_password
sonar.security.ldap.user.baseDn=ou=users,dc=example,dc=com
sonar.security.ldap.user.request=(&(objectClass=person)(uid={login}))

# SSO/SAML Configuration
sonar.auth.saml.enabled=true
sonar.auth.saml.applicationId=sonarqube
sonar.auth.saml.providerName=SAML
sonar.auth.saml.providerId=https://idp.example.com
sonar.auth.saml.loginUrl=https://idp.example.com/sso
sonar.auth.saml.certificate.secured=<base64-encoded-cert>

# Proxy Settings
http.proxyHost=proxy.example.com
http.proxyPort=8080
http.nonProxyHosts=localhost|127.0.0.1
```

### Scanner Configuration (sonar-project.properties)

```properties
# Project identification
sonar.projectKey=my-company:my-project
sonar.projectName=My Project
sonar.projectVersion=1.0.0

# Source code location
sonar.sources=src/main
sonar.tests=src/test
sonar.java.binaries=target/classes
sonar.java.libraries=target/dependency/*.jar

# Exclusions
sonar.exclusions=**/generated/**,**/vendor/**
sonar.test.exclusions=**/test/**
sonar.coverage.exclusions=**/dto/**,**/config/**

# Coverage reports
sonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
sonar.javascript.lcov.reportPaths=coverage/lcov.info
sonar.python.coverage.reportPaths=coverage.xml
sonar.go.coverage.reportPaths=coverage.out

# Encoding
sonar.sourceEncoding=UTF-8

# Branch analysis (Developer Edition+)
sonar.branch.name=${BRANCH_NAME}
sonar.pullrequest.key=${PR_NUMBER}
sonar.pullrequest.branch=${PR_BRANCH}
sonar.pullrequest.base=${PR_TARGET}
```

### Quality Profile Configuration

```json
{
  "name": "Custom Java Profile",
  "language": "java",
  "parent": "Sonar way",
  "rules": [
    {
      "key": "java:S1135",
      "severity": "MAJOR",
      "params": {}
    },
    {
      "key": "java:S2259",
      "severity": "BLOCKER",
      "params": {}
    },
    {
      "key": "java:S3776",
      "severity": "CRITICAL",
      "params": {
        "Threshold": "10"
      }
    }
  ]
}
```

## Security Configuration

### Authentication Methods

```yaml
# SAML 2.0 Configuration
sonar.auth.saml.enabled: true
sonar.auth.saml.applicationId: sonarqube
sonar.auth.saml.providerName: 'Corporate SSO'
sonar.auth.saml.providerId: https://sso.company.com
sonar.auth.saml.loginUrl: https://sso.company.com/saml/sso
sonar.auth.saml.user.login: login
sonar.auth.saml.user.name: displayName
sonar.auth.saml.user.email: email
sonar.auth.saml.group.name: groups

# GitHub OAuth
sonar.auth.github.enabled: true
sonar.auth.github.clientId.secured: <client-id>
sonar.auth.github.clientSecret.secured: <client-secret>
sonar.auth.github.organizations: my-org
sonar.auth.github.allowUsersToSignUp: false

# GitLab OAuth
sonar.auth.gitlab.enabled: true
sonar.auth.gitlab.url: https://gitlab.company.com
sonar.auth.gitlab.applicationId.secured: <app-id>
sonar.auth.gitlab.secret.secured: <secret>
```

### Token Management

```bash
# Generate user token via API
curl -u admin:admin -X POST \
  "http://localhost:9000/api/user_tokens/generate" \
  -d "name=ci-token&type=USER_TOKEN"

# Generate project analysis token
curl -u admin:admin -X POST \
  "http://localhost:9000/api/user_tokens/generate" \
  -d "name=project-token&type=PROJECT_ANALYSIS_TOKEN&projectKey=my-project"

# Generate global analysis token (admin only)
curl -u admin:admin -X POST \
  "http://localhost:9000/api/user_tokens/generate" \
  -d "name=global-token&type=GLOBAL_ANALYSIS_TOKEN"

# Revoke token
curl -u admin:admin -X POST \
  "http://localhost:9000/api/user_tokens/revoke" \
  -d "name=old-token"
```

### Permission Templates

```bash
# Create permission template
curl -u admin:admin -X POST \
  "http://localhost:9000/api/permissions/create_template" \
  -d "name=Default&description=Default+permissions"

# Add group permission
curl -u admin:admin -X POST \
  "http://localhost:9000/api/permissions/add_group_to_template" \
  -d "templateName=Default&groupName=developers&permission=codeviewer"

# Apply template to project
curl -u admin:admin -X POST \
  "http://localhost:9000/api/permissions/apply_template" \
  -d "projectKey=my-project&templateName=Default"
```

## Monitoring

### Health Check Endpoints

```bash
# System health
curl http://localhost:9000/api/system/health
# Response: {"health":"GREEN","causes":[]}

# System status
curl http://localhost:9000/api/system/status
# Response: {"id":"server-id","version":"10.4","status":"UP"}

# Database migration status
curl http://localhost:9000/api/system/db_migration_status
# Response: {"state":"NO_MIGRATION","message":"Database is up-to-date"}
```

### Prometheus Metrics

```yaml
# prometheus.yml scrape config
scrape_configs:
  - job_name: 'sonarqube'
    metrics_path: '/api/monitoring/metrics'
    static_configs:
      - targets: ['sonarqube:9000']
    basic_auth:
      username: 'monitoring-user'
      password: 'monitoring-password'
```

### Key Metrics to Monitor

| Metric                                       | Description            | Alert Threshold   |
| -------------------------------------------- | ---------------------- | ----------------- |
| `sonarqube_health`                           | Overall health status  | != GREEN          |
| `sonarqube_compute_engine_pending_count`     | Pending analysis tasks | > 10              |
| `sonarqube_compute_engine_in_progress_count` | Active analysis tasks  | > workers         |
| `sonarqube_web_uptime_minutes`               | Web server uptime      | < 5 after restart |
| `sonarqube_database_pool_active_connections` | Active DB connections  | > 80% of max      |

### Logging Configuration

```properties
# conf/sonar.properties
sonar.log.level=INFO
sonar.log.level.app=INFO
sonar.log.level.web=INFO
sonar.log.level.ce=INFO
sonar.log.level.es=INFO

# Enable SQL logging for debugging
sonar.log.level.sql=DEBUG

# Log to file
sonar.path.logs=/opt/sonarqube/logs
sonar.log.rollingPolicy=time:yyyy-MM-dd
sonar.log.maxFiles=7
```

## Webhook Configuration

```bash
# Create webhook for quality gate status
curl -u admin:admin -X POST \
  "http://localhost:9000/api/webhooks/create" \
  -d "name=CI+Webhook" \
  -d "url=https://ci.example.com/sonarqube/webhook" \
  -d "secret=webhook-secret-key"
```

### Webhook Payload Example

```json
{
  "serverUrl": "http://sonarqube.example.com",
  "taskId": "AXoKLm...",
  "status": "SUCCESS",
  "analysedAt": "2024-01-15T10:30:00+0000",
  "revision": "abc123def456",
  "changedAt": "2024-01-15T10:30:00+0000",
  "project": {
    "key": "my-project",
    "name": "My Project",
    "url": "http://sonarqube.example.com/dashboard?id=my-project"
  },
  "branch": {
    "name": "main",
    "type": "LONG",
    "isMain": true,
    "url": "http://sonarqube.example.com/dashboard?id=my-project"
  },
  "qualityGate": {
    "name": "Sonar way",
    "status": "OK",
    "conditions": [
      {
        "metric": "new_reliability_rating",
        "operator": "GREATER_THAN",
        "value": "1",
        "status": "OK",
        "errorThreshold": "1"
      }
    ]
  }
}
```

## Backup and Recovery

### Database Backup

```bash
# PostgreSQL backup
pg_dump -h postgres -U sonarqube -d sonarqube > sonarqube_backup.sql

# Restore
psql -h postgres -U sonarqube -d sonarqube < sonarqube_backup.sql
```

### Full Backup Script

```bash
#!/bin/bash
BACKUP_DIR=/backups/sonarqube/$(date +%Y%m%d)
mkdir -p $BACKUP_DIR

# Stop SonarQube (optional for consistency)
docker-compose stop sonarqube

# Backup database
docker-compose exec -T postgres pg_dump -U sonarqube sonarqube > $BACKUP_DIR/database.sql

# Backup configuration
cp -r /opt/sonarqube/conf $BACKUP_DIR/conf
cp -r /opt/sonarqube/extensions $BACKUP_DIR/extensions

# Restart SonarQube
docker-compose start sonarqube

# Cleanup old backups (keep 30 days)
find /backups/sonarqube -type d -mtime +30 -exec rm -rf {} \;
```
