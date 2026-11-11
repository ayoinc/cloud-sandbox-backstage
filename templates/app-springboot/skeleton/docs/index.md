# ${{ values.name }}

${{ values.description }}

## Overview

| Setting     | Value                                                                               |
| ----------- | ----------------------------------------------------------------------------------- |
| Service     | `${{ values.name }}`                                                                |
| Owner       | `${{ values.owner }}`                                                               |
| Environment | `${{ values.environment }}`                                                         |
| Framework   | Spring Boot 3.5 (Web, Actuator, Validation)                                         |
| Java        | ${{ values.javaVersion }} (see `.java-version`)                                     |
| Build tool  | Maven                                                                               |
| Port        | `${{ values.serverPort }}`                                                          |
| Repository  | <https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}> |

```d2
direction: right

client: Client {
  shape: oval
}

app: ${{ values.name }} {
  api: "ApiController\n/api, /api/health"
  actuator: "Actuator\n/actuator/health, /actuator/info, /actuator/metrics"
  config: "application.yml\nSERVER_PORT, APP_ENV" {
    shape: page
  }
  config -> api
  config -> actuator
}

client -> app.api: HTTP ${{ values.serverPort }}
client -> app.actuator: HTTP ${{ values.serverPort }}
```

## Project structure

```
${{ values.name }}/
├── .github/workflows/
│   └── springboot.yaml       # Build, tests, static analysis, image
├── src/
│   ├── main/
│   │   ├── java/com/example/
│   │   │   ├── Application.java
│   │   │   └── controller/ApiController.java
│   │   └── resources/application.yml
│   └── test/java/com/example/
│       ├── ApplicationTests.java
│       └── controller/ApiControllerTest.java
├── .java-version             # Java version used by CI
├── Dockerfile
├── pom.xml
├── catalog-info.yaml         # Backstage catalog entry
└── mkdocs.yml                # TechDocs configuration
```

## Local development

Requires JDK ${{ values.javaVersion }} and Maven 3.9.

```bash
git clone https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}.git
cd ${{ values.destination.repo }}
mvn spring-boot:run
```

```bash
curl http://localhost:${{ values.serverPort }}/api
curl http://localhost:${{ values.serverPort }}/actuator/health
```

| Command                      | Purpose                                             |
| ---------------------------- | --------------------------------------------------- |
| `mvn spring-boot:run`        | Start the application                               |
| `mvn test`                   | Run the tests                                       |
| `mvn verify`                 | Compile, test and build the executable JAR          |
| `mvn compile spotbugs:check` | SpotBugs static analysis; fails when it finds a bug |

## Endpoints

| Method | Path                | Response                                        |
| ------ | ------------------- | ----------------------------------------------- |
| GET    | `/api`              | `service`, `version`, `message`                 |
| GET    | `/api/health`       | `status`, `timestamp`, `service`, `environment` |
| GET    | `/actuator/health`  | `{ "status": "UP" }`                            |
| GET    | `/actuator/info`    | Application information                         |
| GET    | `/actuator/metrics` | Names of the available metrics                  |

## Configuration

`src/main/resources/application.yml` holds the settings. Two of them read an
environment variable first:

| Variable      | Default                     | Purpose                                    |
| ------------- | --------------------------- | ------------------------------------------ |
| `SERVER_PORT` | `${{ values.serverPort }}`  | Port the application listens on            |
| `APP_ENV`     | `${{ values.environment }}` | Environment name reported by `/api/health` |

`JAVA_OPTS` passes JVM options to the container; it defaults to
`-XX:MaxRAMPercentage=75.0`.

## Testing

`ApplicationTests` checks that the application context starts.
`ApiControllerTest` calls the controller and Actuator endpoints through
MockMvc. Test reports are written to `target/surefire-reports/`.

## Continuous integration

`.github/workflows/springboot.yaml` runs on every push and pull request to
`main`:

| Job             | What it does                                                                  |
| --------------- | ----------------------------------------------------------------------------- |
| Build and test  | `mvn verify`; uploads the test reports                                        |
| Static analysis | SpotBugs, and a Trivy report of known vulnerabilities in the dependencies     |
| Image           | Hadolint, image build, start and `/actuator/health` call, Trivy image report  |

The Trivy scans report and do not fail the build. In a public repository the
dependency results also appear in the repository's Security tab.

On pushes to `main` the image is published to the GitHub Container Registry
with the workflow's own token; no secret has to be configured:

```
ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:latest
ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:sha-<commit>
```

## Docker

```bash
docker build -t ${{ values.name }} .
docker run --rm -p ${{ values.serverPort }}:${{ values.serverPort }} ${{ values.name }}
```

The image builds the JAR with Maven and runs it on a JRE as a non-root user.

## References

- [Spring Boot reference](https://docs.spring.io/spring-boot/index.html)
- [Spring Boot Actuator](https://docs.spring.io/spring-boot/reference/actuator/index.html)
- [SpotBugs](https://spotbugs.github.io/)
