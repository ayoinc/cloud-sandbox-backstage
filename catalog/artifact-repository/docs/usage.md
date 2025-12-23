# Usage Guide

## Docker Compose Deployment

### Development Setup

```yaml
# docker-compose.yaml
version: '3.8'

services:
  nexus:
    image: sonatype/nexus3:3.66.0
    container_name: nexus
    ports:
      - "8081:8081"      # Web UI and API
      - "5000:5000"      # Docker registry (hosted)
      - "5001:5001"      # Docker registry (group)
    volumes:
      - nexus-data:/nexus-data
    environment:
      INSTALL4J_ADD_VM_PARAMS: >-
        -Xms2g -Xmx2g
        -XX:MaxDirectMemorySize=2g
        -Djava.util.prefs.userRoot=/nexus-data/javaprefs
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8081/service/rest/v1/status"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 120s
    networks:
      - nexus-net

  nginx:
    image: nginx:alpine
    container_name: nexus-nginx
    ports:
      - "443:443"
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certs:/etc/nginx/certs:ro
    depends_on:
      - nexus
    networks:
      - nexus-net

volumes:
  nexus-data:

networks:
  nexus-net:
    driver: bridge
```

### Nginx Configuration

```nginx
# nginx.conf
events {
    worker_connections 1024;
}

http {
    upstream nexus {
        server nexus:8081;
    }

    upstream docker-hosted {
        server nexus:5000;
    }

    upstream docker-group {
        server nexus:5001;
    }

    # Main Nexus
    server {
        listen 443 ssl;
        server_name nexus.company.com;

        ssl_certificate /etc/nginx/certs/nexus.crt;
        ssl_certificate_key /etc/nginx/certs/nexus.key;

        client_max_body_size 1G;

        location / {
            proxy_pass http://nexus;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }

    # Docker Registry
    server {
        listen 443 ssl;
        server_name docker.company.com;

        ssl_certificate /etc/nginx/certs/docker.crt;
        ssl_certificate_key /etc/nginx/certs/docker.key;

        client_max_body_size 2G;

        location / {
            proxy_pass http://docker-group;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

## Kubernetes Deployment

### Helm Installation

```bash
# Add Sonatype Helm repository
helm repo add sonatype https://sonatype.github.io/helm3-charts/
helm repo update

# Create namespace
kubectl create namespace nexus

# Create PVC for data
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nexus-data
  namespace: nexus
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  storageClassName: standard
EOF

# Install Nexus
helm install nexus sonatype/nexus-repository-manager \
  --namespace nexus \
  --values values.yaml
```

### Helm Values

```yaml
# values.yaml
replicaCount: 1

image:
  repository: sonatype/nexus3
  tag: 3.66.0

nexus:
  docker:
    enabled: true
    registries:
      - host: docker.nexus
        port: 5000
        secretName: docker-registry-secret
  env:
    - name: INSTALL4J_ADD_VM_PARAMS
      value: "-Xms4g -Xmx4g -XX:MaxDirectMemorySize=4g"

resources:
  requests:
    cpu: 1000m
    memory: 4Gi
  limits:
    cpu: 4000m
    memory: 8Gi

persistence:
  enabled: true
  storageClass: standard
  accessMode: ReadWriteOnce
  size: 100Gi

ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hostPath: /
  hostRepo: nexus.company.com
  tls:
    - secretName: nexus-tls
      hosts:
        - nexus.company.com
        - docker.company.com

service:
  type: ClusterIP
  port: 8081
```

## Client Configuration

### Maven Configuration

```xml
<!-- ~/.m2/settings.xml -->
<settings>
  <servers>
    <server>
      <id>nexus-releases</id>
      <username>${env.NEXUS_USERNAME}</username>
      <password>${env.NEXUS_PASSWORD}</password>
    </server>
    <server>
      <id>nexus-snapshots</id>
      <username>${env.NEXUS_USERNAME}</username>
      <password>${env.NEXUS_PASSWORD}</password>
    </server>
  </servers>

  <mirrors>
    <mirror>
      <id>nexus</id>
      <mirrorOf>*</mirrorOf>
      <url>https://nexus.company.com/repository/maven-public/</url>
    </mirror>
  </mirrors>

  <profiles>
    <profile>
      <id>nexus</id>
      <repositories>
        <repository>
          <id>central</id>
          <url>https://nexus.company.com/repository/maven-public/</url>
          <releases><enabled>true</enabled></releases>
          <snapshots><enabled>true</enabled></snapshots>
        </repository>
      </repositories>
      <pluginRepositories>
        <pluginRepository>
          <id>central</id>
          <url>https://nexus.company.com/repository/maven-public/</url>
          <releases><enabled>true</enabled></releases>
          <snapshots><enabled>true</enabled></snapshots>
        </pluginRepository>
      </pluginRepositories>
    </profile>
  </profiles>

  <activeProfiles>
    <activeProfile>nexus</activeProfile>
  </activeProfiles>
</settings>
```

```xml
<!-- pom.xml distribution management -->
<distributionManagement>
  <repository>
    <id>nexus-releases</id>
    <url>https://nexus.company.com/repository/maven-releases/</url>
  </repository>
  <snapshotRepository>
    <id>nexus-snapshots</id>
    <url>https://nexus.company.com/repository/maven-snapshots/</url>
  </snapshotRepository>
</distributionManagement>
```

### npm Configuration

```ini
# ~/.npmrc
registry=https://nexus.company.com/repository/npm-group/
_auth=<base64-encoded-username:password>
email=dev@company.com
always-auth=true

# For publishing to hosted repository
//nexus.company.com/repository/npm-private/:_auth=<base64-encoded-creds>
```

```json
// package.json
{
  "name": "@company/my-package",
  "version": "1.0.0",
  "publishConfig": {
    "registry": "https://nexus.company.com/repository/npm-private/"
  }
}
```

```bash
# Generate base64 auth
echo -n 'username:password' | base64

# Login to npm registry
npm login --registry=https://nexus.company.com/repository/npm-private/

# Publish package
npm publish --registry=https://nexus.company.com/repository/npm-private/
```

### Docker Configuration

```bash
# Login to Docker registry
docker login docker.company.com -u admin -p password

# Pull image through proxy
docker pull docker.company.com/nginx:latest

# Tag and push to hosted registry
docker tag myapp:latest docker.company.com/myapp:1.0.0
docker push docker.company.com/myapp:1.0.0
```

```json
// ~/.docker/config.json
{
  "auths": {
    "docker.company.com": {
      "auth": "<base64-encoded-username:password>"
    }
  }
}
```

### Python/PyPI Configuration

```ini
# ~/.pypirc
[distutils]
index-servers =
    nexus

[nexus]
repository = https://nexus.company.com/repository/pypi-hosted/
username = admin
password = password
```

```ini
# pip.conf
[global]
index-url = https://nexus.company.com/repository/pypi-group/simple/
trusted-host = nexus.company.com
```

```bash
# Install from Nexus
pip install --index-url https://nexus.company.com/repository/pypi-group/simple/ package-name

# Upload to Nexus
twine upload --repository nexus dist/*
```

### Helm Configuration

```bash
# Add Nexus as Helm repository
helm repo add nexus https://nexus.company.com/repository/helm-hosted/ \
  --username admin --password password

# Push chart to Nexus
curl -u admin:password \
  https://nexus.company.com/repository/helm-hosted/ \
  --upload-file mychart-1.0.0.tgz

# Install from Nexus
helm install myrelease nexus/mychart
```

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/publish.yaml
name: Build and Publish

on:
  push:
    branches: [main]
  release:
    types: [published]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
          cache: maven
          server-id: nexus-releases
          server-username: MAVEN_USERNAME
          server-password: MAVEN_PASSWORD

      - name: Build and Publish Maven
        run: mvn deploy -DskipTests
        env:
          MAVEN_USERNAME: ${{ secrets.NEXUS_USERNAME }}
          MAVEN_PASSWORD: ${{ secrets.NEXUS_PASSWORD }}

      - name: Build and Push Docker
        run: |
          docker login docker.company.com -u ${{ secrets.NEXUS_USERNAME }} -p ${{ secrets.NEXUS_PASSWORD }}
          docker build -t docker.company.com/myapp:${{ github.sha }} .
          docker push docker.company.com/myapp:${{ github.sha }}

  publish-npm:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          registry-url: 'https://nexus.company.com/repository/npm-private/'

      - name: Install and Build
        run: npm ci && npm run build

      - name: Publish
        run: npm publish
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - build
  - publish

variables:
  MAVEN_OPTS: "-Dmaven.repo.local=$CI_PROJECT_DIR/.m2/repository"

build:
  stage: build
  image: maven:3.9-eclipse-temurin-17
  script:
    - mvn clean package -DskipTests
  artifacts:
    paths:
      - target/*.jar

publish-maven:
  stage: publish
  image: maven:3.9-eclipse-temurin-17
  script:
    - |
      cat > ~/.m2/settings.xml << EOF
      <settings>
        <servers>
          <server>
            <id>nexus</id>
            <username>${NEXUS_USERNAME}</username>
            <password>${NEXUS_PASSWORD}</password>
          </server>
        </servers>
      </settings>
      EOF
    - mvn deploy -DskipTests
  only:
    - main
    - tags

publish-docker:
  stage: publish
  image: docker:24
  services:
    - docker:24-dind
  script:
    - docker login docker.company.com -u $NEXUS_USERNAME -p $NEXUS_PASSWORD
    - docker build -t docker.company.com/$CI_PROJECT_NAME:$CI_COMMIT_SHA .
    - docker push docker.company.com/$CI_PROJECT_NAME:$CI_COMMIT_SHA
  only:
    - main
```

### Jenkins Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any
    
    environment {
        NEXUS_URL = 'https://nexus.company.com'
        NEXUS_CREDENTIALS = credentials('nexus-credentials')
    }
    
    stages {
        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }
        
        stage('Publish Maven') {
            steps {
                configFileProvider([configFile(fileId: 'maven-settings', variable: 'MAVEN_SETTINGS')]) {
                    sh 'mvn deploy -s $MAVEN_SETTINGS -DskipTests'
                }
            }
        }
        
        stage('Publish Docker') {
            steps {
                script {
                    docker.withRegistry('https://docker.company.com', 'nexus-credentials') {
                        def image = docker.build("myapp:${BUILD_NUMBER}")
                        image.push()
                        image.push('latest')
                    }
                }
            }
        }
        
        stage('Publish npm') {
            steps {
                nodejs('nodejs-20') {
                    sh '''
                        npm config set registry ${NEXUS_URL}/repository/npm-private/
                        npm config set _auth $(echo -n "${NEXUS_CREDENTIALS}" | base64)
                        npm publish
                    '''
                }
            }
        }
    }
}
```

## API Examples

### Search and Download

```bash
# Search for components
curl -u admin:admin123 \
  "http://localhost:8081/service/rest/v1/search?repository=maven-releases&maven.groupId=com.company"

# Download artifact
curl -u admin:admin123 -O \
  "http://localhost:8081/repository/maven-releases/com/company/myapp/1.0.0/myapp-1.0.0.jar"

# Upload raw artifact
curl -u admin:admin123 \
  --upload-file myfile.zip \
  "http://localhost:8081/repository/raw-hosted/path/to/myfile.zip"

# Upload Maven artifact
curl -u admin:admin123 \
  --upload-file myapp-1.0.0.jar \
  "http://localhost:8081/repository/maven-releases/com/company/myapp/1.0.0/myapp-1.0.0.jar"
```

### Component Management

```bash
# List components
curl -u admin:admin123 \
  "http://localhost:8081/service/rest/v1/components?repository=maven-releases"

# Delete component
curl -u admin:admin123 -X DELETE \
  "http://localhost:8081/service/rest/v1/components/{componentId}"

# Get component by ID
curl -u admin:admin123 \
  "http://localhost:8081/service/rest/v1/components/{componentId}"
```

### Repository Management

```bash
# List repositories
curl -u admin:admin123 \
  "http://localhost:8081/service/rest/v1/repositories"

# Get repository details
curl -u admin:admin123 \
  "http://localhost:8081/service/rest/v1/repositories/maven-releases"

# Rebuild index
curl -u admin:admin123 -X POST \
  "http://localhost:8081/service/rest/v1/repositories/maven-releases/rebuild-index"
```

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| 401 Unauthorized | Invalid credentials | Check username/password, token |
| 403 Forbidden | Missing permissions | Add required privileges to role |
| 404 Not Found | Artifact doesn't exist | Check path, repository name |
| 413 Entity Too Large | Upload size exceeded | Increase client_max_body_size |
| 500 Internal Error | Server issue | Check logs, disk space |
| Slow proxy downloads | Remote slow/unavailable | Check proxy settings, timeout |
| Storage full | Blob store at capacity | Run cleanup, expand storage |
| Database corruption | Improper shutdown | Restore from backup |

### Log Analysis

```bash
# View Nexus logs
docker logs nexus

# View request log
docker exec nexus tail -f /nexus-data/log/request.log

# View task log
docker exec nexus tail -f /nexus-data/log/tasks/

# Check disk usage
docker exec nexus du -sh /nexus-data/*
```

### Backup and Restore

```bash
# Stop Nexus
docker stop nexus

# Backup data directory
tar -czvf nexus-backup-$(date +%Y%m%d).tar.gz /nexus-data

# Restore
tar -xzvf nexus-backup.tar.gz -C /

# Restart Nexus
docker start nexus
```

## Best Practices

1. **Use proxy repositories** - Cache external dependencies for faster builds
2. **Separate blob stores** - Different stores for different artifact types
3. **Implement cleanup policies** - Prevent storage bloat
4. **Enable authentication** - Secure all repository access
5. **Use HTTPS** - Encrypt all traffic
6. **Regular backups** - Automate database and blob backups
7. **Monitor storage** - Alert before capacity issues
8. **Use repository groups** - Simplify client configuration
9. **Version artifacts properly** - Follow semantic versioning
10. **Audit access** - Review who uploads/downloads what
