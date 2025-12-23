# SonarQube Code Quality

Static code analysis platform for continuous inspection of code quality and security vulnerabilities.

## Quick Start

```bash
# Pull SonarQube image
docker pull sonarqube:10.4-community

# Start SonarQube with Docker
docker run -d --name sonarqube \
  -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  sonarqube:10.4-community

# Access UI (default credentials: admin/admin)
open http://localhost:9000

# Install SonarScanner CLI
brew install sonar-scanner

# Run first analysis
sonar-scanner \
  -Dsonar.projectKey=my-project \
  -Dsonar.sources=src \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=your-token
```

## Features

| Feature | Description | Benefit |
|---------|-------------|---------|
| **Static Analysis** | Detects bugs, vulnerabilities, and code smells | Early defect detection |
| **Quality Gates** | Pass/fail criteria for code quality | Enforce standards automatically |
| **Security Hotspots** | Identifies security-sensitive code | Proactive security review |
| **Code Coverage** | Tracks test coverage metrics | Ensure adequate testing |
| **Technical Debt** | Estimates effort to fix issues | Prioritize remediation |
| **Multi-Language** | Supports 30+ programming languages | Unified quality platform |
| **Branch Analysis** | Analyzes feature branches and PRs | Shift-left quality checks |
| **CI/CD Integration** | Native integrations with CI systems | Automated quality gates |

## Supported Languages

| Language | Analyzer | Key Rules |
|----------|----------|-----------|
| Java | SonarJava | 600+ rules |
| JavaScript/TypeScript | SonarJS | 300+ rules |
| Python | SonarPython | 200+ rules |
| C# | SonarC# | 400+ rules |
| Go | SonarGo | 100+ rules |
| PHP | SonarPHP | 200+ rules |
| Kotlin | SonarKotlin | 150+ rules |
| Ruby | SonarRuby | 80+ rules |

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Developer Workflow                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────┐    ┌──────────────┐    ┌─────────────────────────┐   │
│  │   IDE    │───▶│ SonarLint    │◀──▶│   SonarQube Server      │   │
│  │          │    │ (Real-time)  │    │                         │   │
│  └──────────┘    └──────────────┘    │  ┌─────────────────┐    │   │
│                                       │  │ Compute Engine  │    │   │
│  ┌──────────┐    ┌──────────────┐    │  │ (Analysis)      │    │   │
│  │   Git    │───▶│ CI/CD        │───▶│  └─────────────────┘    │   │
│  │  Push    │    │ Pipeline     │    │                         │   │
│  └──────────┘    └──────────────┘    │  ┌─────────────────┐    │   │
│                                       │  │ Elasticsearch   │    │   │
│  ┌──────────┐    ┌──────────────┐    │  │ (Search)        │    │   │
│  │ Scanner  │───▶│ Analysis     │───▶│  └─────────────────┘    │   │
│  │  CLI     │    │ Report       │    │                         │   │
│  └──────────┘    └──────────────┘    │  ┌─────────────────┐    │   │
│                                       │  │ PostgreSQL      │    │   │
│                                       │  │ (Persistence)   │    │   │
│                                       │  └─────────────────┘    │   │
│                                       └─────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Quality Gate Configuration

```yaml
# Default Quality Gate Conditions
quality_gate:
  name: "Sonar way"
  conditions:
    - metric: new_reliability_rating
      operator: GREATER_THAN
      value: "1"  # A rating
    - metric: new_security_rating
      operator: GREATER_THAN
      value: "1"  # A rating
    - metric: new_maintainability_rating
      operator: GREATER_THAN
      value: "1"  # A rating
    - metric: new_coverage
      operator: LESS_THAN
      value: "80"  # 80% minimum
    - metric: new_duplicated_lines_density
      operator: GREATER_THAN
      value: "3"  # 3% maximum
```

## Issue Severity Levels

| Severity | Description | Example |
|----------|-------------|---------|
| **Blocker** | Bug with high impact | Null pointer exception |
| **Critical** | Bug or security vulnerability | SQL injection |
| **Major** | Quality flaw impacting productivity | Complex method |
| **Minor** | Quality flaw with minor impact | Missing documentation |
| **Info** | Not a flaw, just information | TODO comments |

## Version Compatibility

| Component | Version | Notes |
|-----------|---------|-------|
| SonarQube Community | 10.4+ | Free, open source |
| SonarQube Developer | 10.4+ | Branch analysis, PR decoration |
| SonarQube Enterprise | 10.4+ | Portfolio management |
| SonarScanner CLI | 5.0+ | Language-agnostic scanner |
| SonarScanner Maven | 3.10+ | Maven projects |
| SonarScanner Gradle | 4.4+ | Gradle projects |
| PostgreSQL | 13-16 | Required for production |
| Elasticsearch | Embedded | Part of SonarQube |

## Related Documentation

- [Overview](overview.md) - Architecture, configuration, and security
- [Usage](usage.md) - Deployment examples and troubleshooting
