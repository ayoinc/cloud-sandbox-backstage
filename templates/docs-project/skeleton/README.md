# ${{ values.name }}

${{ values.description }}

## Overview

Project documentation using MkDocs and TechDocs.

## Getting Started

```bash
pip install mkdocs mkdocs-techdocs-core
mkdocs serve
```

Access at [http://localhost:8000](http://localhost:8000)

## Project Structure

```
├── docs/
│   ├── index.md
│   ├── getting-started.md
│   └── api/
└── mkdocs.yml
```

## Building Docs

```bash
mkdocs build
```

## Configuration

Edit `mkdocs.yml`:

```yaml
site_name: My Project
nav:
  - Home: index.md
  - Getting Started: getting-started.md
plugins:
  - techdocs-core
```

## License

MIT

## Author

${{ values.owner }}
