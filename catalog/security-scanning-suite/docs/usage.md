# Usage Guide

## Docker Compose Deployment

### Security Scanner Stack

```yaml
# docker-compose.yaml
version: '3.8'

services:
  trivy:
    image: aquasec/trivy:0.49.0
    container_name: trivy
    command: server --listen 0.0.0.0:4954
    volumes:
      - trivy-cache:/root/.cache/
      - /var/run/docker.sock:/var/run/docker.sock:ro
    ports:
      - "4954:4954"
    environment:
      TRIVY_CACHE_DIR: /root/.cache/trivy
      TRIVY_DEBUG: "false"
    networks:
      - security-net

  grype:
    image: anchore/grype:v0.74.0
    container_name: grype
    entrypoint: ["/bin/sh", "-c"]
    command: ["while true; do sleep 3600; done"]
    volumes:
      - grype-db:/root/.grype/
      - ./scan-targets:/scan-targets:ro
    networks:
      - security-net

  zap:
    image: zaproxy/zap-stable:2.14.0
    container_name: zap
    command: zap.sh -daemon -host 0.0.0.0 -port 8080 -config api.addrs.addr.name=.* -config api.addrs.addr.regex=true -config api.key=zap-api-key
    ports:
      - "8080:8080"
    volumes:
      - zap-data:/zap/wrk
    networks:
      - security-net

  defectdojo:
    image: defectdojo/defectdojo-django:2.31.0
    container_name: defectdojo
    depends_on:
      - defectdojo-db
    environment:
      DD_DATABASE_URL: postgres://defectdojo:defectdojo@defectdojo-db:5432/defectdojo
      DD_SECRET_KEY: your-secret-key-here
      DD_CREDENTIAL_AES_256_KEY: your-aes-key-here
    ports:
      - "8000:8080"
    networks:
      - security-net

  defectdojo-db:
    image: postgres:16-alpine
    container_name: defectdojo-db
    environment:
      POSTGRES_DB: defectdojo
      POSTGRES_USER: defectdojo
      POSTGRES_PASSWORD: defectdojo
    volumes:
      - defectdojo-db-data:/var/lib/postgresql/data
    networks:
      - security-net

volumes:
  trivy-cache:
  grype-db:
  zap-data:
  defectdojo-db-data:

networks:
  security-net:
    driver: bridge
```

### Running Scans with Docker

```bash
# Trivy container image scan
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:0.49.0 image nginx:latest

# Trivy filesystem scan
docker run --rm -v $(pwd):/app aquasec/trivy:0.49.0 fs /app

# Grype container scan
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  anchore/grype:v0.74.0 docker:nginx:latest

# Semgrep scan
docker run --rm -v $(pwd):/src returntocorp/semgrep:latest \
  semgrep scan --config auto /src

# Gitleaks scan
docker run --rm -v $(pwd):/repo zricethezav/gitleaks:v8.18.0 \
  detect --source /repo --verbose
```

## Kubernetes Deployment

### Trivy Operator

```bash
# Install Trivy Operator
helm repo add aquasecurity https://aquasecurity.github.io/helm-charts/
helm repo update

kubectl create namespace trivy-system

helm install trivy-operator aquasecurity/trivy-operator \
  --namespace trivy-system \
  --set trivy.ignoreUnfixed=true \
  --set operator.scanJobsConcurrentLimit=5
```

```yaml
# trivy-operator-values.yaml
trivy:
  ignoreUnfixed: true
  severity: CRITICAL,HIGH,MEDIUM
  timeout: 10m0s
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 1Gi

operator:
  scanJobsConcurrentLimit: 5
  scanJobsRetryDelay: 30s
  vulnerabilityScannerEnabled: true
  configAuditScannerEnabled: true
  exposedSecretScannerEnabled: true
  rbacAssessmentScannerEnabled: true

serviceMonitor:
  enabled: true
```

### Security Scanning CronJob

```yaml
# security-scan-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: security-scanner
  namespace: security
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: trivy
              image: aquasec/trivy:0.49.0
              command:
                - /bin/sh
                - -c
                - |
                  trivy image --format json --output /results/trivy.json \
                    $(kubectl get pods -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n' | sort -u)
              volumeMounts:
                - name: results
                  mountPath: /results
            - name: grype
              image: anchore/grype:v0.74.0
              command:
                - /bin/sh
                - -c
                - |
                  for img in $(kubectl get pods -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n' | sort -u); do
                    grype $img -o json >> /results/grype.json
                  done
              volumeMounts:
                - name: results
                  mountPath: /results
          volumes:
            - name: results
              persistentVolumeClaim:
                claimName: scan-results
          restartPolicy: OnFailure
```

## CI/CD Integration Examples

### GitHub Actions - Complete Security Pipeline

```yaml
# .github/workflows/security.yaml
name: Security Scanning

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 2 * * *'

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  secret-scanning:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Gitleaks Scan
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  sast:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Semgrep Scan
        uses: returntocorp/semgrep-action@v1
        with:
          config: >-
            p/security-audit
            p/secrets
            p/owasp-top-ten
          generateSarif: true

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: semgrep.sarif

  dependency-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Trivy FS Scan
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-fs.sarif'
          severity: 'CRITICAL,HIGH'

      - name: Upload Trivy SARIF
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: trivy-fs.sarif

  iac-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Checkov Scan
        uses: bridgecrewio/checkov-action@v12
        with:
          directory: terraform/
          framework: terraform
          output_format: sarif
          output_file_path: checkov.sarif

      - name: tfsec Scan
        uses: aquasecurity/tfsec-sarif-action@v0.1.4
        with:
          sarif_file: tfsec.sarif

  container-scan:
    runs-on: ubuntu-latest
    needs: [sast, dependency-scan]
    steps:
      - uses: actions/checkout@v4

      - name: Build Image
        run: docker build -t ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }} .

      - name: Trivy Image Scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: '${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}'
          format: 'sarif'
          output: 'trivy-image.sarif'
          severity: 'CRITICAL,HIGH'
          exit-code: '1'

      - name: Grype Scan
        uses: anchore/scan-action@v3
        with:
          image: '${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}'
          fail-build: true
          severity-cutoff: high
          output-format: sarif

      - name: Generate SBOM
        uses: anchore/sbom-action@v0
        with:
          image: '${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}'
          format: spdx-json
          output-file: sbom.spdx.json

  dast:
    runs-on: ubuntu-latest
    needs: [container-scan]
    if: github.event_name == 'schedule' || github.ref == 'refs/heads/main'
    steps:
      - name: ZAP Baseline Scan
        uses: zaproxy/action-baseline@v0.10.0
        with:
          target: 'https://staging.example.com'
          rules_file_name: '.zap/rules.tsv'
          cmd_options: '-a'

      - name: Nuclei Scan
        uses: projectdiscovery/nuclei-action@main
        with:
          target: https://staging.example.com
          templates: cves/,vulnerabilities/
          output: nuclei-results.txt

  upload-results:
    runs-on: ubuntu-latest
    needs: [secret-scanning, sast, dependency-scan, iac-scan, container-scan]
    steps:
      - name: Upload to DefectDojo
        run: |
          curl -X POST "${{ secrets.DEFECTDOJO_URL }}/api/v2/import-scan/" \
            -H "Authorization: Token ${{ secrets.DEFECTDOJO_TOKEN }}" \
            -F "scan_type=SARIF" \
            -F "file=@semgrep.sarif" \
            -F "engagement=${{ secrets.DEFECTDOJO_ENGAGEMENT }}" \
            -F "verified=true" \
            -F "active=true"
```

### GitLab CI Security Pipeline

```yaml
# .gitlab-ci.yml
stages:
  - secrets
  - sast
  - dependencies
  - build
  - container-scan
  - dast
  - report

variables:
  TRIVY_CACHE_DIR: .trivycache/
  SECURE_LOG_LEVEL: debug

include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml
  - template: Security/Container-Scanning.gitlab-ci.yml

gitleaks:
  stage: secrets
  image: zricethezav/gitleaks:v8.18.0
  script:
    - gitleaks detect --source . --verbose --report-format sarif --report-path gitleaks.sarif
  artifacts:
    reports:
      sast: gitleaks.sarif
  allow_failure: false

semgrep:
  stage: sast
  image: returntocorp/semgrep:latest
  script:
    - semgrep scan --config auto --sarif --output semgrep.sarif .
  artifacts:
    reports:
      sast: semgrep.sarif

trivy-fs:
  stage: dependencies
  image: aquasec/trivy:0.49.0
  script:
    - trivy fs --format sarif --output trivy-fs.sarif .
  artifacts:
    reports:
      dependency_scanning: trivy-fs.sarif
  cache:
    paths:
      - .trivycache/

checkov:
  stage: sast
  image: bridgecrew/checkov:latest
  script:
    - checkov -d terraform/ -o sarif --output-file checkov.sarif
  artifacts:
    reports:
      sast: checkov.sarif

build-image:
  stage: build
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA

trivy-image:
  stage: container-scan
  image: aquasec/trivy:0.49.0
  needs:
    - build-image
  script:
    - trivy image --format sarif --output trivy-image.sarif $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  artifacts:
    reports:
      container_scanning: trivy-image.sarif

grype-scan:
  stage: container-scan
  image: anchore/grype:v0.74.0
  needs:
    - build-image
  script:
    - grype $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA -o sarif > grype.sarif
  artifacts:
    reports:
      container_scanning: grype.sarif

zap-dast:
  stage: dast
  image: zaproxy/zap-stable:2.14.0
  script:
    - zap-baseline.py -t $STAGING_URL -r zap-report.html -w zap-report.md
  artifacts:
    paths:
      - zap-report.html
      - zap-report.md
  only:
    - main
```

### Jenkins Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any
    
    environment {
        REGISTRY = 'registry.example.com'
        IMAGE_NAME = 'myapp'
        TRIVY_CACHE = '/var/jenkins_home/trivy-cache'
    }
    
    stages {
        stage('Secret Scanning') {
            steps {
                sh 'gitleaks detect --source . --verbose --report-format json --report-path gitleaks.json'
            }
            post {
                always {
                    archiveArtifacts artifacts: 'gitleaks.json', fingerprint: true
                }
            }
        }
        
        stage('SAST') {
            parallel {
                stage('Semgrep') {
                    steps {
                        sh 'semgrep scan --config auto --sarif --output semgrep.sarif .'
                    }
                }
                stage('Checkov') {
                    steps {
                        sh 'checkov -d terraform/ -o sarif --output-file checkov.sarif'
                    }
                }
            }
        }
        
        stage('Dependency Scan') {
            steps {
                sh '''
                    trivy fs --cache-dir ${TRIVY_CACHE} \
                        --format sarif --output trivy-fs.sarif .
                '''
            }
        }
        
        stage('Build') {
            steps {
                sh "docker build -t ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} ."
            }
        }
        
        stage('Container Scan') {
            parallel {
                stage('Trivy') {
                    steps {
                        sh '''
                            trivy image --cache-dir ${TRIVY_CACHE} \
                                --format sarif --output trivy-image.sarif \
                                --exit-code 1 --severity CRITICAL,HIGH \
                                ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}
                        '''
                    }
                }
                stage('Grype') {
                    steps {
                        sh '''
                            grype ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} \
                                -o sarif > grype.sarif
                        '''
                    }
                }
            }
        }
        
        stage('SBOM Generation') {
            steps {
                sh '''
                    syft packages ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} \
                        -o spdx-json > sbom.spdx.json
                '''
            }
        }
        
        stage('DAST') {
            when {
                branch 'main'
            }
            steps {
                sh '''
                    docker run --rm -v $(pwd):/zap/wrk:rw zaproxy/zap-stable:2.14.0 \
                        zap-baseline.py -t ${STAGING_URL} \
                        -r zap-report.html -w zap-report.md
                '''
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: '*.sarif,*.json,zap-report.*', fingerprint: true
            
            recordIssues(
                tools: [sarif(pattern: '*.sarif')],
                qualityGates: [[threshold: 1, type: 'TOTAL_HIGH', unstable: true]]
            )
        }
    }
}
```

## Scripted Scanning Examples

### Comprehensive Scan Script

```bash
#!/bin/bash
# security-scan.sh - Comprehensive security scanning script

set -e

# Configuration
TARGET_DIR="${1:-.}"
IMAGE="${2:-}"
OUTPUT_DIR="${3:-./security-reports}"
SEVERITY="CRITICAL,HIGH,MEDIUM"

mkdir -p "$OUTPUT_DIR"

echo "=== Security Scanning Suite ==="
echo "Target Directory: $TARGET_DIR"
echo "Target Image: $IMAGE"
echo "Output Directory: $OUTPUT_DIR"
echo ""

# Secret scanning
echo ">>> Running Gitleaks..."
gitleaks detect --source "$TARGET_DIR" \
    --report-format sarif \
    --report-path "$OUTPUT_DIR/gitleaks.sarif" || true

# SAST with Semgrep
echo ">>> Running Semgrep..."
semgrep scan --config auto \
    --sarif --output "$OUTPUT_DIR/semgrep.sarif" \
    "$TARGET_DIR" || true

# Dependency scanning
echo ">>> Running Trivy FS scan..."
trivy fs --format sarif \
    --output "$OUTPUT_DIR/trivy-fs.sarif" \
    --severity "$SEVERITY" \
    "$TARGET_DIR" || true

# IaC scanning
if [ -d "$TARGET_DIR/terraform" ]; then
    echo ">>> Running Checkov..."
    checkov -d "$TARGET_DIR/terraform" \
        -o sarif \
        --output-file "$OUTPUT_DIR/checkov.sarif" || true
fi

# Container scanning
if [ -n "$IMAGE" ]; then
    echo ">>> Running Trivy image scan..."
    trivy image --format sarif \
        --output "$OUTPUT_DIR/trivy-image.sarif" \
        --severity "$SEVERITY" \
        "$IMAGE" || true
    
    echo ">>> Running Grype scan..."
    grype "$IMAGE" \
        -o sarif > "$OUTPUT_DIR/grype.sarif" || true
    
    echo ">>> Generating SBOM..."
    syft packages "$IMAGE" \
        -o spdx-json > "$OUTPUT_DIR/sbom.spdx.json" || true
fi

# Generate summary report
echo ">>> Generating summary..."
python3 << 'EOF'
import json
import os
from pathlib import Path

output_dir = os.environ.get('OUTPUT_DIR', './security-reports')
summary = {"total": 0, "critical": 0, "high": 0, "medium": 0, "low": 0}

for sarif_file in Path(output_dir).glob('*.sarif'):
    with open(sarif_file) as f:
        data = json.load(f)
        for run in data.get('runs', []):
            for result in run.get('results', []):
                summary['total'] += 1
                level = result.get('level', 'note')
                if level == 'error':
                    summary['critical'] += 1
                elif level == 'warning':
                    summary['high'] += 1
                else:
                    summary['medium'] += 1

print(f"\n=== Security Scan Summary ===")
print(f"Total Issues: {summary['total']}")
print(f"Critical: {summary['critical']}")
print(f"High: {summary['high']}")
print(f"Medium: {summary['medium']}")
print(f"Low: {summary['low']}")

with open(f"{output_dir}/summary.json", 'w') as f:
    json.dump(summary, f, indent=2)
EOF

echo ""
echo "=== Scan Complete ==="
echo "Reports saved to: $OUTPUT_DIR"
```

### Python Integration

```python
# security_scanner.py
import subprocess
import json
from pathlib import Path
from dataclasses import dataclass
from typing import List, Optional

@dataclass
class Finding:
    tool: str
    severity: str
    title: str
    description: str
    file: Optional[str] = None
    line: Optional[int] = None

class SecurityScanner:
    def __init__(self, output_dir: str = "./security-reports"):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.findings: List[Finding] = []
    
    def run_trivy(self, target: str, scan_type: str = "fs") -> List[Finding]:
        """Run Trivy vulnerability scanner."""
        output_file = self.output_dir / f"trivy-{scan_type}.json"
        
        cmd = [
            "trivy", scan_type,
            "--format", "json",
            "--output", str(output_file),
            "--severity", "CRITICAL,HIGH,MEDIUM",
            target
        ]
        
        subprocess.run(cmd, capture_output=True)
        
        findings = []
        if output_file.exists():
            with open(output_file) as f:
                data = json.load(f)
                for result in data.get("Results", []):
                    for vuln in result.get("Vulnerabilities", []):
                        findings.append(Finding(
                            tool="trivy",
                            severity=vuln.get("Severity", "UNKNOWN"),
                            title=vuln.get("VulnerabilityID", ""),
                            description=vuln.get("Title", ""),
                            file=result.get("Target")
                        ))
        
        self.findings.extend(findings)
        return findings
    
    def run_semgrep(self, target: str) -> List[Finding]:
        """Run Semgrep SAST scanner."""
        output_file = self.output_dir / "semgrep.json"
        
        cmd = [
            "semgrep", "scan",
            "--config", "auto",
            "--json", "--output", str(output_file),
            target
        ]
        
        subprocess.run(cmd, capture_output=True)
        
        findings = []
        if output_file.exists():
            with open(output_file) as f:
                data = json.load(f)
                for result in data.get("results", []):
                    findings.append(Finding(
                        tool="semgrep",
                        severity=result.get("extra", {}).get("severity", "INFO"),
                        title=result.get("check_id", ""),
                        description=result.get("extra", {}).get("message", ""),
                        file=result.get("path"),
                        line=result.get("start", {}).get("line")
                    ))
        
        self.findings.extend(findings)
        return findings
    
    def run_gitleaks(self, target: str) -> List[Finding]:
        """Run Gitleaks secret scanner."""
        output_file = self.output_dir / "gitleaks.json"
        
        cmd = [
            "gitleaks", "detect",
            "--source", target,
            "--report-format", "json",
            "--report-path", str(output_file)
        ]
        
        subprocess.run(cmd, capture_output=True)
        
        findings = []
        if output_file.exists():
            with open(output_file) as f:
                data = json.load(f)
                for leak in data:
                    findings.append(Finding(
                        tool="gitleaks",
                        severity="HIGH",
                        title=leak.get("RuleID", ""),
                        description=f"Secret detected: {leak.get('Description', '')}",
                        file=leak.get("File"),
                        line=leak.get("StartLine")
                    ))
        
        self.findings.extend(findings)
        return findings
    
    def get_summary(self) -> dict:
        """Get summary of all findings."""
        summary = {
            "total": len(self.findings),
            "by_severity": {},
            "by_tool": {}
        }
        
        for finding in self.findings:
            # Count by severity
            severity = finding.severity.upper()
            summary["by_severity"][severity] = summary["by_severity"].get(severity, 0) + 1
            
            # Count by tool
            summary["by_tool"][finding.tool] = summary["by_tool"].get(finding.tool, 0) + 1
        
        return summary


# Usage example
if __name__ == "__main__":
    scanner = SecurityScanner()
    
    # Run all scans
    scanner.run_trivy(".", "fs")
    scanner.run_semgrep(".")
    scanner.run_gitleaks(".")
    
    # Print summary
    summary = scanner.get_summary()
    print(json.dumps(summary, indent=2))
```

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Trivy DB download fails | Network/proxy issues | Set `TRIVY_DB_REPOSITORY` or use offline mode |
| Semgrep memory issues | Large codebase | Use `--max-target-bytes` or exclude large files |
| ZAP scan timeout | Slow target | Increase timeout, reduce spider depth |
| Grype DB update fails | Rate limiting | Use local DB cache, schedule updates |
| Container scan permission denied | Docker socket access | Add user to docker group |
| SARIF upload fails | Invalid format | Validate SARIF with schema validator |
| False positives | Overly broad rules | Tune rules, add exceptions |
| Scanner conflicts | Overlapping detections | Use single scanner per category |

### Debug Commands

```bash
# Trivy debug mode
trivy image --debug nginx:latest

# Semgrep verbose output
semgrep scan --verbose --config auto .

# Grype with trace logging
GRYPE_LOG_LEVEL=trace grype nginx:latest

# ZAP debug mode
zap.sh -daemon -config api.disablekey=true -debug
```

## Best Practices

1. **Shift Left** - Run scans as early as possible in the pipeline
2. **Fail Fast** - Block builds on critical/high vulnerabilities
3. **Tune Rules** - Reduce false positives through customization
4. **Aggregate Results** - Use DefectDojo or similar for centralized view
5. **Track Metrics** - Monitor MTTR and vulnerability trends
6. **Automate Everything** - No manual intervention in CI/CD
7. **Keep Updated** - Regularly update scanner databases
8. **Document Exceptions** - Maintain audit trail for suppressed findings
