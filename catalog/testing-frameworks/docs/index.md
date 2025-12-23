# Testing Frameworks Suite

Comprehensive testing frameworks for unit, integration, and end-to-end testing across all supported languages.

## Quick Start

```bash
# JavaScript/TypeScript - Jest
npm install --save-dev jest @types/jest ts-jest
npm test

# Python - pytest
pip install pytest pytest-cov pytest-asyncio
pytest --cov=src

# Go - testing
go test -v -race -cover ./...

# E2E - Playwright
npm install --save-dev @playwright/test
npx playwright test
```

## Features

| Feature | Description | Status |
|---------|-------------|--------|
| Unit Testing | Jest, pytest, go test, JUnit | Active |
| Integration Testing | Supertest, pytest-httpx, testcontainers | Active |
| E2E Testing | Playwright, Cypress | Active |
| API Testing | Postman/Newman, REST Assured | Active |
| Coverage Reporting | Istanbul, coverage.py, go cover | Active |
| Mocking | Jest mocks, unittest.mock, gomock | Active |
| Snapshot Testing | Jest snapshots, syrupy | Active |
| Visual Regression | Playwright screenshots, Percy | Active |

## Architecture

```
+------------------------------------------------------------------+
|                    TESTING PYRAMID                                |
+------------------------------------------------------------------+
|                                                                   |
|                         +-------+                                 |
|                        /   E2E   \                                |
|                       /  Playwright\                              |
|                      +-------------+                              |
|                     /   Integration  \                            |
|                    /   Supertest/API   \                          |
|                   +-------------------+                           |
|                  /      Unit Tests      \                         |
|                 /   Jest/pytest/go test  \                        |
|                +-------------------------+                        |
|                                                                   |
|  +-------------------+    +-------------------+                   |
|  |   Test Runner     |    |   Coverage Tool   |                   |
|  |   Jest/pytest     |--->|   Istanbul/c8     |                   |
|  |   go test         |    |   coverage.py     |                   |
|  +-------------------+    +-------------------+                   |
|           |                        |                              |
|           v                        v                              |
|  +-------------------+    +-------------------+                   |
|  |   CI Integration  |    |   Quality Gate    |                   |
|  |   GitHub Actions  |--->|   SonarQube       |                   |
|  |   GitLab CI       |    |   Codecov         |                   |
|  +-------------------+    +-------------------+                   |
|                                                                   |
+------------------------------------------------------------------+
```

## Supported Frameworks

| Language | Unit Test | Integration | E2E | Coverage |
|----------|-----------|-------------|-----|----------|
| JavaScript/TS | Jest, Vitest | Supertest | Playwright | c8, Istanbul |
| Python | pytest | pytest-httpx | Playwright | coverage.py |
| Go | testing | testcontainers | - | go cover |
| Java | JUnit 5 | REST Assured | Selenium | JaCoCo |
| .NET | xUnit, NUnit | WebApplicationFactory | Playwright | Coverlet |

## Test Types

| Type | Purpose | Tools | Speed |
|------|---------|-------|-------|
| **Unit** | Test isolated functions/classes | Jest, pytest | Fast |
| **Integration** | Test component interactions | Supertest, testcontainers | Medium |
| **E2E** | Test full user flows | Playwright, Cypress | Slow |
| **API** | Test HTTP endpoints | Postman, REST Assured | Medium |
| **Performance** | Test load/stress | k6, Locust | Varies |
| **Visual** | Test UI appearance | Percy, Chromatic | Medium |
| **Contract** | Test API contracts | Pact, Prism | Fast |
| **Mutation** | Test test quality | Stryker, mutmut | Slow |

## Configuration Files

```
project/
├── jest.config.js          # Jest configuration
├── vitest.config.ts         # Vitest configuration
├── pytest.ini               # pytest configuration
├── playwright.config.ts     # Playwright configuration
├── cypress.config.ts        # Cypress configuration
├── .nycrc                   # NYC/Istanbul coverage
└── codecov.yml              # Codecov configuration
```

## CLI Commands Reference

| Language | Run Tests | With Coverage | Watch Mode |
|----------|-----------|---------------|------------|
| Node.js | `npm test` | `npm test -- --coverage` | `npm test -- --watch` |
| Python | `pytest` | `pytest --cov=src` | `pytest-watch` |
| Go | `go test ./...` | `go test -cover ./...` | `gotestsum --watch` |
| Java | `./gradlew test` | `./gradlew jacocoTestReport` | - |

## Related Documentation

- [Overview](overview.md) - Framework configurations and patterns
- [Usage](usage.md) - Examples and CI integration
