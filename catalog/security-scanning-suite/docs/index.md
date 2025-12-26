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

| Feature                | Tool                  | Description                                 |
| ---------------------- | --------------------- | ------------------------------------------- |
| **Container Scanning** | Trivy, Grype          | Detect vulnerabilities in container images  |
| **IaC Scanning**       | Trivy, Checkov, tfsec | Security misconfigurations in Terraform/K8s |
| **SAST**               | Semgrep, CodeQL       | Static application security testing         |
| **DAST**               | OWASP ZAP, Nuclei     | Dynamic application security testing        |
| **SCA**                | Snyk, Dependabot      | Software composition analysis               |
| **Secret Detection**   | Gitleaks, TruffleHog  | Find secrets in code/history                |
| **License Compliance** | FOSSA, Trivy          | License scanning and compliance             |
| **SBOM Generation**    | Syft, Trivy           | Software bill of materials                  |

## Supported Scanners

| Scanner       | Type    | Languages/Targets              | License    |
| ------------- | ------- | ------------------------------ | ---------- |
| **Trivy**     | Multi   | Containers, IaC, SBOM, Secrets | Apache 2.0 |
| **Grype**     | SCA     | Container images, filesystems  | Apache 2.0 |
| **Semgrep**   | SAST    | 30+ languages                  | LGPL 2.1   |
| **OWASP ZAP** | DAST    | Web applications               | Apache 2.0 |
| **Checkov**   | IaC     | Terraform, CloudFormation, K8s | Apache 2.0 |
| **Gitleaks**  | Secrets | Git repositories               | MIT        |
| **Nuclei**    | DAST    | Web, Network, DNS              | MIT        |
| **Snyk**      | Multi   | Code, Containers, IaC          | Commercial |

## Architecture

```d2
direction: down

title: Security Scanning Pipeline {
  shape: text
  near: top-center
  style.font-size: 24
}

source: Source Code Scanning {
  style.fill: "#E3F2FD"

  sast: SAST\nSemgrep {
    shape: hexagon
    style.fill: "#2196F3"
    style.font-color: white
  }

  secrets: Secrets\nGitleaks {
    shape: hexagon
    style.fill: "#2196F3"
    style.font-color: white
  }

  license: License\nTrivy {
    shape: hexagon
    style.fill: "#2196F3"
    style.font-color: white
  }

  sca: Dependency\nCheck (SCA) {
    shape: hexagon
    style.fill: "#2196F3"
    style.font-color: white
  }
}

container: Container Image Scanning {
  style.fill: "#E8F5E9"

  trivy: Trivy\n(Vuln) {
    shape: hexagon
    style.fill: "#4CAF50"
    style.font-color: white
  }

  grype: Grype\n(Vuln) {
    shape: hexagon
    style.fill: "#4CAF50"
    style.font-color: white
  }

  snyk: Snyk\n(Vuln) {
    shape: hexagon
    style.fill: "#4CAF50"
    style.font-color: white
  }

  sbom: SBOM\nSyft {
    shape: document
    style.fill: "#81C784"
    style.font-color: white
  }
}

iac: Infrastructure as Code {
  style.fill: "#FFF3E0"

  trivy_iac: Trivy\n(IaC) {
    shape: hexagon
    style.fill: "#FF9800"
    style.font-color: white
  }

  checkov: Checkov {
    shape: hexagon
    style.fill: "#FF9800"
    style.font-color: white
  }

  tfsec: tfsec {
    shape: hexagon
    style.fill: "#FF9800"
    style.font-color: white
  }

  kics: KICS {
    shape: hexagon
    style.fill: "#FF9800"
    style.font-color: white
  }
}

runtime: Running Applications (DAST) {
  style.fill: "#FFCDD2"

  zap: OWASP ZAP {
    shape: hexagon
    style.fill: "#F44336"
    style.font-color: white
  }

  nuclei: Nuclei {
    shape: hexagon
    style.fill: "#F44336"
    style.font-color: white
  }

  burp: Burp Suite\n(Manual) {
    shape: hexagon
    style.fill: "#EF5350"
    style.font-color: white
  }
}

dashboard: Security Dashboard / Reporting {
  style.fill: "#F3E5F5"

  defectdojo: DefectDojo {
    shape: rectangle
    style.fill: "#9C27B0"
    style.font-color: white
  }

  sonarqube: SonarQube {
    shape: rectangle
    style.fill: "#9C27B0"
    style.font-color: white
  }

  grafana: Grafana/\nPrometheus {
    shape: rectangle
    style.fill: "#9C27B0"
    style.font-color: white
  }
}

source -> container: Build
container -> iac: Deploy
iac -> runtime: Running
runtime -> dashboard: Report
source -> dashboard: Results {style.stroke-dash: 3}
container -> dashboard: Results {style.stroke-dash: 3}
iac -> dashboard: Results {style.stroke-dash: 3}
```

## Vulnerability Severity Levels

| Severity     | CVSS Score | Response Time | Examples                   |
| ------------ | ---------- | ------------- | -------------------------- |
| **Critical** | 9.0 - 10.0 | Immediate     | RCE, Authentication Bypass |
| **High**     | 7.0 - 8.9  | 24-48 hours   | SQL Injection, XSS         |
| **Medium**   | 4.0 - 6.9  | 1 week        | Information Disclosure     |
| **Low**      | 0.1 - 3.9  | 1 month       | Minor configuration issues |
| **Unknown**  | N/A        | Assess        | New CVEs without scores    |

## Scanning Categories

| Category      | Purpose                    | Tools                | When to Run    |
| ------------- | -------------------------- | -------------------- | -------------- |
| **SAST**      | Find bugs in source code   | Semgrep, CodeQL      | Every commit   |
| **SCA**       | Dependency vulnerabilities | Snyk, Grype          | Every commit   |
| **Container** | Image vulnerabilities      | Trivy, Grype         | On build       |
| **IaC**       | Infra misconfigurations    | Checkov, tfsec       | On change      |
| **DAST**      | Runtime vulnerabilities    | ZAP, Nuclei          | Nightly/Weekly |
| **Secrets**   | Exposed credentials        | Gitleaks, TruffleHog | Pre-commit     |

## Version Information

| Tool      | Version | Update Frequency |
| --------- | ------- | ---------------- |
| Trivy     | 0.49+   | Weekly           |
| Grype     | 0.74+   | Weekly           |
| Semgrep   | 1.60+   | Weekly           |
| OWASP ZAP | 2.14+   | Monthly          |
| Checkov   | 3.2+    | Weekly           |
| Gitleaks  | 8.18+   | Monthly          |
| Nuclei    | 3.1+    | Weekly           |

## Related Documentation

- [Overview](overview.md) - Architecture, configuration, and security policies
- [Usage](usage.md) - CI/CD integration and troubleshooting
