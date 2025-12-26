# ${{ values.name }}

${{ values.description }}

## Overview

D2 diagram documentation for system architecture visualization.

## Getting Started

```bash
# Install D2
curl -fsSL https://d2lang.com/install.sh | sh

# Generate diagrams
d2 diagrams/architecture.d2 diagrams/architecture.svg
```

## Project Structure

```
├── diagrams/           # D2 source files
│   ├── architecture.d2
│   └── components.d2
├── docs/               # Generated documentation
└── mkdocs.yml
```

## D2 Basics

```d2
# Define shapes
server: Server
database: Database

# Connect them
server -> database: queries
```

## Commands

- `d2 input.d2 output.svg` - Generate SVG
- `d2 --watch input.d2` - Watch mode
- `d2 fmt input.d2` - Format file

## License

MIT

## Author

${{ values.owner }}
