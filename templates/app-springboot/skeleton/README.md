# ${{ values.name }}

${{ values.description }}

Spring Boot 3 service (Java ${{ values.javaVersion }}, Maven).

## Getting started

Requires JDK ${{ values.javaVersion }} and Maven 3.9.

```bash
mvn spring-boot:run
```

The application listens on <http://localhost:${{ values.serverPort }}>.

## Commands

- `mvn spring-boot:run` starts the application
- `mvn verify` compiles, runs the tests and builds the executable JAR in `target/`
- `mvn test` runs the tests only
- `mvn compile spotbugs:check` runs the SpotBugs static analysis

## Endpoints

| Method | Path               | Description                    |
| ------ | ------------------ | ------------------------------ |
| GET    | `/api`             | Service name and version       |
| GET    | `/api/health`      | Status, timestamp, environment |
| GET    | `/actuator/health` | Spring Boot Actuator health    |

## Configuration

Settings live in `src/main/resources/application.yml`. `SERVER_PORT` overrides
the port (default `${{ values.serverPort }}`) and `APP_ENV` the environment
name (default `${{ values.environment }}`).

## Docker

```bash
docker build -t ${{ values.name }} .
docker run --rm -p ${{ values.serverPort }}:${{ values.serverPort }} ${{ values.name }}
```

## Owner

${{ values.owner }}
