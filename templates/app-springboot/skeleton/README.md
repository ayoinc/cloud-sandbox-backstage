# ${{ values.name }}

${{ values.description }}

## Overview

Spring Boot application with Java/Kotlin and production-ready features.

## Getting Started

```bash
./gradlew bootRun
# or
./mvnw spring-boot:run
```

Application available at [http://localhost:8080](http://localhost:8080)

## Build

```bash
./gradlew build
# or
./mvnw package
```

## Scripts

- `./gradlew bootRun` - Start development server
- `./gradlew build` - Build JAR
- `./gradlew test` - Run tests
- `./gradlew bootJar` - Create executable JAR

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /actuator/health | Health check |
| GET | /api/v1/* | API routes |

## Project Structure

```
├── src/main/java/
│   └── com/example/
│       ├── controller/
│       ├── service/
│       ├── repository/
│       └── Application.java
└── src/test/java/
```

## Configuration

Edit `application.yml` or use environment variables.

## License

MIT

## Author

${{ values.owner }}
