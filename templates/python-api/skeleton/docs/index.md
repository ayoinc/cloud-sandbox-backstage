# ${{ values.name }}

${{ values.description }}

## Overview

A Python API built with ${{ values.framework }} framework.

## Quick Start

### Prerequisites

- Python ${{ values.python_version }}
- pip or pipenv/poetry

### Installation

```bash
# Install dependencies
pip install -r requirements.txt

# Run development server
python -m uvicorn main:app --reload
```

### Running Tests

```bash
pytest
```

## API Documentation

Once running, access the API documentation at:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Project Structure

```
.
├── src/                 # Source code
├── tests/               # Test files
├── docs/                # Documentation
├── requirements.txt     # Dependencies
├── Dockerfile           # Container image
└── catalog-info.yaml    # Backstage metadata
```

## Configuration

Environment variables:
- `DATABASE_URL`: Database connection string
- `API_KEY`: API authentication key
- `LOG_LEVEL`: Logging level (default: INFO)

## Deployment

```bash
docker build -t ${{ values.name }} .
docker run -p 8000:8000 ${{ values.name }}
```
