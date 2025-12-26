# Usage Guide

## Getting Started

### Prerequisites

| Framework  | Language      | Installation                              |
| ---------- | ------------- | ----------------------------------------- |
| Jest       | JavaScript/TS | `npm install --save-dev jest`             |
| Vitest     | JavaScript/TS | `npm install --save-dev vitest`           |
| pytest     | Python        | `pip install pytest pytest-cov`           |
| go test    | Go            | Built-in                                  |
| Playwright | Any           | `npm install --save-dev @playwright/test` |
| JUnit 5    | Java          | Gradle/Maven dependency                   |

### Quick Setup

```bash
# JavaScript/TypeScript with Jest
npm install --save-dev jest @types/jest ts-jest
npx ts-jest config:init

# JavaScript/TypeScript with Vitest
npm install --save-dev vitest @vitest/coverage-v8
# Add to package.json: "test": "vitest"

# Python with pytest
pip install pytest pytest-cov pytest-asyncio
# Create pytest.ini or pyproject.toml

# Go
# No installation needed - use go test

# Playwright
npm init playwright@latest
```

## Examples

### Integration Testing with Supertest

```typescript
// tests/integration/api.test.ts
import request from 'supertest';
import { app } from '../../src/app';
import { db } from '../../src/database';
import { createTestUser, cleanupTestData } from '../helpers';

describe('Users API', () => {
  let authToken: string;

  beforeAll(async () => {
    await db.connect();
    const user = await createTestUser();
    authToken = user.token;
  });

  afterAll(async () => {
    await cleanupTestData();
    await db.disconnect();
  });

  describe('GET /api/users', () => {
    it('should return list of users', async () => {
      const response = await request(app)
        .get('/api/users')
        .set('Authorization', `Bearer ${authToken}`)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body).toHaveProperty('users');
      expect(Array.isArray(response.body.users)).toBe(true);
    });

    it('should require authentication', async () => {
      await request(app).get('/api/users').expect(401);
    });
  });

  describe('POST /api/users', () => {
    it('should create a new user', async () => {
      const newUser = {
        name: 'Test User',
        email: 'test@example.com',
        password: 'SecurePass123!',
      };

      const response = await request(app)
        .post('/api/users')
        .set('Authorization', `Bearer ${authToken}`)
        .send(newUser)
        .expect(201);

      expect(response.body).toMatchObject({
        id: expect.any(String),
        name: newUser.name,
        email: newUser.email,
      });
      expect(response.body).not.toHaveProperty('password');
    });

    it('should validate email format', async () => {
      const response = await request(app)
        .post('/api/users')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name: 'Test', email: 'invalid', password: 'pass' })
        .expect(400);

      expect(response.body.errors).toContainEqual(
        expect.objectContaining({ field: 'email' }),
      );
    });
  });
});
```

### Python Integration Testing

```python
# tests/integration/test_api.py
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from src.main import app
from src.database import get_db
from tests.factories import UserFactory

@pytest.fixture
async def client(db_session: AsyncSession):
    """Create test client with database session."""
    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db

    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client

    app.dependency_overrides.clear()

@pytest.fixture
async def auth_headers(client: AsyncClient, db_session: AsyncSession):
    """Create authenticated user and return headers."""
    user = await UserFactory.create(session=db_session)
    response = await client.post("/auth/login", json={
        "email": user.email,
        "password": "testpassword"
    })
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}

class TestUsersAPI:
    @pytest.mark.asyncio
    async def test_list_users(self, client: AsyncClient, auth_headers: dict):
        response = await client.get("/api/users", headers=auth_headers)

        assert response.status_code == 200
        assert "users" in response.json()
        assert isinstance(response.json()["users"], list)

    @pytest.mark.asyncio
    async def test_create_user(self, client: AsyncClient, auth_headers: dict):
        user_data = {
            "name": "New User",
            "email": "newuser@example.com",
            "password": "SecurePass123!"
        }

        response = await client.post(
            "/api/users",
            json=user_data,
            headers=auth_headers
        )

        assert response.status_code == 201
        data = response.json()
        assert data["name"] == user_data["name"]
        assert data["email"] == user_data["email"]
        assert "password" not in data

    @pytest.mark.asyncio
    @pytest.mark.parametrize("email,expected_status", [
        ("valid@example.com", 201),
        ("invalid-email", 422),
        ("", 422),
    ])
    async def test_email_validation(
        self, client: AsyncClient, auth_headers: dict, email: str, expected_status: int
    ):
        response = await client.post(
            "/api/users",
            json={"name": "Test", "email": email, "password": "pass123"},
            headers=auth_headers
        )
        assert response.status_code == expected_status
```

### Testcontainers for Database Testing

```typescript
// tests/integration/database.test.ts
import {
  PostgreSqlContainer,
  StartedPostgreSqlContainer,
} from '@testcontainers/postgresql';
import { Pool } from 'pg';
import { UserRepository } from '../../src/repositories/userRepository';

describe('UserRepository with Testcontainers', () => {
  let container: StartedPostgreSqlContainer;
  let pool: Pool;
  let repository: UserRepository;

  beforeAll(async () => {
    container = await new PostgreSqlContainer()
      .withDatabase('testdb')
      .withUsername('testuser')
      .withPassword('testpass')
      .start();

    pool = new Pool({
      connectionString: container.getConnectionUri(),
    });

    // Run migrations
    await pool.query(`
      CREATE TABLE users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        created_at TIMESTAMP DEFAULT NOW()
      )
    `);

    repository = new UserRepository(pool);
  }, 60000);

  afterAll(async () => {
    await pool.end();
    await container.stop();
  });

  beforeEach(async () => {
    await pool.query('DELETE FROM users');
  });

  it('should create and retrieve user', async () => {
    const created = await repository.create({
      name: 'John',
      email: 'john@example.com',
    });

    const found = await repository.findById(created.id);

    expect(found).toEqual(created);
  });

  it('should find user by email', async () => {
    await repository.create({ name: 'Jane', email: 'jane@example.com' });

    const found = await repository.findByEmail('jane@example.com');

    expect(found?.name).toBe('Jane');
  });
});
```

### Contract Testing with Pact

```typescript
// tests/contract/userConsumer.pact.test.ts
import { PactV3, MatchersV3 } from '@pact-foundation/pact';
import { UserApiClient } from '../../src/clients/userApiClient';

const { like, eachLike, uuid } = MatchersV3;

const provider = new PactV3({
  consumer: 'frontend-app',
  provider: 'user-service',
  dir: './pacts',
});

describe('User API Consumer', () => {
  it('should get user by id', async () => {
    await provider
      .given('a user exists')
      .uponReceiving('a request for a user')
      .withRequest({
        method: 'GET',
        path: '/api/users/1',
        headers: {
          Accept: 'application/json',
        },
      })
      .willRespondWith({
        status: 200,
        headers: {
          'Content-Type': 'application/json',
        },
        body: {
          id: like('1'),
          name: like('John Doe'),
          email: like('john@example.com'),
        },
      });

    await provider.executeTest(async mockServer => {
      const client = new UserApiClient(mockServer.url);
      const user = await client.getUser('1');

      expect(user.name).toBe('John Doe');
    });
  });
});
```

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/test.yaml
name: Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - run: npm ci
      - run: npm run test:coverage

      - uses: codecov/codecov-action@v4
        with:
          files: coverage/lcov.info
          fail_ci_if_error: true

  integration-tests:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_DB: test
          POSTGRES_PASSWORD: test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - run: npm ci
      - run: npm run test:integration
        env:
          DATABASE_URL: postgres://postgres:test@localhost:5432/test

  e2e-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - run: npm ci
      - run: npx playwright install --with-deps

      - run: npm run test:e2e

      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: playwright-report
          path: playwright-report/
```

### Coverage Requirements

```yaml
# codecov.yml
coverage:
  precision: 2
  round: down
  status:
    project:
      default:
        target: 80%
        threshold: 2%
    patch:
      default:
        target: 80%
        threshold: 5%

comment:
  layout: 'reach,diff,flags,files'
  behavior: default
  require_changes: true
```

## Troubleshooting

| Issue               | Cause                        | Solution                          |
| ------------------- | ---------------------------- | --------------------------------- |
| Tests timeout       | Async operations not awaited | Add `await` to async calls        |
| Mock not working    | Wrong mock path              | Use full module path in jest.mock |
| Flaky tests         | Race conditions              | Use proper wait/retry logic       |
| Coverage too low    | Untested branches            | Add edge case tests               |
| Database tests fail | Connection issues            | Check container/service health    |
| E2E tests slow      | Too many browser instances   | Reduce parallelism                |
| Snapshot mismatch   | Expected change              | Run with `-u` flag to update      |

### Debug Commands

```bash
# Jest debug
node --inspect-brk node_modules/.bin/jest --runInBand

# pytest debug
pytest --pdb  # Drop into debugger on failure
pytest -x     # Stop on first failure

# Playwright debug
PWDEBUG=1 npx playwright test

# Go test verbose
go test -v -run TestSpecificTest ./...
```

## Best Practices

### Test Organization

- [ ] Follow AAA pattern (Arrange, Act, Assert)
- [ ] One assertion concept per test
- [ ] Descriptive test names
- [ ] Group related tests with describe/context

### Test Data

- [ ] Use factories for test data
- [ ] Isolate test data between tests
- [ ] Clean up after tests
- [ ] Use realistic data

### Mocking

- [ ] Mock external dependencies
- [ ] Don't mock what you don't own
- [ ] Verify mock calls when relevant
- [ ] Reset mocks between tests

### Coverage

- [ ] Focus on meaningful coverage
- [ ] Test edge cases and error paths
- [ ] Don't chase 100% blindly
- [ ] Review uncovered code

## CLI Reference

| Command                    | Description         |
| -------------------------- | ------------------- |
| `npm test`                 | Run all tests       |
| `npm test -- --watch`      | Watch mode          |
| `npm test -- --coverage`   | With coverage       |
| `npm test -- -t "pattern"` | Run matching tests  |
| `pytest -v`                | Verbose output      |
| `pytest -k "pattern"`      | Run matching tests  |
| `pytest --lf`              | Run last failed     |
| `go test ./...`            | Run all tests       |
| `go test -race ./...`      | With race detection |
| `npx playwright test`      | Run E2E tests       |
| `npx playwright test --ui` | Interactive mode    |

## Related Resources

- [Jest Documentation](https://jestjs.io/)
- [pytest Documentation](https://docs.pytest.org/)
- [Playwright Documentation](https://playwright.dev/)
- [Testing Library](https://testing-library.com/)
- [Testcontainers](https://testcontainers.com/)
- [Pact Contract Testing](https://pact.io/)
