# ${{ values.name }}

${{ values.description }}

## Overview

| Property        | Value                     |
| --------------- | ------------------------- |
| **Owner**       | ${{ values.owner }}       |
| **Environment** | ${{ values.environment }} |
| **Framework**   | ${{ values.framework }}   |
| **Port**        | ${{ values.port }}        |

## Quick Start

```bash
# Install dependencies
npm install

# Run in development mode
npm run dev

# Run tests
npm test

# Build for production
npm run build

# Start production server
npm start
```

## API Endpoints

| Endpoint        | Method | Description     |
| --------------- | ------ | --------------- |
| `/health`       | GET    | Health check    |
| `/health/ready` | GET    | Readiness probe |
| `/health/live`  | GET    | Liveness probe  |
| `/api`          | GET    | API root        |

## Docker

```bash
# Build image
docker build -t ${{ values.name }} .

# Run container
docker run -p ${{ values.port }}:${{ values.port }} ${{ values.name }}
```
