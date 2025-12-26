# ${{ values.name }}

${{ values.description }}

## Overview

| Property         | Value                     |
| ---------------- | ------------------------- |
| **Owner**        | ${{ values.owner }}       |
| **Environment**  | ${{ values.environment }} |
| **Java Version** | ${{ values.javaVersion }} |
| **Port**         | ${{ values.serverPort }}  |

## Quick Start

```bash
# Build
./mvnw clean package

# Run
./mvnw spring-boot:run

# Test
./mvnw test
```

## API Endpoints

| Endpoint           | Method | Description            |
| ------------------ | ------ | ---------------------- |
| `/api`             | GET    | API root               |
| `/api/health`      | GET    | Health check           |
| `/actuator/health` | GET    | Spring Actuator health |
