# ${{ values.name }}

${{ values.description }}

## Overview

Welcome to the documentation for **${{ values.name }}**. This comprehensive documentation system provides a structured approach to documenting your project, including installation guides, user manuals, architecture details, and contribution guidelines.

```d2
direction: right

title: {
  label: Project Documentation Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

users: Users {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  developers: Developers {
    shape: person
  }

  operators: Operators {
    shape: person
  }

  stakeholders: Stakeholders {
    shape: person
  }
}

docs: Documentation Hub {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  getting_started: Getting Started {
    style.fill: "#C8E6C9"
    overview: Overview
    installation: Installation
    quickstart: Quickstart
  }

  user_guide: User Guide {
    style.fill: "#FFF9C4"
    introduction: Introduction
    features: Features
    configuration: Configuration
  }

  architecture: Architecture {
    style.fill: "#FCE4EC"
    overview: Overview
    components: Components
  }

  contributing: Contributing {
    style.fill: "#E1F5FE"
  }
}

backstage: Backstage {
  shape: hexagon
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"

  techdocs: TechDocs {
    shape: cylinder
  }

  catalog: Catalog
}

users -> docs: "Access"
docs -> backstage.techdocs: "Published"
backstage.techdocs -> backstage.catalog: "Registered"
```

## Configuration Summary

| Setting | Value |
| --- | --- |
| Documentation Name | `${{ values.name }}` |
| Owner | `${{ values.owner }}` |
| Documentation Type | `${{ values.docType }}` |
| Theme | `${{ values.theme }}` |
| API Documentation | `${{ values.includeApiDocs }}` |
| Changelog Tracking | `${{ values.includeChangelog }}` |

---

## Quick Links

| Section | Description | Audience |
| --- | --- | --- |
| [Getting Started](getting-started/overview.md) | Begin here if you're new | New users |
| [Installation](getting-started/installation.md) | Setup instructions | Developers |
| [Quickstart](getting-started/quickstart.md) | Get running quickly | All users |
| [User Guide](user-guide/introduction.md) | Learn how to use the project | End users |
| [Features](user-guide/features.md) | Feature documentation | All users |
| [Configuration](user-guide/configuration.md) | Configuration options | Operators |
| [Architecture](architecture/overview.md) | Understand the design | Developers |
| [Components](architecture/components.md) | Component breakdown | Developers |
| [Contributing](contributing.md) | Help improve the project | Contributors |

---

## Documentation Structure

```d2
direction: down

root: ${{ values.name }}/ {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  docs: docs/ {
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"

    index: index.md
    contributing: contributing.md

    getting_started: getting-started/ {
      style.fill: "#C8E6C9"
      overview: overview.md
      installation: installation.md
      quickstart: quickstart.md
    }

    user_guide: user-guide/ {
      style.fill: "#FFF9C4"
      introduction: introduction.md
      features: features.md
      configuration: configuration.md
    }

    architecture: architecture/ {
      style.fill: "#FCE4EC"
      overview: overview.md
      components: components.md
    }
  }

  github: .github/workflows/ {
    style.fill: "#F3E5F5"
    style.stroke: "#7B1FA2"
    docs_workflow: docs.yaml
  }

  mkdocs: mkdocs.yml
  catalog: catalog-info.yaml
  readme: README.md
}
```

### Directory Descriptions

| Directory | Purpose | Contents |
| --- | --- | --- |
| `docs/` | Root documentation directory | All markdown documentation files |
| `docs/getting-started/` | Onboarding documentation | Installation, quickstart, overview |
| `docs/user-guide/` | User-facing documentation | Features, configuration, tutorials |
| `docs/architecture/` | Technical documentation | System design, components, patterns |
| `.github/workflows/` | CI/CD automation | Documentation build and publish |

---

## Features

This documentation template includes:

### Core Features

| Feature | Description |
| --- | --- |
| **Comprehensive Structure** | Pre-organized documentation hierarchy |
| **Search Functionality** | Full-text search via TechDocs |
| **Code Syntax Highlighting** | Support for multiple programming languages |
| **Responsive Design** | Works on desktop and mobile devices |
| **Easy Navigation** | Sidebar navigation and breadcrumbs |
| **Mermaid Diagrams** | Support for flowcharts and diagrams |
| **D2 Diagrams** | Declarative diagram support |

### MkDocs Theme Features

{% if values.theme == "material" %}
Using the **Material for MkDocs** theme provides:

- Dark/light mode toggle
- Instant loading (single-page application feel)
- Integrated search with suggestions
- Navigation tabs
- Social cards
- Content tabs
- Admonitions (callouts)
- Code annotations

{% else %}
Using the **Read the Docs** theme provides:

- Classic documentation look
- Wide browser support
- Sidebar navigation
- Search functionality
- Mobile responsive design
{% endif %}

---

## Getting Started

### For New Users

If you're new to this project, follow this learning path:

```d2
direction: right

step1: 1. Overview {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  label: "Read Overview\n(5 min)"
}

step2: 2. Installation {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Install Project\n(15 min)"
}

step3: 3. Quickstart {
  style.fill: "#FFF9C4"
  style.stroke: "#FBC02D"
  label: "Complete Tutorial\n(20 min)"
}

step4: 4. User Guide {
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
  label: "Learn Features\n(30 min)"
}

step5: 5. Advanced {
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"
  label: "Explore Architecture"
}

step1 -> step2 -> step3 -> step4 -> step5
```

1. **[Overview](getting-started/overview.md)** - Understand what this project does
2. **[Installation](getting-started/installation.md)** - Set up your environment
3. **[Quickstart](getting-started/quickstart.md)** - Complete your first task
4. **[User Guide](user-guide/introduction.md)** - Learn the features in depth
5. **[Architecture](architecture/overview.md)** - Dive into the technical details

### Prerequisites

Before getting started, ensure you have:

| Requirement | Version | Purpose |
| --- | --- | --- |
| Git | 2.x+ | Clone repository |
| Python | 3.8+ | MkDocs build (local preview) |
| pip | Latest | Python package management |
| Node.js | 18+ | If using npm-based tooling |

### Local Documentation Preview

To preview documentation locally:

```bash
# Clone the repository
git clone <repository-url>
cd ${{ values.name }}

# Install MkDocs and dependencies
pip install mkdocs mkdocs-material mkdocs-techdocs-core

# Start local server
mkdocs serve

# Open http://localhost:8000 in your browser
```

---

## User Guide

### Introduction

The [User Guide](user-guide/introduction.md) provides comprehensive documentation for all users. It covers:

- Basic concepts and terminology
- Common use cases and workflows
- Step-by-step tutorials
- Tips and best practices

### Features Documentation

The [Features](user-guide/features.md) section documents all available functionality:

| Category | Examples |
| --- | --- |
| Core Features | Primary functionality |
| Advanced Features | Power user capabilities |
| Integrations | Third-party connections |
| Extensions | Plugin and extension system |

### Configuration

The [Configuration](user-guide/configuration.md) section covers:

- Environment variables
- Configuration files
- Runtime options
- Feature flags
- Performance tuning

#### Configuration Example

```yaml
# config.yaml
app:
  name: ${{ values.name }}
  environment: production
  debug: false

logging:
  level: INFO
  format: json

features:
  feature_a: true
  feature_b: false
```

---

## Architecture

### System Overview

The [Architecture Overview](architecture/overview.md) provides:

- High-level system design
- Technology stack explanation
- Design principles and patterns
- System boundaries and interfaces

```d2
direction: down

title: {
  label: System Architecture Overview
  near: top-center
  shape: text
  style.font-size: 20
  style.bold: true
}

external: External Layer {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  users: Users {
    shape: person
  }

  clients: Client Apps
  apis: External APIs
}

application: Application Layer {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  gateway: API Gateway {
    shape: hexagon
  }

  services: Services {
    service_a: Service A
    service_b: Service B
    service_c: Service C
  }

  gateway -> services
}

data: Data Layer {
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"

  primary_db: Primary DB {
    shape: cylinder
  }

  cache: Cache {
    shape: cylinder
  }

  queue: Message Queue {
    shape: queue
  }
}

infrastructure: Infrastructure Layer {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"

  k8s: Kubernetes
  monitoring: Monitoring
  logging: Logging
}

external -> application.gateway
application.services -> data
data -> infrastructure
```

### Components

The [Components](architecture/components.md) section details:

- Individual component responsibilities
- Component interfaces and contracts
- Dependencies between components
- Component configuration options

---

## Contributing

We welcome contributions to both the project and its documentation. See the [Contributing Guide](contributing.md) for details.

### Documentation Contributions

```d2
direction: right

identify: Identify Need {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

fork: Fork & Branch {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
}

write: Write/Edit {
  style.fill: "#FFF9C4"
  style.stroke: "#FBC02D"
}

preview: Preview Locally {
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
}

pr: Pull Request {
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"
}

review: Review & Merge {
  style.fill: "#C8E6C9"
  style.stroke: "#388E3C"
}

identify -> fork -> write -> preview -> pr -> review
```

#### How to Contribute

1. **Fork the repository** and create a new branch
2. **Make your changes** to the documentation
3. **Preview locally** using `mkdocs serve`
4. **Submit a pull request** with a clear description
5. **Address feedback** from reviewers
6. **Get merged** once approved

#### Documentation Standards

| Standard | Description |
| --- | --- |
| **Clear Language** | Use simple, direct language |
| **Consistent Style** | Follow existing patterns |
| **Working Examples** | Test all code examples |
| **Proper Links** | Verify all links work |
| **Spell Check** | Proofread for errors |
| **Inclusive Language** | Use welcoming terminology |

---

## CI/CD Pipeline

This documentation includes automated workflows for building and publishing.

### Documentation Workflow

```d2
direction: right

push: Push/PR {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

lint: Lint Markdown {
  style.fill: "#FFF9C4"
  style.stroke: "#FBC02D"
}

build: Build Docs {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
}

link_check: Check Links {
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
}

publish: Publish {
  style.fill: "#C8E6C9"
  style.stroke: "#388E3C"
}

push -> lint -> build -> link_check -> publish
```

### Pipeline Features

| Stage | Description | Trigger |
| --- | --- | --- |
| **Lint** | Check markdown formatting | All pushes |
| **Build** | Compile documentation | All pushes |
| **Link Check** | Verify internal/external links | All pushes |
| **Publish** | Deploy to TechDocs | Main branch only |

### Running Locally

```bash
# Install development dependencies
pip install -r requirements-dev.txt

# Lint markdown files
markdownlint docs/

# Build documentation
mkdocs build

# Check for broken links
linkchecker site/

# Serve for preview
mkdocs serve
```

---

{% if values.includeApiDocs %}
## API Documentation

This project includes API documentation. See the [API Reference](api/index.md) for:

- Endpoint documentation
- Request/response schemas
- Authentication details
- Code examples

### OpenAPI Integration

API documentation is generated from OpenAPI/Swagger specifications:

```d2
direction: right

openapi: OpenAPI Spec {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  shape: page
}

generator: Doc Generator {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
}

docs: API Docs {
  style.fill: "#FFF9C4"
  style.stroke: "#FBC02D"
  shape: page
}

techdocs: TechDocs {
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
}

openapi -> generator -> docs -> techdocs
```

{% endif %}

{% if values.includeChangelog %}
## Changelog

This project maintains a changelog to track all notable changes.

### Changelog Format

We follow [Keep a Changelog](https://keepachangelog.com/) format:

| Section | Description |
| --- | --- |
| **Added** | New features |
| **Changed** | Changes to existing functionality |
| **Deprecated** | Features to be removed |
| **Removed** | Removed features |
| **Fixed** | Bug fixes |
| **Security** | Security updates |

See [CHANGELOG.md](../CHANGELOG.md) for the complete history.

{% endif %}

---

## Troubleshooting

### Common Issues

#### Documentation Not Building

**Problem**: `mkdocs build` fails with errors.

**Solutions**:
```bash
# Check Python version
python --version  # Should be 3.8+

# Reinstall dependencies
pip install --upgrade mkdocs mkdocs-material mkdocs-techdocs-core

# Validate mkdocs.yml
mkdocs build --strict
```

#### Missing Navigation Items

**Problem**: Pages don't appear in the sidebar.

**Solution**: Ensure pages are listed in `mkdocs.yml` navigation:

```yaml
nav:
  - Home: index.md
  - Getting Started:
    - Overview: getting-started/overview.md
    - Installation: getting-started/installation.md
```

#### Broken Links

**Problem**: Links to other pages return 404.

**Solutions**:
- Use relative paths: `[Link](../other-page.md)`
- Don't include `.md` extension in some configurations
- Run link checker: `linkchecker site/`

#### TechDocs Not Updating

**Problem**: Changes don't appear in Backstage TechDocs.

**Solutions**:
1. Verify the documentation build succeeded in CI
2. Check that TechDocs is configured to rebuild
3. Refresh the TechDocs cache in Backstage
4. Verify `catalog-info.yaml` has correct TechDocs annotation

#### Search Not Working

**Problem**: Search returns no results.

**Solutions**:
- Ensure `search` plugin is enabled in `mkdocs.yml`
- Rebuild the documentation
- Clear browser cache
- Check TechDocs search index is being generated

---

## Best Practices

### Writing Documentation

| Practice | Description |
| --- | --- |
| **Start with Why** | Explain the purpose before the details |
| **Use Examples** | Show, don't just tell |
| **Keep it Current** | Update docs with code changes |
| **Test Code Samples** | Verify all examples work |
| **Progressive Disclosure** | Start simple, add complexity |
| **Use Visuals** | Diagrams explain complex concepts |

### Documentation Structure

```d2
direction: down

title: {
  label: Documentation Hierarchy
  near: top-center
  shape: text
  style.font-size: 18
  style.bold: true
}

overview: Overview {
  style.fill: "#E3F2FD"
  label: "What is this?\nWhy should I care?"
}

getting_started: Getting Started {
  style.fill: "#E8F5E9"
  label: "How do I start?\nQuick wins"
}

guides: User Guides {
  style.fill: "#FFF9C4"
  label: "How do I use features?\nTutorials"
}

reference: Reference {
  style.fill: "#FCE4EC"
  label: "API docs\nConfiguration"
}

explanation: Explanation {
  style.fill: "#F3E5F5"
  label: "Architecture\nDesign decisions"
}

overview -> getting_started -> guides -> reference
guides -> explanation
```

### Markdown Tips

```markdown
# Use proper heading hierarchy
## H2 for main sections
### H3 for subsections
#### H4 sparingly

# Use callouts for important information
!!! note
    Important information here

!!! warning
    Be careful about this

# Use code blocks with language hints
```python
def example():
    return "Hello, World!"
```

# Use tables for structured data
| Column 1 | Column 2 |
| --- | --- |
| Value 1 | Value 2 |
```

---

## Getting Help

If you need assistance:

1. **Check the Documentation** - Search for your topic
2. **Review [Common Issues](#troubleshooting)** - See if it's a known problem
3. **Ask the Team** - Contact ${{ values.owner }}
4. **Open an Issue** - Report documentation gaps

### Contact

| Channel | Use Case |
| --- | --- |
| Slack: #documentation | Quick questions |
| Email: docs@company.com | Detailed requests |
| GitHub Issues | Bug reports, feature requests |

---

## Related Templates

| Template | Description |
| --- | --- |
| [docs-adr](/docs/default/template/docs-adr) | Architecture Decision Records |
| [docs-runbook](/docs/default/template/docs-runbook) | Operational runbooks |
| [docs-d2-guide](/docs/default/template/docs-d2-guide) | D2 diagramming documentation |

---

## References

- [Backstage TechDocs](https://backstage.io/docs/features/techdocs/)
- [MkDocs Documentation](https://www.mkdocs.org/)
- [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/)
- [Markdown Guide](https://www.markdownguide.org/)
- [Divio Documentation System](https://documentation.divio.com/) - Documentation structure principles
- [Write the Docs](https://www.writethedocs.org/) - Documentation community and best practices

---

## Version

| Field | Value |
| --- | --- |
| Documentation Version | 1.0.0 |
| Last Updated | {{ date }} |
| Owner | ${{ values.owner }} |
