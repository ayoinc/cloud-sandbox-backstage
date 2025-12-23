# Security Scanning Suite

Comprehensive security scanning platform integrating vulnerability scanning, SAST, DAST, SCA, and container security tools.

## Quick Start

```bash
# Install Trivy (Container & IaC Scanner)
brew install aquasecurity/trivy/trivy

# Install Grype (Container Vulnerability Scanner)
brew install anchore/grype/grype

# Install Semgrep (SAST)
brew install semgrep

# Install OWASP ZAP (DAST)
docker pull zaproxy/zap-stable

# Scan a container image
trivy image nginx:latest

# Scan dependencies
grype dir:. --output table

# Run SAST scan
semgrep scan --config auto .

# Run DAST scan
docker run -t zaproxy/zap-stable zap-baseline.py -t https://target-app.com
```

## Features

| Feature | Tool | Description |
|---------|------|-------------|
| **Container Scanning** | Trivy, Grype | Detect vulnerabilities in container images |
| **IaC Scanning** | Trivy, Checkov, tfsec | Security misconfigurations in Terraform/K8s |
| **SAST** | Semgrep, CodeQL | Static application security testing |
| **DAST** | OWASP ZAP, Nuclei | Dynamic application security testing |
| **SCA** | Snyk, Dependabot | Software composition analysis |
| **Secret Detection** | Gitleaks, TruffleHog | Find secrets in code/history |
| **License Compliance** | FOSSA, Trivy | License scanning and compliance |
| **SBOM Generation** | Syft, Trivy | Software bill of materials |

## Supported Scanners

| Scanner | Type | Languages/Targets | License |
|---------|------|-------------------|---------|
| **Trivy** | Multi | Containers, IaC, SBOM, Secrets | Apache 2.0 |
| **Grype** | SCA | Container images, filesystems | Apache 2.0 |
| **Semgrep** | SAST | 30+ languages | LGPL 2.1 |
| **OWASP ZAP** | DAST | Web applications | Apache 2.0 |
| **Checkov** | IaC | Terraform, CloudFormation, K8s | Apache 2.0 |
| **Gitleaks** | Secrets | Git repositories | MIT |
| **Nuclei** | DAST | Web, Network, DNS | MIT |
| **Snyk** | Multi | Code, Containers, IaC | Commercial |

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     Security Scanning Pipeline                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │                        Source Code                               │    │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────────────┐    │    │
│  │  │ SAST    │  │ Secrets │  │ License │  │ Dependency      │    │    │
│  │  │ Semgrep │  │Gitleaks │  │ Trivy   │  │ Check (SCA)     │    │    │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────────────┘    │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                    │                                     │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │                     Container Images                             │    │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────────────┐    │    │
│  │  │ Trivy   │  │ Grype   │  │ Snyk    │  │ SBOM Generation │    │    │
│  │  │ (Vuln)  │  │ (Vuln)  │  │ (Vuln)  │  │ Syft            │    │    │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────────────┘    │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                    │                                     │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │                   Infrastructure as Code                         │    │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────────────┐    │    │
│  │  │ Trivy   │  │ Checkov │  │ tfsec   │  │ KICS            │    │    │
│  │  │ (IaC)   │  │         │  │         │  │                 │    │    │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────────────┘    │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                    │                                     │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │                    Running Applications                          │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐     │    │
│  │  │ OWASP ZAP   │  │ Nuclei      │  │ Burp Suite          │     │    │
│  │  │ (DAST)      │  │ (DAST)      │  │ (DAST/Manual)       │     │    │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘     │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                    │                                     │
│                                    ▼                                     │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │              Security Dashboard / Reporting                      │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐     │    │
│  │  │ DefectDojo  │  │ SonarQube   │  │ Grafana/Prometheus  │     │    │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘     │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Vulnerability Severity Levels

| Severity | CVSS Score | Response Time | Examples |
|----------|------------|---------------|----------|
| **Critical** | 9.0 - 10.0 | Immediate | RCE, Authentication Bypass |
| **High** | 7.0 - 8.9 | 24-48 hours | SQL Injection, XSS |
| **Medium** | 4.0 - 6.9 | 1 week | Information Disclosure |
| **Low** | 0.1 - 3.9 | 1 month | Minor configuration issues |
| **Unknown** | N/A | Assess | New CVEs without scores |

## Scanning Categories

| Category | Purpose | Tools | When to Run |
|----------|---------|-------|-------------|
| **SAST** | Find bugs in source code | Semgrep, CodeQL | Every commit |
| **SCA** | Dependency vulnerabilities | Snyk, Grype | Every commit |
| **Container** | Image vulnerabilities | Trivy, Grype | On build |
| **IaC** | Infra misconfigurations | Checkov, tfsec | On change |
| **DAST** | Runtime vulnerabilities | ZAP, Nuclei | Nightly/Weekly |
| **Secrets** | Exposed credentials | Gitleaks, TruffleHog | Pre-commit |

## Version Information

| Tool | Version | Update Frequency |
|------|---------|------------------|
| Trivy | 0.49+ | Weekly |
| Grype | 0.74+ | Weekly |
| Semgrep | 1.60+ | Weekly |
| OWASP ZAP | 2.14+ | Monthly |
| Checkov | 3.2+ | Weekly |
| Gitleaks | 8.18+ | Monthly |
| Nuclei | 3.1+ | Weekly |

## Related Documentation

- [Overview](overview.md) - Architecture, configuration, and security policies
- [Usage](usage.md) - CI/CD integration and troubleshooting
