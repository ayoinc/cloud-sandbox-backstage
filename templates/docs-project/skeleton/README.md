# ${{ values.name }}

${{ values.description }}

## Overview

Project documentation built with MkDocs and published through Backstage TechDocs.

## Getting Started

Install [D2](https://d2lang.com/) for the diagrams, then:

```bash
pip install mkdocs-techdocs-core==1.7.1 mkdocs-d2-plugin==1.7.0
mkdocs serve
```

Open <http://localhost:8000> to preview the documentation.

## Project Structure

```text
├── docs/
│   ├── index.md
│   ├── getting-started/
│   ├── user-guide/
│   ├── architecture/
│   ├── adrs/
│   ├── runbooks/
│   └── contributing.md
├── catalog-info.yaml
├── mkdocs.yml              # Configuration used by TechDocs
└── mkdocs.standalone.yml   # Same pages as a standalone site with the ${{ values.theme }} theme
```

## Building Docs

```bash
# The build TechDocs runs
mkdocs build --strict

# A standalone site with the ${{ values.theme }} theme, written to site/
mkdocs build --strict --config-file mkdocs.standalone.yml
```

## Continuous Integration

The `Documentation` workflow runs on every push and pull request:

| Job | What it does |
| --- | --- |
| Lint Markdown | Runs markdownlint with the rules in `.markdownlint.yaml` |
| Build Documentation | Builds both configurations with `--strict`; a D2 diagram that does not compile fails the build |
| Check Links | Verifies the links between files in this repository |
| Check External Links | Verifies links to other sites every Monday and when the workflow is started by hand |

## Owner

${{ values.owner }}
