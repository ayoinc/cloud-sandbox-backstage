# ${{ values.name }}

${{ values.description }}

## Overview

Containerized application with Docker and docker-compose.

## Getting Started

```bash
docker-compose up -d
```

## Build

```bash
docker build -t ${{ values.name }} .
docker run -p 8080:8080 ${{ values.name }}
```

## Project Structure

```
├── Dockerfile          # Container definition
├── docker-compose.yml  # Multi-container setup
├── .dockerignore       # Build exclusions
└── src/                # Application source
```

## Configuration

Environment variables in `docker-compose.yml` or `.env`.

## Commands

- `docker-compose up -d` - Start containers
- `docker-compose down` - Stop containers
- `docker-compose logs -f` - View logs
- `docker-compose build` - Rebuild images

## License

MIT

## Author

${{ values.owner }}
