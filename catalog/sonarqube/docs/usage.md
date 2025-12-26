# Usage Guide

## Docker Compose Deployment

### Development Setup

```yaml
# docker-compose.yaml
version: '3.8'

services:
  sonarqube:
    image: sonarqube:10.4-community
    container_name: sonarqube
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://postgres:5432/sonarqube
      SONAR_JDBC_USERNAME: sonarqube
      SONAR_JDBC_PASSWORD: sonarqube_password
      SONAR_ES_BOOTSTRAP_CHECKS_DISABLE: 'true'
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_logs:/opt/sonarqube/logs
      - sonarqube_extensions:/opt/sonarqube/extensions
    ports:
      - '9000:9000'
    networks:
      - sonarnet
    ulimits:
      nofile:
        soft: 65536
        hard: 65536
    healthcheck:
      test: ['CMD', 'curl', '-f', 'http://localhost:9000/api/system/health']
      interval: 30s
      timeout: 10s
      retries: 5

  postgres:
    image: postgres:16-alpine
    container_name: sonarqube-postgres
    environment:
      POSTGRES_DB: sonarqube
      POSTGRES_USER: sonarqube
      POSTGRES_PASSWORD: sonarqube_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - sonarnet
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U sonarqube']
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  sonarqube_data:
  sonarqube_logs:
  sonarqube_extensions:
  postgres_data:

networks:
  sonarnet:
    driver: bridge
```

### Production Setup with HTTPS

```yaml
# docker-compose.prod.yaml
version: '3.8'

services:
  sonarqube:
    image: sonarqube:10.4-enterprise
    container_name: sonarqube
    depends_on:
      - postgres
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://postgres:5432/sonarqube
      SONAR_JDBC_USERNAME: ${SONAR_DB_USER}
      SONAR_JDBC_PASSWORD: ${SONAR_DB_PASSWORD}
      SONAR_WEB_CONTEXT: /sonarqube
      SONAR_WEB_JAVAADDITIONALOPTS: -Xmx2g
      SONAR_CE_JAVAADDITIONALOPTS: -Xmx2g
      SONAR_SEARCH_JAVAADDITIONALOPTS: -Xmx1g
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_logs:/opt/sonarqube/logs
      - sonarqube_extensions:/opt/sonarqube/extensions
      - ./sonar.properties:/opt/sonarqube/conf/sonar.properties:ro
    expose:
      - '9000'
    networks:
      - sonarnet
    deploy:
      resources:
        limits:
          memory: 6G
        reservations:
          memory: 4G
    ulimits:
      nofile:
        soft: 131072
        hard: 131072

  nginx:
    image: nginx:alpine
    container_name: sonarqube-nginx
    ports:
      - '443:443'
      - '80:80'
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certs:/etc/nginx/certs:ro
    depends_on:
      - sonarqube
    networks:
      - sonarnet
```

## Kubernetes Deployment

### Helm Installation

```bash
# Add SonarQube Helm repository
helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
helm repo update

# Create namespace
kubectl create namespace sonarqube

# Create secrets
kubectl create secret generic sonarqube-db \
  --namespace sonarqube \
  --from-literal=password=sonarqube_password

kubectl create secret generic sonarqube-admin \
  --namespace sonarqube \
  --from-literal=password=admin_password

# Install SonarQube
helm install sonarqube sonarqube/sonarqube \
  --namespace sonarqube \
  --values values.yaml
```

### Helm Values (values.yaml)

```yaml
# values.yaml
replicaCount: 1

image:
  repository: sonarqube
  tag: 10.4-community
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 9000

ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-body-size: '64m'
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - name: sonarqube.example.com
      path: /
  tls:
    - secretName: sonarqube-tls
      hosts:
        - sonarqube.example.com

resources:
  requests:
    cpu: 500m
    memory: 2Gi
  limits:
    cpu: 2000m
    memory: 4Gi

persistence:
  enabled: true
  storageClass: standard
  size: 20Gi

postgresql:
  enabled: true
  postgresqlUsername: sonarqube
  postgresqlPassword: sonarqube_password
  postgresqlDatabase: sonarqube
  persistence:
    enabled: true
    size: 20Gi

plugins:
  install:
    - https://github.com/dependency-check/dependency-check-sonar-plugin/releases/download/4.0.1/sonar-dependency-check-plugin-4.0.1.jar

sonarProperties:
  sonar.forceAuthentication: 'true'
  sonar.core.serverBaseURL: 'https://sonarqube.example.com'

jvmOpts: '-Xmx2g -Xms2g'
jvmCeOpts: '-Xmx2g -Xms2g'

monitoringPasscode: 'monitoring-secret'
```

### Native Kubernetes Manifests

```yaml
# sonarqube-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sonarqube
  namespace: sonarqube
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sonarqube
  template:
    metadata:
      labels:
        app: sonarqube
    spec:
      securityContext:
        fsGroup: 1000
      initContainers:
        - name: sysctl
          image: busybox
          command:
            - sh
            - -c
            - |
              sysctl -w vm.max_map_count=524288
              sysctl -w fs.file-max=131072
          securityContext:
            privileged: true
      containers:
        - name: sonarqube
          image: sonarqube:10.4-community
          ports:
            - containerPort: 9000
          env:
            - name: SONAR_JDBC_URL
              value: jdbc:postgresql://postgres:5432/sonarqube
            - name: SONAR_JDBC_USERNAME
              valueFrom:
                secretKeyRef:
                  name: sonarqube-db
                  key: username
            - name: SONAR_JDBC_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: sonarqube-db
                  key: password
          resources:
            requests:
              cpu: 500m
              memory: 2Gi
            limits:
              cpu: 2000m
              memory: 4Gi
          volumeMounts:
            - name: data
              mountPath: /opt/sonarqube/data
            - name: extensions
              mountPath: /opt/sonarqube/extensions
          livenessProbe:
            httpGet:
              path: /api/system/health
              port: 9000
            initialDelaySeconds: 120
            periodSeconds: 30
          readinessProbe:
            httpGet:
              path: /api/system/status
              port: 9000
            initialDelaySeconds: 60
            periodSeconds: 10
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: sonarqube-data
        - name: extensions
          persistentVolumeClaim:
            claimName: sonarqube-extensions
```

## CI/CD Integration Examples

### GitHub Actions

```yaml
# .github/workflows/sonarqube.yaml
name: SonarQube Analysis

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  sonarqube:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
          cache: 'maven'

      - name: Build and Test
        run: mvn clean verify -Pcoverage

      - name: SonarQube Scan
        uses: sonarsource/sonarqube-scan-action@master
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
        with:
          args: >
            -Dsonar.projectKey=my-project
            -Dsonar.sources=src/main
            -Dsonar.tests=src/test
            -Dsonar.java.binaries=target/classes
            -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml

      - name: SonarQube Quality Gate
        uses: sonarsource/sonarqube-quality-gate-action@master
        timeout-minutes: 5
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - analyze

variables:
  SONAR_USER_HOME: '${CI_PROJECT_DIR}/.sonar'
  GIT_DEPTH: 0

sonarqube-check:
  stage: analyze
  image: maven:3.9-eclipse-temurin-17
  cache:
    key: '${CI_JOB_NAME}'
    paths:
      - .sonar/cache
      - .m2/repository
  script:
    - mvn verify sonar:sonar
      -Dsonar.projectKey=${CI_PROJECT_NAME}
      -Dsonar.host.url=${SONAR_HOST_URL}
      -Dsonar.token=${SONAR_TOKEN}
      -Dsonar.qualitygate.wait=true
  only:
    - merge_requests
    - main
    - develop
```

### Jenkins Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any

    environment {
        SONAR_TOKEN = credentials('sonarqube-token')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Test') {
            steps {
                sh 'mvn clean verify -Pcoverage'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        mvn sonar:sonar \
                            -Dsonar.projectKey=${JOB_NAME} \
                            -Dsonar.projectName="${JOB_NAME}" \
                            -Dsonar.branch.name=${BRANCH_NAME}
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }

    post {
        always {
            junit '**/target/surefire-reports/*.xml'
            jacoco execPattern: '**/target/jacoco.exec'
        }
    }
}
```

### Azure DevOps

```yaml
# azure-pipelines.yml
trigger:
  - main
  - develop

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: sonarqube-credentials

steps:
  - task: SonarQubePrepare@5
    inputs:
      SonarQube: 'SonarQube Connection'
      scannerMode: 'CLI'
      configMode: 'manual'
      cliProjectKey: 'my-project'
      cliProjectName: 'My Project'
      cliSources: 'src'
      extraProperties: |
        sonar.javascript.lcov.reportPaths=coverage/lcov.info
        sonar.testExecutionReportPaths=test-results/sonar-report.xml

  - script: npm ci && npm run test:coverage
    displayName: 'Install and Test'

  - task: SonarQubeAnalyze@5
    displayName: 'Run SonarQube Analysis'

  - task: SonarQubePublish@5
    inputs:
      pollingTimeoutSec: '300'
```

## Scanner Configuration by Language

### Java (Maven)

```xml
<!-- pom.xml -->
<properties>
    <sonar.projectKey>my-java-project</sonar.projectKey>
    <sonar.organization>my-org</sonar.organization>
    <sonar.host.url>http://localhost:9000</sonar.host.url>
    <sonar.coverage.jacoco.xmlReportPaths>
        ${project.build.directory}/site/jacoco/jacoco.xml
    </sonar.coverage.jacoco.xmlReportPaths>
</properties>

<build>
    <plugins>
        <plugin>
            <groupId>org.jacoco</groupId>
            <artifactId>jacoco-maven-plugin</artifactId>
            <version>0.8.11</version>
            <executions>
                <execution>
                    <goals>
                        <goal>prepare-agent</goal>
                    </goals>
                </execution>
                <execution>
                    <id>report</id>
                    <phase>test</phase>
                    <goals>
                        <goal>report</goal>
                    </goals>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

```bash
# Run analysis
mvn clean verify sonar:sonar \
  -Dsonar.token=your-token
```

### JavaScript/TypeScript

```javascript
// sonar-project.properties
sonar.projectKey=my-js-project
sonar.sources=src
sonar.tests=tests
sonar.exclusions=**/node_modules/**,**/dist/**
sonar.javascript.lcov.reportPaths=coverage/lcov.info
sonar.testExecutionReportPaths=coverage/test-report.xml
```

```json
// package.json
{
  "scripts": {
    "test:coverage": "jest --coverage --testResultsProcessor=jest-sonar-reporter",
    "sonar": "sonar-scanner"
  },
  "jestSonar": {
    "reportPath": "coverage",
    "reportFile": "test-report.xml"
  }
}
```

### Python

```ini
# sonar-project.properties
sonar.projectKey=my-python-project
sonar.sources=src
sonar.tests=tests
sonar.python.coverage.reportPaths=coverage.xml
sonar.python.xunit.reportPath=test-results.xml
```

```bash
# Run tests with coverage
pytest --cov=src --cov-report=xml:coverage.xml --junitxml=test-results.xml

# Run SonarQube analysis
sonar-scanner \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=your-token
```

### Go

```ini
# sonar-project.properties
sonar.projectKey=my-go-project
sonar.sources=.
sonar.exclusions=**/*_test.go,**/vendor/**
sonar.tests=.
sonar.test.inclusions=**/*_test.go
sonar.go.coverage.reportPaths=coverage.out
sonar.go.tests.reportPaths=report.json
```

```bash
# Run tests with coverage
go test -coverprofile=coverage.out -json ./... > report.json

# Run analysis
sonar-scanner -Dsonar.token=your-token
```

## API Examples

### Project Management

```bash
# Create project
curl -u admin:admin -X POST \
  "http://localhost:9000/api/projects/create" \
  -d "name=My+Project&project=my-project"

# Delete project
curl -u admin:admin -X POST \
  "http://localhost:9000/api/projects/delete" \
  -d "project=my-project"

# List projects
curl -u admin:admin \
  "http://localhost:9000/api/projects/search?ps=100"

# Get project status
curl -u admin:admin \
  "http://localhost:9000/api/qualitygates/project_status?projectKey=my-project"
```

### Quality Gate Management

```bash
# Create quality gate
curl -u admin:admin -X POST \
  "http://localhost:9000/api/qualitygates/create" \
  -d "name=My+Quality+Gate"

# Add condition
curl -u admin:admin -X POST \
  "http://localhost:9000/api/qualitygates/create_condition" \
  -d "gateName=My+Quality+Gate" \
  -d "metric=new_coverage" \
  -d "op=LT" \
  -d "error=80"

# Set as default
curl -u admin:admin -X POST \
  "http://localhost:9000/api/qualitygates/set_as_default" \
  -d "name=My+Quality+Gate"

# Associate with project
curl -u admin:admin -X POST \
  "http://localhost:9000/api/qualitygates/select" \
  -d "projectKey=my-project" \
  -d "gateName=My+Quality+Gate"
```

### Issues API

```bash
# Search issues
curl -u admin:admin \
  "http://localhost:9000/api/issues/search?componentKeys=my-project&severities=BLOCKER,CRITICAL&statuses=OPEN"

# Bulk change issues
curl -u admin:admin -X POST \
  "http://localhost:9000/api/issues/bulk_change" \
  -d "issues=issue1,issue2" \
  -d "do_transition=falsepositive" \
  -d "comment=Not+applicable"

# Add comment
curl -u admin:admin -X POST \
  "http://localhost:9000/api/issues/add_comment" \
  -d "issue=AXoKLm..." \
  -d "text=This+is+a+comment"
```

## Troubleshooting

| Issue                                 | Cause                     | Solution                                        |
| ------------------------------------- | ------------------------- | ----------------------------------------------- |
| Elasticsearch bootstrap checks failed | Low vm.max_map_count      | Run `sysctl -w vm.max_map_count=524288` on host |
| Analysis takes too long               | Large codebase or slow DB | Increase CE memory, optimize DB, use SSD        |
| Quality Gate timeout                  | Webhook not responding    | Check webhook URL, increase timeout             |
| Scanner can't connect                 | Network/firewall issue    | Verify URL, check proxy settings                |
| Out of memory during analysis         | Heap too small            | Increase `-Xmx` in scanner/CE settings          |
| Database connection errors            | Pool exhausted            | Increase `sonar.jdbc.maxActive`                 |
| Plugin installation fails             | Version incompatibility   | Check plugin compatibility matrix               |
| Branch analysis not working           | Community Edition         | Upgrade to Developer Edition                    |

### Log Analysis

```bash
# View web server logs
docker logs sonarqube 2>&1 | grep -E "(ERROR|WARN)"

# View compute engine logs
docker exec sonarqube tail -f /opt/sonarqube/logs/ce.log

# View Elasticsearch logs
docker exec sonarqube tail -f /opt/sonarqube/logs/es.log

# Check analysis report
cat .scannerwork/report-task.txt
```

### Performance Tuning

```properties
# Increase compute engine workers
sonar.ce.workerCount=4

# Optimize database pool
sonar.jdbc.maxActive=60
sonar.jdbc.maxIdle=5
sonar.jdbc.minIdle=2
sonar.jdbc.maxWait=5000

# Increase web server threads
sonar.web.http.maxThreads=50
sonar.web.http.minThreads=5
sonar.web.http.acceptCount=25

# Elasticsearch tuning
sonar.search.javaOpts=-Xmx2g -Xms2g -XX:MaxDirectMemorySize=256m
```

## Best Practices

### Code Quality Standards

1. **Set realistic quality gates** - Start with achievable thresholds
2. **Focus on new code** - Clean as you code approach
3. **Review security hotspots** - Don't ignore security warnings
4. **Track technical debt** - Plan debt reduction sprints
5. **Use quality profiles** - Customize rules per team/project

### CI/CD Integration

1. **Fail builds on quality gate failure** - Enforce standards
2. **Use branch analysis** - Catch issues before merge
3. **Enable PR decoration** - Show issues in pull requests
4. **Cache scanner data** - Speed up repeated analyses
5. **Set timeouts** - Prevent hung pipelines

### Operations

1. **Monitor disk usage** - Elasticsearch can grow large
2. **Regular backups** - Database and configuration
3. **Keep updated** - Security patches and new features
4. **Scale appropriately** - Right-size for your workload
5. **Use external database** - PostgreSQL for production
