# Spring Boot Application Template

This template creates a production-ready Spring Boot application with Java 17 and best practices.

## Features

- **Spring Boot 3** - Latest Spring framework
- **Java 17** - LTS version
- **Spring Data JPA** - Database access
- **Spring Security** - Authentication/Authorization
- **OpenAPI** - API documentation with Springdoc
- **Docker** - Containerization ready
- **GitHub Actions** - CI/CD pipeline

## Prerequisites

- Java 17+
- Maven 3.8+
- Docker (optional)

## Quick Start

```bash
# Build the application
./mvnw clean package

# Run locally
./mvnw spring-boot:run

# Run tests
./mvnw test

# Build Docker image
docker build -t myapp .
```

## Project Structure

```
├── src/main/java/
│   └── com/example/
│       ├── controller/     # REST controllers
│       ├── service/        # Business logic
│       ├── repository/     # Data access
│       ├── model/          # Entity classes
│       ├── dto/            # Data transfer objects
│       ├── config/         # Configuration
│       └── Application.java
├── src/main/resources/
│   ├── application.yml     # Configuration
│   └── db/migration/       # Flyway migrations
└── src/test/               # Test files
```

## Configuration

```yaml
# application.yml
server:
  port: 8080

spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/mydb
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
```

## API Documentation

Swagger UI is available at `/swagger-ui.html` when running locally.

## Support

Contact the Platform Team for assistance.
