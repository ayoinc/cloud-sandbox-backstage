# ${{ values.name }}

${{ values.description }}

## Overview

Architecture Decision Records (ADRs) provide a structured way to capture and communicate important architectural decisions made throughout the lifecycle of a project. This repository serves as the central location for all ADRs related to your team or project.

```d2
direction: right

title: {
  label: ADR Documentation System
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

team: Team Members {
  shape: person
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

adr_repo: ADR Repository {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  proposed: Proposed ADRs {
    style.fill: "#FFF9C4"
    style.stroke: "#FBC02D"
  }

  accepted: Accepted ADRs {
    style.fill: "#C8E6C9"
    style.stroke: "#388E3C"
  }

  deprecated: Deprecated ADRs {
    style.fill: "#FFCDD2"
    style.stroke: "#D32F2F"
  }

  superseded: Superseded ADRs {
    style.fill: "#E1BEE7"
    style.stroke: "#7B1FA2"
  }

  proposed -> accepted: "Review & Approve"
  accepted -> deprecated: "No Longer Valid"
  accepted -> superseded: "New ADR"
}

backstage: Backstage Catalog {
  shape: hexagon
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
}

search: TechDocs Search {
  shape: cylinder
  style.fill: "#E1F5FE"
  style.stroke: "#0288D1"
}

team -> adr_repo: "Create & Review"
adr_repo -> backstage: "Registered"
backstage -> search: "Indexed"
```

## What are ADRs?

Architecture Decision Records (ADRs) are short text documents that capture important architectural decisions made along with their context and consequences. They were first described by Michael Nygard in his article ["Documenting Architecture Decisions"](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions).

### Why Use ADRs?

ADRs serve multiple critical purposes in software development:

| Purpose | Description |
| --- | --- |
| **Historical Record** | Capture why decisions were made at a specific point in time |
| **Team Alignment** | Ensure all team members understand and agree on key decisions |
| **Onboarding** | Help new team members quickly understand architectural context |
| **Future Reference** | Provide context when revisiting or reversing decisions |
| **Accountability** | Create a clear record of who made decisions and when |
| **Knowledge Sharing** | Share learnings across teams and projects |

### When to Create an ADR

You should create an ADR when:

- Making a significant architectural decision that affects system structure
- Choosing between multiple technologies, frameworks, or approaches
- Establishing a new pattern, practice, or convention for the team
- Changing or reversing a previously accepted architectural decision
- Making a decision that will impact multiple teams or services
- Selecting a vendor, tool, or third-party service
- Defining API contracts or integration patterns
- Establishing security, compliance, or data handling approaches

---

## Configuration Summary

| Setting | Value |
| --- | --- |
| Repository Name | `${{ values.name }}` |
| Owner | `${{ values.owner }}` |
| ADR Format | `${{ values.adrFormat }}` |
| Example ADRs Included | `${{ values.includeExamples }}` |
| Categories | {% for category in values.categories %}`{{ category }}`{% if not loop.last %}, {% endif %}{% endfor %} |

### ADR Format Comparison

This template supports multiple ADR formats:

| Format | Description | Best For |
| --- | --- | --- |
| **MADR** | Markdown Any Decision Records - Extended format with alternatives section | Teams wanting comprehensive documentation |
| **Nygard** | Original format by Michael Nygard - Simple and concise | Quick decisions, smaller teams |
| **Custom** | Customizable template for specific needs | Organizations with unique requirements |

---

## Repository Structure

```d2
direction: down

root: ${{ values.name }} {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  docs: docs/ {
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"

    index: index.md
    process: process.md
    templates: templates.md

    adrs: adrs/ {
      style.fill: "#FFF9C4"
      style.stroke: "#FBC02D"

      adr_index: index.md
      adr_001: 001-use-adrs.md
      adr_002: 002-example.md
      adr_nnn: NNN-decision.md
    }

    templates_dir: templates/ {
      style.fill: "#FCE4EC"
      style.stroke: "#C2185B"

      template: adr-template.md
    }
  }

  mkdocs: mkdocs.yml
  catalog: catalog-info.yaml
  readme: README.md
}
```

### File Descriptions

| File/Directory | Purpose |
| --- | --- |
| `docs/index.md` | Main entry point and ADR overview |
| `docs/process.md` | ADR creation and review process documentation |
| `docs/templates.md` | Available templates and how to use them |
| `docs/adrs/` | Directory containing all ADR documents |
| `docs/adrs/index.md` | Index of all ADRs with status summary |
| `docs/templates/adr-template.md` | Template for creating new ADRs |
| `mkdocs.yml` | MkDocs configuration for TechDocs |
| `catalog-info.yaml` | Backstage catalog entity definition |

---

## Quick Start

### Creating a New ADR

Follow these steps to create a new Architecture Decision Record:

#### Step 1: Determine the Next ADR Number

```bash
# List existing ADRs to find the next number
ls docs/adrs/*.md | grep -E '[0-9]{3}' | sort | tail -1
```

ADRs are numbered sequentially: `001`, `002`, `003`, etc. Always use zero-padded three-digit numbers.

#### Step 2: Copy the Template

```bash
# Copy template with the next available number
cp docs/templates/adr-template.md docs/adrs/NNN-your-decision-title.md
```

Replace `NNN` with the next number and `your-decision-title` with a short, descriptive, hyphenated title.

#### Step 3: Fill in the Template

Open the new ADR file and complete each section:

1. **Title**: Replace `ADR NNN: Title` with your decision title
2. **Status**: Set to `Proposed` initially
3. **Context**: Describe the current situation and what's driving the decision
4. **Decision**: State the decision clearly and unambiguously
5. **Consequences**: List both positive and negative outcomes
6. **Alternatives Considered**: Document other options you evaluated

#### Step 4: Submit for Review

```bash
# Create a feature branch
git checkout -b adr/NNN-your-decision-title

# Add the new ADR
git add docs/adrs/NNN-your-decision-title.md

# Commit with a descriptive message
git commit -m "ADR NNN: Your Decision Title"

# Push and create pull request
git push -u origin adr/NNN-your-decision-title
```

### ADR Status Lifecycle

```d2
direction: right

proposed: Proposed {
  shape: oval
  style.fill: "#FFF9C4"
  style.stroke: "#FBC02D"
}

review: Under Review {
  shape: diamond
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

accepted: Accepted {
  shape: oval
  style.fill: "#C8E6C9"
  style.stroke: "#388E3C"
}

deprecated: Deprecated {
  shape: oval
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
}

superseded: Superseded {
  shape: oval
  style.fill: "#E1BEE7"
  style.stroke: "#7B1FA2"
}

rejected: Rejected {
  shape: oval
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
}

proposed -> review: "PR Created"
review -> accepted: "Approved"
review -> rejected: "Not Approved"
accepted -> deprecated: "No Longer Valid"
accepted -> superseded: "Replaced by New ADR"
```

| Status | Description | When to Use |
| --- | --- | --- |
| **Proposed** | Decision is drafted and awaiting review | Initial submission |
| **Accepted** | Decision has been approved and is active | After PR approval |
| **Rejected** | Decision was not approved | After review determines it's not suitable |
| **Deprecated** | Decision is no longer relevant | Context has fundamentally changed |
| **Superseded** | Replaced by another ADR | New ADR addresses the same concern |

---

## Current ADRs

| # | Title | Status | Date |
| --- | --- | --- | --- |
| [001](adrs/001-use-adrs.md) | Use ADRs for Architecture Decisions | Accepted | 2024-01-01 |
| [002](adrs/002-example-decision.md) | Example Decision | Proposed | 2024-01-15 |

---

## ADR Categories

Organize your ADRs using these categories to improve discoverability:

{% for category in values.categories %}
### {{ category | capitalize }}

ADRs related to {{ category }} decisions. Examples include:

{% if category == "architecture" %}
- System design patterns
- Service boundaries and responsibilities
- Communication patterns (sync vs async)
- API design principles
{% elif category == "security" %}
- Authentication and authorization approaches
- Data encryption strategies
- Security protocols and standards
- Access control patterns
{% elif category == "infrastructure" %}
- Cloud provider selection
- Deployment strategies
- Container orchestration
- Network architecture
{% elif category == "data" %}
- Database selection and design
- Data modeling approaches
- Data retention and archival
- Data migration strategies
{% else %}
- Decisions related to {{ category }}
{% endif %}

{% endfor %}

---

## Review Process

### Review Workflow

```d2
direction: down

author: Author {
  shape: person
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

draft: Draft ADR {
  style.fill: "#FFF9C4"
  style.stroke: "#FBC02D"
}

pr: Pull Request {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
}

reviewers: Reviewers {
  shape: person
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"

  tech_lead: Tech Lead
  architect: Architect
  stakeholders: Stakeholders
}

discussion: Discussion {
  shape: diamond
  style.fill: "#E1F5FE"
  style.stroke: "#0288D1"
}

consensus: Consensus {
  style.fill: "#C8E6C9"
  style.stroke: "#388E3C"
}

merge: Merge & Accept {
  style.fill: "#C8E6C9"
  style.stroke: "#388E3C"
}

author -> draft: "Creates"
draft -> pr: "Submits"
pr -> reviewers: "Assigns"
reviewers -> discussion: "Feedback"
discussion -> consensus: "Agreement"
consensus -> merge: "Approve"
merge -> author: "Notify"
```

### Review Criteria

Reviewers should evaluate ADRs against these criteria:

| Criterion | Questions to Consider |
| --- | --- |
| **Clarity** | Is the context clearly explained? Is the decision stated unambiguously? |
| **Completeness** | Are all sections filled in? Are alternatives documented? |
| **Consequences** | Are both positive and negative outcomes realistic? |
| **Alignment** | Does it align with existing architectural principles? |
| **Feasibility** | Can the decision be implemented with current resources? |
| **Reversibility** | What's the cost of reversing this decision later? |

### Review Timeline

| Phase | Duration | Activities |
| --- | --- | --- |
| Initial Review | 2-3 days | Reviewers read and provide initial feedback |
| Discussion | 2-5 days | Team discusses concerns, author addresses feedback |
| Final Review | 1-2 days | Reviewers approve or request changes |
| Merge | Same day | Upon approval, ADR is merged and status updated |

---

## Best Practices

### Writing Effective ADRs

#### DO

- **Keep it concise**: Target 1-2 pages maximum
- **Focus on "why"**: Explain the reasoning, not just the decision
- **Include alternatives**: Show you considered other options
- **Be specific**: Use concrete examples and metrics when possible
- **Link related ADRs**: Create a connected knowledge base
- **Use clear language**: Avoid jargon that might confuse readers
- **Date everything**: Include dates for proposals and acceptances
- **Update status promptly**: Keep the lifecycle accurate

#### DON'T

- **Overuse ADRs**: Don't create them for trivial decisions
- **Include implementation details**: ADRs are about "what" and "why", not "how"
- **Leave in limbo**: Don't let ADRs sit as "Proposed" indefinitely
- **Modify accepted ADRs**: Create new ADRs instead of editing old ones
- **Skip context**: Never assume readers know the background
- **Ignore consequences**: Both positive and negative outcomes matter

### Naming Conventions

```
docs/adrs/NNN-short-descriptive-title.md
```

| Component | Description | Example |
| --- | --- | --- |
| `NNN` | Three-digit sequential number | `001`, `042`, `103` |
| `short-descriptive-title` | Hyphenated, lowercase title | `use-postgresql-database` |
| `.md` | Markdown extension | Required for TechDocs |

**Good Examples:**
- `001-use-adrs-for-architecture-decisions.md`
- `015-adopt-kubernetes-for-orchestration.md`
- `023-implement-event-driven-architecture.md`

**Bad Examples:**
- `1-decision.md` (missing leading zeros, vague title)
- `adr-about-the-database.md` (missing number)
- `New_Decision_2024.md` (wrong format, wrong case)

---

## Integrations

### Backstage Integration

This ADR repository is automatically registered in the Backstage catalog via the `catalog-info.yaml` file. This provides:

- **Discoverability**: Find ADRs through Backstage search
- **Ownership**: Clear indication of team ownership
- **TechDocs**: Rendered documentation within Backstage

### TechDocs

ADRs are rendered as searchable documentation in Backstage TechDocs:

```d2
direction: right

markdown: Markdown Files {
  style.fill: "#FFF9C4"
  style.stroke: "#FBC02D"
}

mkdocs: MkDocs Build {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

techdocs: TechDocs {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
}

search: Search Index {
  shape: cylinder
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
}

markdown -> mkdocs: "Build"
mkdocs -> techdocs: "Publish"
techdocs -> search: "Index"
```

### CI/CD Integration

Consider adding these automations to your workflow:

```yaml
# .github/workflows/adr-check.yaml
name: ADR Validation

on:
  pull_request:
    paths:
      - 'docs/adrs/*.md'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check ADR format
        run: |
          for file in docs/adrs/*.md; do
            if [[ $(basename "$file") =~ ^[0-9]{3}- ]]; then
              echo "Valid: $file"
            else
              echo "Invalid format: $file"
              exit 1
            fi
          done

      - name: Validate required sections
        run: |
          for file in docs/adrs/*.md; do
            if ! grep -q "## Status" "$file"; then
              echo "Missing Status section: $file"
              exit 1
            fi
            if ! grep -q "## Context" "$file"; then
              echo "Missing Context section: $file"
              exit 1
            fi
            if ! grep -q "## Decision" "$file"; then
              echo "Missing Decision section: $file"
              exit 1
            fi
          done
```

---

## Troubleshooting

### Common Issues

#### ADR Not Appearing in Index

**Problem**: New ADR doesn't show in the index table.

**Solution**: Manually update `docs/adrs/index.md` and `docs/index.md` to include the new ADR entry.

#### TechDocs Not Rendering

**Problem**: ADRs don't appear in Backstage TechDocs.

**Solution**:
1. Verify `mkdocs.yml` includes the ADR in the navigation
2. Check that `catalog-info.yaml` has the correct TechDocs annotation
3. Trigger a TechDocs rebuild in Backstage

#### Conflicting ADR Numbers

**Problem**: Two people created ADRs with the same number.

**Solution**:
1. Rename one ADR to the next available number
2. Update all references to the renamed ADR
3. Consider using a GitHub issue to reserve ADR numbers

#### Status Not Updating

**Problem**: ADR status shows old value.

**Solution**: Status must be manually updated in the ADR file. After merging, update the status line from `Proposed` to `Accepted`.

---

## Resources

### Documentation

- [ADR Process](process.md) - Detailed process documentation
- [ADR Templates](templates.md) - Available templates and usage
- [ADR Index](adrs/index.md) - Complete list of all ADRs

### External References

- [Michael Nygard's Original Article](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions) - The definitive introduction to ADRs
- [MADR](https://adr.github.io/madr/) - Markdown Any Decision Records format
- [ADR GitHub Organization](https://adr.github.io/) - Community resources and tools
- [Joel Parker Henderson's ADR Collection](https://github.com/joelparkerhenderson/architecture-decision-record) - Comprehensive ADR examples

### Tools

| Tool | Description | Link |
| --- | --- | --- |
| **adr-tools** | Command-line tools for working with ADRs | [GitHub](https://github.com/npryce/adr-tools) |
| **adr-log** | Generate changelog from ADRs | [GitHub](https://github.com/adr/adr-log) |
| **Log4brains** | ADR management tool with CLI and web UI | [GitHub](https://github.com/thomvaill/log4brains) |

---

## Related Templates

| Template | Description |
| --- | --- |
| [docs-project](/docs/default/template/docs-project) | Comprehensive project documentation |
| [docs-runbook](/docs/default/template/docs-runbook) | Operational runbooks for incident response |
| [docs-d2-guide](/docs/default/template/docs-d2-guide) | Documentation with D2 diagrams |

---

## References

- [Backstage TechDocs](https://backstage.io/docs/features/techdocs/)
- [MkDocs Documentation](https://www.mkdocs.org/)
- [D2 Language Reference](https://d2lang.com/)
- [Markdown Guide](https://www.markdownguide.org/)
