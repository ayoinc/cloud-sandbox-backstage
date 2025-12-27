# ${{ values.name }}

${{ values.description }}

## Overview

This Spring Boot application provides a production-ready microservice foundation with:

- RESTful API endpoints with validation support
- Spring Boot Actuator for health monitoring and metrics
- Docker containerization with multi-stage builds
- GitHub Actions CI/CD pipeline for automated builds and deployments
- Structured logging and environment-based configuration

```d2
direction: right

title: {
  label: Spring Boot Application Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

client: Client {
  shape: oval
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
}

app: Spring Boot Application {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  controller: Controllers {
    shape: rectangle
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"
    label: "REST Controllers\n@RestController"
  }

  service: Services {
    shape: rectangle
    style.fill: "#FCE4EC"
    style.stroke: "#C2185B"
    label: "Business Logic\n@Service"
  }

  repository: Repositories {
    shape: rectangle
    style.fill: "#F3E5F5"
    style.stroke: "#7B1FA2"
    label: "Data Access\n@Repository"
  }

  config: Configuration {
    shape: hexagon
    style.fill: "#FFECB3"
    style.stroke: "#FFA000"
    label: "application.yml\n@Configuration"
  }

  actuator: Actuator {
    shape: cylinder
    style.fill: "#E0F7FA"
    style.stroke: "#00838F"
    label: "Health\nMetrics\nInfo"
  }

  controller -> service
  service -> repository
  config -> controller
  config -> service
}

db: Database {
  shape: cylinder
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
}

client -> app.controller: HTTP/REST
app.repository -> db: JDBC/JPA
```

## Configuration Summary

| Setting             | Value                       |
| ------------------- | --------------------------- |
| Application Name    | `${{ values.name }}`        |
| Owner               | ${{ values.owner }}         |
| Environment         | `${{ values.environment }}` |
| Java Version        | `${{ values.javaVersion }}` |
| Server Port         | `${{ values.serverPort }}`  |
| Spring Boot Version | `3.2.1`                     |

---

## Project Structure

```
${{ values.name }}/
├── .github/
│   └── workflows/
│       └── springboot.yaml      # CI/CD pipeline configuration
├── docs/
│   └── index.md                 # This documentation
├── src/
│   ├── main/
│   │   ├── java/com/example/
│   │   │   ├── Application.java           # Main application entry point
│   │   │   └── controller/
│   │   │       └── ApiController.java     # REST API endpoints
│   │   └── resources/
│   │       └── application.yml            # Application configuration
│   └── test/
│       └── java/com/example/
│           ├── ApplicationTests.java      # Application context tests
│           └── controller/
│               └── ApiControllerTest.java # Controller unit tests
├── catalog-info.yaml            # Backstage catalog entity
├── Dockerfile                   # Multi-stage Docker build
├── mkdocs.yml                   # Documentation configuration
├── pom.xml                      # Maven project configuration
└── README.md                    # Project readme
```

### Key Directories

| Directory          | Purpose                                       |
| ------------------ | --------------------------------------------- |
| `src/main/java`    | Application source code                       |
| `src/main/resources` | Configuration files (application.yml)       |
| `src/test/java`    | Unit and integration tests                    |
| `.github/workflows` | GitHub Actions CI/CD pipelines               |
| `docs/`            | Technical documentation for Backstage TechDocs |

---

## CI/CD Pipeline

This repository includes a comprehensive GitHub Actions pipeline with:

- **Build & Test**: Compile source code and run all tests
- **Maven Caching**: Faster builds with dependency caching
- **Docker Build**: Multi-stage container image creation
- **Container Registry**: Automatic push to GitHub Container Registry (ghcr.io)
- **Test Reports**: Artifact upload for test results

### Pipeline Workflow

```d2
direction: right

pr: Pull Request {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

checkout: Checkout {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Clone\nRepository"
}

setup: Setup JDK {
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"
  label: "JDK ${{ values.javaVersion }}\nTemurin"
}

build: Build & Test {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "mvn clean verify\nUnit Tests"
}

artifacts: Upload Artifacts {
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"
  label: "Test Results\nSurefire Reports"
}

docker: Docker Build {
  style.fill: "#E0F7FA"
  style.stroke: "#00838F"
  label: "Build Image\nPush to GHCR"
}

deploy: Deploy {
  shape: hexagon
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Container\nRegistry"
}

pr -> checkout -> setup -> build -> artifacts
build -> docker: main branch
docker -> deploy
```

### Pipeline Triggers

| Trigger                | Actions                               |
| ---------------------- | ------------------------------------- |
| Pull Request to `main` | Build, Test, Upload Artifacts         |
| Push to `main`         | Build, Test, Docker Build, Push Image |

---

## Prerequisites

### 1. Development Environment

#### Required Software

| Software   | Minimum Version | Purpose                    |
| ---------- | --------------- | -------------------------- |
| JDK        | ${{ values.javaVersion }}            | Java runtime and compiler  |
| Maven      | 3.8+            | Build and dependency management |
| Docker     | 20.10+          | Container build and runtime |
| Git        | 2.30+           | Version control            |

#### Install JDK (Temurin/AdoptOpenJDK)

```bash
# macOS (Homebrew)
brew install --cask temurin@${{ values.javaVersion }}

# Ubuntu/Debian
sudo apt install openjdk-${{ values.javaVersion }}-jdk

# Windows (Chocolatey)
choco install temurin${{ values.javaVersion }}

# Verify installation
java -version
```

#### Install Maven

```bash
# macOS
brew install maven

# Ubuntu/Debian
sudo apt install maven

# Windows
choco install maven

# Verify installation
mvn -version
```

#### Install Docker

```bash
# macOS
brew install --cask docker

# Ubuntu
sudo apt install docker.io
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Verify installation
docker --version
```

### 2. IDE Setup (Recommended)

#### IntelliJ IDEA

1. Open project via **File > Open** and select `pom.xml`
2. Import as Maven project when prompted
3. Install recommended plugins:
   - Spring Boot Assistant
   - Lombok (if using Lombok)
   - Docker

#### VS Code

1. Install extensions:
   - Extension Pack for Java
   - Spring Boot Extension Pack
   - Docker
2. Open project folder
3. Maven will auto-configure

### 3. GitHub Repository Setup

#### Required Secrets

Configure these in **Settings > Secrets and variables > Actions**:

| Secret         | Description                        | Required |
| -------------- | ---------------------------------- | -------- |
| `GITHUB_TOKEN` | Auto-provided for GHCR push        | Auto     |

No additional secrets required for basic CI/CD. The pipeline uses the automatically provided `GITHUB_TOKEN` for container registry authentication.

---

## Usage

### Local Development

```bash
# Clone the repository
git clone <repository-url>
cd ${{ values.name }}

# Build the project
./mvnw clean package

# Run the application
./mvnw spring-boot:run

# Run with specific profile
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev

# Access the application
curl http://localhost:${{ values.serverPort }}/api
curl http://localhost:${{ values.serverPort }}/api/health
curl http://localhost:${{ values.serverPort }}/actuator/health
```

### Maven Commands

| Command                          | Description                        |
| -------------------------------- | ---------------------------------- |
| `./mvnw clean`                   | Clean build artifacts              |
| `./mvnw compile`                 | Compile source code                |
| `./mvnw test`                    | Run unit tests                     |
| `./mvnw package`                 | Build JAR file                     |
| `./mvnw verify`                  | Run integration tests              |
| `./mvnw clean package -DskipTests` | Build without running tests      |
| `./mvnw spring-boot:run`         | Run application locally            |
| `./mvnw dependency:tree`         | Show dependency tree               |
| `./mvnw versions:display-dependency-updates` | Check for dependency updates |

### Docker Build & Run

```bash
# Build the Docker image
docker build -t ${{ values.name }}:latest .

# Run the container
docker run -d \
  --name ${{ values.name }} \
  -p ${{ values.serverPort }}:${{ values.serverPort }} \
  ${{ values.name }}:latest

# View logs
docker logs -f ${{ values.name }}

# Stop the container
docker stop ${{ values.name }}

# Remove the container
docker rm ${{ values.name }}

# Run with environment variables
docker run -d \
  --name ${{ values.name }} \
  -p ${{ values.serverPort }}:${{ values.serverPort }} \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e JAVA_OPTS="-Xmx512m" \
  ${{ values.name }}:latest
```

### Docker Compose (Optional)

Create a `docker-compose.yml` for local development:

```yaml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "${{ values.serverPort }}:${{ values.serverPort }}"
    environment:
      - SPRING_PROFILES_ACTIVE=dev
    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:${{ values.serverPort }}/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

---

## API Documentation

### Available Endpoints

| Endpoint           | Method | Description                    | Response Type |
| ------------------ | ------ | ------------------------------ | ------------- |
| `/api`             | GET    | API root with service info     | JSON          |
| `/api/health`      | GET    | Application health status      | JSON          |
| `/actuator/health` | GET    | Spring Actuator health endpoint | JSON          |
| `/actuator/info`   | GET    | Application information        | JSON          |
| `/actuator/metrics` | GET   | Application metrics            | JSON          |

### API Examples

#### Root Endpoint

```bash
curl http://localhost:${{ values.serverPort }}/api
```

**Response:**

```json
{
  "service": "${{ values.name }}",
  "version": "1.0.0",
  "message": "Welcome to ${{ values.name }} API"
}
```

#### Health Check Endpoint

```bash
curl http://localhost:${{ values.serverPort }}/api/health
```

**Response:**

```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "service": "${{ values.name }}",
  "environment": "${{ values.environment }}"
}
```

#### Actuator Health

```bash
curl http://localhost:${{ values.serverPort }}/actuator/health
```

**Response:**

```json
{
  "status": "UP"
}
```

### HTTP Status Codes

| Code | Description                              |
| ---- | ---------------------------------------- |
| 200  | Success                                  |
| 400  | Bad Request - Invalid input              |
| 401  | Unauthorized - Authentication required   |
| 403  | Forbidden - Insufficient permissions     |
| 404  | Not Found - Resource doesn't exist       |
| 500  | Internal Server Error                    |

---

## Testing Strategy

### Test Types

| Type              | Location                    | Framework      | Purpose                      |
| ----------------- | --------------------------- | -------------- | ---------------------------- |
| Unit Tests        | `src/test/java`             | JUnit 5        | Test individual components   |
| Integration Tests | `src/test/java`             | Spring Boot Test | Test component interactions |
| API Tests         | `src/test/java`             | MockMvc        | Test REST endpoints          |

### Running Tests

```bash
# Run all tests
./mvnw test

# Run specific test class
./mvnw test -Dtest=ApiControllerTest

# Run tests with coverage
./mvnw test jacoco:report

# Run integration tests only
./mvnw verify -DskipUnitTests

# Run tests in parallel
./mvnw test -T 4
```

### Test Coverage

Configure JaCoCo in `pom.xml` for coverage reports:

```xml
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <version>0.8.11</version>
    <executions>
        <execution>
            <goals>
                <goal>prepare-agent</goal>
            </goals>
        </execution>
        <execution>
            <id>report</id>
            <phase>test</phase>
            <goals>
                <goal>report</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

### Test Examples

```java
@SpringBootTest
@AutoConfigureMockMvc
class ApiControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void shouldReturnWelcomeMessage() throws Exception {
        mockMvc.perform(get("/api"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.service").exists());
    }

    @Test
    void shouldReturnHealthStatus() throws Exception {
        mockMvc.perform(get("/api/health"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("healthy"));
    }
}
```

---

## Security Features

### Current Security Configuration

This template includes foundational security practices:

| Feature                  | Status    | Description                          |
| ------------------------ | --------- | ------------------------------------ |
| Non-root Container User  | Enabled   | Runs as `spring` user (UID 1001)     |
| Health Endpoint Auth     | Configured | `show-details: when-authorized`     |
| Input Validation         | Enabled   | Spring Validation starter included   |
| Container Health Check   | Enabled   | Docker HEALTHCHECK configured        |

### Adding Spring Security

To add authentication and authorization, add this dependency:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

### Security Best Practices

1. **Environment Variables**: Never commit secrets to version control
2. **HTTPS**: Enable TLS in production environments
3. **Input Validation**: Validate all user inputs
4. **Dependencies**: Regularly update dependencies for security patches
5. **Actuator Security**: Restrict actuator endpoints in production

### Securing Actuator Endpoints

Add to `application.yml` for production:

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info
  endpoint:
    health:
      show-details: never
```

---

## Troubleshooting

### Build Issues

**Error: Java version mismatch**

```
Fatal error compiling: invalid target release: ${{ values.javaVersion }}
```

**Resolution:**

1. Verify Java version: `java -version`
2. Set `JAVA_HOME` to correct JDK installation
3. Ensure Maven uses correct Java: `mvn -version`

---

**Error: Maven wrapper not executable**

```
./mvnw: Permission denied
```

**Resolution:**

```bash
chmod +x mvnw
```

---

### Runtime Issues

**Error: Port already in use**

```
Web server failed to start. Port ${{ values.serverPort }} was already in use.
```

**Resolution:**

```bash
# Find process using the port
lsof -i :${{ values.serverPort }}

# Kill the process
kill -9 <PID>

# Or run on different port
./mvnw spring-boot:run -Dserver.port=8081
```

---

**Error: Application fails to start**

```
Application run failed
```

**Resolution:**

1. Check logs for specific error messages
2. Verify `application.yml` syntax
3. Ensure all required dependencies are available
4. Run with debug logging: `./mvnw spring-boot:run -Ddebug`

---

### Docker Issues

**Error: Docker build fails**

```
failed to solve: eclipse-temurin:${{ values.javaVersion }}-jdk-alpine: not found
```

**Resolution:**

```bash
# Verify image exists
docker pull eclipse-temurin:${{ values.javaVersion }}-jdk-alpine

# Check Docker Hub for available tags
# https://hub.docker.com/_/eclipse-temurin
```

---

**Error: Container health check failing**

```
container is unhealthy
```

**Resolution:**

1. Check container logs: `docker logs <container-id>`
2. Verify application is starting correctly
3. Increase `--start-period` in Dockerfile HEALTHCHECK
4. Test health endpoint manually

---

### CI/CD Pipeline Issues

**Error: Docker push fails**

```
denied: permission_denied
```

**Resolution:**

1. Verify `packages: write` permission in workflow
2. Check GITHUB_TOKEN is available
3. Ensure repository allows package publishing

---

**Error: Tests failing in CI but passing locally**

**Resolution:**

1. Check for environment-specific configurations
2. Verify test database/mock configurations
3. Check for timing-dependent tests
4. Review CI environment differences

---

## Related Templates

| Template                                              | Description                           |
| ----------------------------------------------------- | ------------------------------------- |
| [app-springboot-jpa](/docs/default/template/app-springboot-jpa) | Spring Boot with JPA/Hibernate       |
| [app-springboot-kafka](/docs/default/template/app-springboot-kafka) | Spring Boot with Kafka messaging   |
| [app-springboot-security](/docs/default/template/app-springboot-security) | Spring Boot with Spring Security |
| [app-node-express](/docs/default/template/app-node-express) | Node.js Express application         |
| [app-python-fastapi](/docs/default/template/app-python-fastapi) | Python FastAPI application         |
| [aws-eks](/docs/default/template/aws-eks)             | Amazon EKS for deployment             |
| [aws-rds](/docs/default/template/aws-rds)             | Amazon RDS for database               |

---

## References

- [Spring Boot Documentation](https://docs.spring.io/spring-boot/docs/current/reference/html/)
- [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
- [Maven Documentation](https://maven.apache.org/guides/)
- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Eclipse Temurin JDK](https://adoptium.net/)
- [Spring Initializr](https://start.spring.io/)
- [Backstage TechDocs](https://backstage.io/docs/features/techdocs/)
