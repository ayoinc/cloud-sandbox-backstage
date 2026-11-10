# ${{ values.name }}

${{ values.description }}

## Overview

Documentation with D2 diagrams for system architecture visualization. The diagrams live next to the text as fenced `d2` code blocks and are rendered by the `mkdocs-d2-plugin` when the documentation is built.

## Getting Started

```bash
# Install D2
curl -fsSL https://d2lang.com/install.sh | sh -s --

# Install MkDocs with the TechDocs and D2 plugins
pip install mkdocs-techdocs-core==1.7.1 mkdocs-d2-plugin==1.7.0

# Preview the documentation with live reload
mkdocs serve
```

## Project Structure

```
├── docs/
│   ├── index.md          # D2 guide and syntax reference
│   ├── architecture.md   # Architecture diagrams
│   └── examples.md       # Common diagram patterns
├── catalog-info.yaml
└── mkdocs.yml            # MkDocs configuration with the D2 plugin
```

## D2 Basics

````markdown
```d2
# Define shapes
server: Server
database: Database

# Connect them
server -> database: queries
```
````

## Continuous Integration

The `Documentation` workflow builds the site with `mkdocs build --strict` on every push and pull request. A D2 diagram that does not compile, or a broken link between pages, fails the build.

## Owner

${{ values.owner }}
