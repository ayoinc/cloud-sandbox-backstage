# Overview

## Architecture Deep Dive

The Security Scanning Suite provides a comprehensive security testing framework that integrates multiple scanning tools across the software development lifecycle.

### Scanning Pipeline Architecture

```d2
direction: down

title: CI/CD Security Pipeline {
  shape: text
  near: top-center
  style.font-size: 24
}

precommit: Pre-Commit Hooks {
  style.fill: "#E3F2FD"
  
  gitleaks: Gitleaks\n(Secrets) {
    shape: hexagon
    style.fill: "#2196F3"
    style.font-color: white
  }
  
  hooks: Pre-commit\nHooks {
    shape: hexagon
    style.fill: "#2196F3"
    style.font-color: white
  }
  
  semgrep_local: Local Semgrep\n(Quick SAST) {
    shape: hexagon
    style.fill: "#2196F3"
    style.font-color: white
  }
}

pr: Pull Request Scans {
  style.fill: "#E8F5E9"
  
  semgrep: Semgrep\nSAST {
    shape: hexagon
    style.fill: "#4CAF50"
    style.font-color: white
  }
  
  deps: Dependency\nScanning {
    shape: hexagon
    style.fill: "#4CAF50"
    style.font-color: white
  }
  
  iac: IaC Scanning\n(Checkov/tfsec) {
    shape: hexagon
    style.fill: "#4CAF50"
    style.font-color: white
  }
}

build: Build Stage {
  style.fill: "#FFF3E0"
  
  container: Container\nScanning {
    shape: hexagon
    style.fill: "#FF9800"
    style.font-color: white
  }
  
  sbom: SBOM\nGeneration {
    shape: document
    style.fill: "#FF9800"
    style.font-color: white
  }
  
  license: License\nCompliance {
    shape: hexagon
    style.fill: "#FFB74D"
    style.font-color: white
  }
}

postdeploy: Post-Deploy Scans {
  style.fill: "#FFCDD2"
  
  dast: DAST\n(ZAP) {
    shape: hexagon
    style.fill: "#F44336"
    style.font-color: white
  }
  
  api: API Security\nTesting {
    shape: hexagon
    style.fill: "#F44336"
    style.font-color: white
  }
  
  monitoring: Continuous\nMonitoring {
    shape: hexagon
    style.fill: "#EF5350"
    style.font-color: white
  }
}

precommit -> pr: Commit
pr -> build: Merge
build -> postdeploy: Deploy
```

### Tool Integration Flow

```d2
direction: down

title: Results Aggregation {
  shape: text
  near: top-center
  style.font-size: 24
}

scanners: Scanner Results {
  style.fill: "#E3F2FD"
  
  trivy: Trivy\nResults {
    shape: document
    style.fill: "#2196F3"
    style.font-color: white
  }
  
  semgrep: Semgrep\nResults {
    shape: document
    style.fill: "#4CAF50"
    style.font-color: white
  }
  
  zap: ZAP\nResults {
    shape: document
    style.fill: "#F44336"
    style.font-color: white
  }
  
  grype: Grype\nResults {
    shape: document
    style.fill: "#FF9800"
    style.font-color: white
  }
}

formats: Output Formats {
  style.fill: "#E8F5E9"
  
  sarif: SARIF Format\n(Unified) {
    shape: document
    style.fill: "#4CAF50"
    style.font-color: white
  }
  
  native: JSON/XML\n(Native) {
    shape: document
    style.fill: "#81C784"
    style.font-color: white
  }
}

defectdojo: DefectDojo {
  shape: hexagon
  style.fill: "#9C27B0"
  style.font-color: white
}

outputs: Integrations {
  style.fill: "#FCE4EC"
  
  jira: Jira\nTickets {
    shape: rectangle
    style.fill: "#0052CC"
    style.font-color: white
  }
  
  slack: Slack\nAlerts {
    shape: rectangle
    style.fill: "#4A154B"
    style.font-color: white
  }
  
  grafana: Dashboards\n(Grafana) {
    shape: rectangle
    style.fill: "#F46800"
    style.font-color: white
  }
}

scanners -> formats: Convert
formats -> defectdojo: Import
defectdojo -> outputs: Notify
```

## Configuration

### Trivy Configuration

```yaml
# trivy.yaml
scan:
  scanners:
    - vuln
    - secret
    - misconfig
  
severity:
  - CRITICAL
  - HIGH
  - MEDIUM

vulnerability:
  type:
    - os
    - library
  ignore-unfixed: false
  
secret:
  config: trivy-secret.yaml

misconfig:
  policy-bundle-repository: ghcr.io/aquasecurity/trivy-policies:latest
  
cache:
  backend: fs
  ttl: 24h

db:
  repository: ghcr.io/aquasecurity/trivy-db
  
output:
  format: sarif
  output: trivy-results.sarif
```

### Semgrep Configuration

```yaml
# .semgrep.yaml
rules:
  - id: custom-sql-injection
    patterns:
      - pattern-either:
          - pattern: $QUERY = "..." + $INPUT + "..."
          - pattern: $QUERY = f"...{$INPUT}..."
    message: Potential SQL injection vulnerability
    languages: [python, javascript, typescript]
    severity: ERROR
    metadata:
      cwe: "CWE-89"
      owasp: "A03:2021"

  - id: hardcoded-secret
    pattern: $KEY = "..."
    pattern-regex: (?i)(password|secret|api_key|token)\s*=\s*["'][^"']+["']
    message: Hardcoded credential detected
    languages: [python, javascript, go]
    severity: WARNING
```

```yaml
# semgrep.yaml (CI config)
version: 1

rules:
  - p/security-audit
  - p/secrets
  - p/owasp-top-ten
  - p/cwe-top-25

paths:
  include:
    - src/
    - lib/
  exclude:
    - "**/test/**"
    - "**/vendor/**"
    - "**/*.test.*"

options:
  max-target-bytes: 1000000
  timeout: 300
  jobs: 4
```

### OWASP ZAP Configuration

```yaml
# zap-config.yaml
env:
  contexts:
    - name: "Default Context"
      urls:
        - "https://target-app.com"
      includePaths:
        - "https://target-app.com/.*"
      excludePaths:
        - ".*logout.*"
        - ".*static.*"
      authentication:
        method: "form"
        parameters:
          loginUrl: "https://target-app.com/login"
          loginRequestData: "username={%username%}&password={%password%}"
        verification:
          method: "response"
          loggedInRegex: "\\Qlogout\\E"
          loggedOutRegex: "\\Qlogin\\E"
      users:
        - name: "test-user"
          credentials:
            username: "testuser"
            password: "testpassword"

jobs:
  - type: passiveScan-config
    parameters:
      maxAlertsPerRule: 10
      scanOnlyInScope: true
      maxBodySizeInBytesToScan: 10000

  - type: spider
    parameters:
      maxDuration: 5
      maxDepth: 5
      maxChildren: 10

  - type: activeScan
    parameters:
      maxRuleDurationInMins: 5
      maxScanDurationInMins: 60
      policy: "API-Scan"
```

### Gitleaks Configuration

```toml
# .gitleaks.toml
title = "Gitleaks Config"

[extend]
useDefault = true

[[rules]]
id = "custom-api-key"
description = "Custom API Key Pattern"
regex = '''(?i)api[_-]?key['\"]?\s*[:=]\s*['\"]?([a-zA-Z0-9]{32,})'''
secretGroup = 1
keywords = ["api_key", "apikey"]

[[rules]]
id = "custom-jwt"
description = "JWT Token"
regex = '''eyJ[A-Za-z0-9-_=]+\.eyJ[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*'''
keywords = ["eyJ"]

[allowlist]
description = "Global Allowlist"
paths = [
    '''(.*?)test(.*?)''',
    '''\.gitleaks\.toml''',
    '''go\.sum''',
    '''package-lock\.json'''
]
```

### Checkov Configuration

```yaml
# .checkov.yaml
branch: main
compact: true
directory:
  - terraform/
  - kubernetes/
download-external-modules: true
evaluate-variables: true
external-modules-download-path: .external_modules
framework:
  - terraform
  - kubernetes
  - helm
  - dockerfile
output:
  - cli
  - sarif
output-file-path: checkov-results
quiet: true
skip-check:
  - CKV_AWS_18  # Skip specific check
  - CKV_K8S_21  # Skip default namespace check
soft-fail: false
```

## Security Policies

### Vulnerability Thresholds

```yaml
# security-policy.yaml
vulnerability_thresholds:
  fail_build:
    critical: 0
    high: 5
    medium: 20
    low: 100
  
  warn:
    critical: 0
    high: 0
    medium: 10
    low: 50

sla_response_times:
  critical:
    hours: 4
    escalation: security-team
  high:
    hours: 24
    escalation: dev-lead
  medium:
    days: 7
    escalation: none
  low:
    days: 30
    escalation: none

exceptions:
  allowed_duration_days: 90
  requires_approval: true
  approvers:
    - security-team
    - ciso
```

### Scanning Schedule

```yaml
# scanning-schedule.yaml
schedules:
  pre_commit:
    tools:
      - gitleaks
    blocking: true
    
  pull_request:
    tools:
      - semgrep
      - trivy-fs
      - checkov
    blocking: true
    
  merge_to_main:
    tools:
      - trivy-image
      - grype
      - sbom-generation
    blocking: true
    
  nightly:
    tools:
      - zap-full-scan
      - nuclei
      - trivy-repo
    blocking: false
    
  weekly:
    tools:
      - full-dependency-audit
      - license-compliance
      - container-drift-detection
    blocking: false
```

## Monitoring and Alerting

### Prometheus Metrics

```yaml
# prometheus rules for security scanning
groups:
  - name: security_scanning
    rules:
      - alert: CriticalVulnerabilityDetected
        expr: security_scan_vulnerabilities{severity="critical"} > 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Critical vulnerability detected"
          description: "{{ $value }} critical vulnerabilities in {{ $labels.image }}"
      
      - alert: ScanFailure
        expr: security_scan_status{status="failed"} == 1
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Security scan failed"
          description: "{{ $labels.scanner }} scan failed for {{ $labels.target }}"
```

### Grafana Dashboard Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `vulnerabilities_total` | Total vulnerabilities by severity | Critical > 0 |
| `scan_duration_seconds` | Time taken for scans | > 30 min |
| `scan_success_rate` | Percentage of successful scans | < 95% |
| `mttr_hours` | Mean time to remediate | Critical > 4h |
| `sla_compliance_rate` | SLA compliance percentage | < 90% |

## SBOM (Software Bill of Materials)

### SBOM Generation

```bash
# Generate SBOM with Syft
syft packages dir:. -o spdx-json > sbom.spdx.json
syft packages dir:. -o cyclonedx-json > sbom.cyclonedx.json

# Generate SBOM with Trivy
trivy sbom --format spdx-json --output sbom.json .
trivy sbom --format cyclonedx --output sbom.xml .

# Scan SBOM for vulnerabilities
grype sbom:sbom.spdx.json
trivy sbom sbom.cyclonedx.json
```

### SBOM Policy

```yaml
# sbom-policy.yaml
sbom:
  required: true
  formats:
    - spdx-json
    - cyclonedx-json
  storage:
    location: s3://sbom-storage/
    retention_days: 365
  validation:
    required_fields:
      - name
      - version
      - supplier
      - license
    blocked_licenses:
      - GPL-3.0
      - AGPL-3.0
```

## Compliance Frameworks

| Framework | Relevant Checks | Tools |
|-----------|-----------------|-------|
| **PCI-DSS** | 6.5.x (Secure coding) | Semgrep, ZAP |
| **HIPAA** | Security controls | Trivy, Checkov |
| **SOC 2** | Vulnerability management | All scanners |
| **GDPR** | Data protection | Gitleaks, Semgrep |
| **OWASP Top 10** | Web vulnerabilities | ZAP, Semgrep |
| **CIS Benchmarks** | Container hardening | Trivy, Checkov |
