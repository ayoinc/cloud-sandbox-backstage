# Overview

## Architecture

The Testing Frameworks Suite provides standardized testing patterns, configurations, and utilities for all supported languages. Tests are integrated into CI/CD pipelines with coverage thresholds and quality gates.

```
+------------------------------------------------------------------+
|                    TEST EXECUTION FLOW                            |
+------------------------------------------------------------------+
|                                                                   |
|  +-------------------+         +-------------------+              |
|  |   Source Code     |         |   Test Code       |              |
|  |   src/            |-------->|   tests/          |              |
|  |   lib/            |         |   __tests__/      |              |
|  +-------------------+         +-------------------+              |
|           |                            |                          |
|           v                            v                          |
|  +--------------------------------------------------+            |
|  |              TEST RUNNER                          |            |
|  |  +------------+  +------------+  +------------+  |            |
|  |  | Setup      |  | Execute    |  | Teardown   |  |            |
|  |  | Fixtures   |  | Assertions |  | Cleanup    |  |            |
|  |  +------------+  +------------+  +------------+  |            |
|  +--------------------------------------------------+            |
|                          |                                        |
|                          v                                        |
|  +--------------------------------------------------+            |
|  |              REPORTS                              |            |
|  |  +------------+  +------------+  +------------+  |            |
|  |  | JUnit XML  |  | Coverage   |  | HTML       |  |            |
|  |  | Report     |  | Report     |  | Report     |  |            |
|  |  +------------+  +------------+  +------------+  |            |
|  +--------------------------------------------------+            |
|                                                                   |
+------------------------------------------------------------------+
```

## Jest Configuration (JavaScript/TypeScript)

### Basic Configuration

```javascript
// jest.config.js
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src'],
  testMatch: ['**/__tests__/**/*.ts', '**/*.test.ts', '**/*.spec.ts'],
  transform: {
    '^.+\\.tsx?$': 'ts-jest',
  },
  collectCoverageFrom: [
    'src/**/*.{ts,tsx}',
    '!src/**/*.d.ts',
    '!src/**/index.ts',
    '!src/**/__tests__/**',
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
  },
  coverageReporters: ['text', 'lcov', 'html', 'cobertura'],
  reporters: [
    'default',
    ['jest-junit', {
      outputDirectory: 'reports',
      outputName: 'junit.xml',
    }],
  ],
  setupFilesAfterEnv: ['<rootDir>/src/setupTests.ts'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  clearMocks: true,
  testTimeout: 10000,
};
```

### Setup File

```typescript
// src/setupTests.ts
import '@testing-library/jest-dom';

// Global mocks
jest.mock('./lib/logger', () => ({
  logger: {
    info: jest.fn(),
    error: jest.fn(),
    warn: jest.fn(),
    debug: jest.fn(),
  },
}));

// Global setup
beforeAll(async () => {
  // Setup test database, etc.
});

afterAll(async () => {
  // Cleanup
});

// Reset mocks between tests
beforeEach(() => {
  jest.clearAllMocks();
});
```

### Unit Test Example

```typescript
// src/services/__tests__/userService.test.ts
import { UserService } from '../userService';
import { UserRepository } from '../../repositories/userRepository';

jest.mock('../../repositories/userRepository');

describe('UserService', () => {
  let userService: UserService;
  let mockUserRepository: jest.Mocked<UserRepository>;

  beforeEach(() => {
    mockUserRepository = new UserRepository() as jest.Mocked<UserRepository>;
    userService = new UserService(mockUserRepository);
  });

  describe('getUser', () => {
    it('should return user when found', async () => {
      const mockUser = { id: '1', name: 'John', email: 'john@example.com' };
      mockUserRepository.findById.mockResolvedValue(mockUser);

      const result = await userService.getUser('1');

      expect(result).toEqual(mockUser);
      expect(mockUserRepository.findById).toHaveBeenCalledWith('1');
    });

    it('should throw error when user not found', async () => {
      mockUserRepository.findById.mockResolvedValue(null);

      await expect(userService.getUser('999')).rejects.toThrow('User not found');
    });
  });

  describe('createUser', () => {
    it('should create and return new user', async () => {
      const input = { name: 'Jane', email: 'jane@example.com' };
      const expectedUser = { id: '2', ...input };
      mockUserRepository.create.mockResolvedValue(expectedUser);

      const result = await userService.createUser(input);

      expect(result).toEqual(expectedUser);
      expect(mockUserRepository.create).toHaveBeenCalledWith(input);
    });

    it('should validate email format', async () => {
      const input = { name: 'Jane', email: 'invalid-email' };

      await expect(userService.createUser(input)).rejects.toThrow('Invalid email');
    });
  });
});
```

## pytest Configuration (Python)

### Configuration File

```ini
# pytest.ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = 
    -v
    --tb=short
    --strict-markers
    -ra
    --cov=src
    --cov-report=term-missing
    --cov-report=html:htmlcov
    --cov-report=xml:coverage.xml
    --cov-fail-under=80
    --junitxml=reports/junit.xml
markers =
    slow: marks tests as slow
    integration: marks tests as integration tests
    e2e: marks tests as end-to-end tests
asyncio_mode = auto
filterwarnings =
    ignore::DeprecationWarning
```

### Conftest.py

```python
# tests/conftest.py
import pytest
import asyncio
from typing import Generator, AsyncGenerator
from unittest.mock import MagicMock, AsyncMock
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

from src.database import Base
from src.config import settings

# Fixtures
@pytest.fixture(scope="session")
def event_loop():
    """Create event loop for async tests."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture(scope="session")
async def db_engine():
    """Create test database engine."""
    engine = create_async_engine(
        settings.TEST_DATABASE_URL,
        echo=False,
    )
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await engine.dispose()

@pytest.fixture
async def db_session(db_engine) -> AsyncGenerator[AsyncSession, None]:
    """Create database session for each test."""
    async_session = sessionmaker(
        db_engine, class_=AsyncSession, expire_on_commit=False
    )
    async with async_session() as session:
        yield session
        await session.rollback()

@pytest.fixture
def mock_redis():
    """Mock Redis client."""
    return MagicMock()

@pytest.fixture
def mock_http_client():
    """Mock HTTP client."""
    client = AsyncMock()
    client.get.return_value.json.return_value = {"status": "ok"}
    return client
```

### Unit Test Example

```python
# tests/unit/test_user_service.py
import pytest
from unittest.mock import AsyncMock, MagicMock
from src.services.user_service import UserService
from src.models.user import User
from src.exceptions import UserNotFoundError, ValidationError

class TestUserService:
    @pytest.fixture
    def mock_user_repo(self):
        return AsyncMock()

    @pytest.fixture
    def user_service(self, mock_user_repo):
        return UserService(user_repository=mock_user_repo)

    @pytest.mark.asyncio
    async def test_get_user_returns_user_when_found(
        self, user_service, mock_user_repo
    ):
        # Arrange
        expected_user = User(id="1", name="John", email="john@example.com")
        mock_user_repo.find_by_id.return_value = expected_user

        # Act
        result = await user_service.get_user("1")

        # Assert
        assert result == expected_user
        mock_user_repo.find_by_id.assert_called_once_with("1")

    @pytest.mark.asyncio
    async def test_get_user_raises_error_when_not_found(
        self, user_service, mock_user_repo
    ):
        # Arrange
        mock_user_repo.find_by_id.return_value = None

        # Act & Assert
        with pytest.raises(UserNotFoundError):
            await user_service.get_user("999")

    @pytest.mark.asyncio
    async def test_create_user_validates_email(self, user_service):
        # Act & Assert
        with pytest.raises(ValidationError, match="Invalid email"):
            await user_service.create_user(
                name="Jane", email="invalid-email"
            )

    @pytest.mark.parametrize("email,expected", [
        ("valid@example.com", True),
        ("also.valid@sub.domain.com", True),
        ("invalid", False),
        ("@missing.local", False),
        ("missing@.domain", False),
    ])
    def test_validate_email(self, user_service, email, expected):
        result = user_service._validate_email(email)
        assert result == expected
```

## Go Testing

### Test File

```go
// internal/services/user_service_test.go
package services

import (
    "context"
    "errors"
    "testing"

    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
    "github.com/stretchr/testify/require"
    
    "myapp/internal/models"
    "myapp/internal/repositories/mocks"
)

func TestUserService_GetUser(t *testing.T) {
    t.Run("returns user when found", func(t *testing.T) {
        // Arrange
        mockRepo := mocks.NewUserRepository(t)
        service := NewUserService(mockRepo)
        
        expectedUser := &models.User{
            ID:    "1",
            Name:  "John",
            Email: "john@example.com",
        }
        mockRepo.On("FindByID", mock.Anything, "1").Return(expectedUser, nil)

        // Act
        result, err := service.GetUser(context.Background(), "1")

        // Assert
        require.NoError(t, err)
        assert.Equal(t, expectedUser, result)
        mockRepo.AssertExpectations(t)
    })

    t.Run("returns error when user not found", func(t *testing.T) {
        mockRepo := mocks.NewUserRepository(t)
        service := NewUserService(mockRepo)
        
        mockRepo.On("FindByID", mock.Anything, "999").Return(nil, ErrUserNotFound)

        result, err := service.GetUser(context.Background(), "999")

        assert.Nil(t, result)
        assert.ErrorIs(t, err, ErrUserNotFound)
    })
}

func TestUserService_CreateUser(t *testing.T) {
    tests := []struct {
        name        string
        input       models.CreateUserInput
        wantErr     bool
        expectedErr error
    }{
        {
            name: "valid input",
            input: models.CreateUserInput{
                Name:  "Jane",
                Email: "jane@example.com",
            },
            wantErr: false,
        },
        {
            name: "invalid email",
            input: models.CreateUserInput{
                Name:  "Jane",
                Email: "invalid-email",
            },
            wantErr:     true,
            expectedErr: ErrInvalidEmail,
        },
        {
            name: "empty name",
            input: models.CreateUserInput{
                Name:  "",
                Email: "jane@example.com",
            },
            wantErr:     true,
            expectedErr: ErrNameRequired,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            mockRepo := mocks.NewUserRepository(t)
            service := NewUserService(mockRepo)

            if !tt.wantErr {
                mockRepo.On("Create", mock.Anything, mock.Anything).
                    Return(&models.User{ID: "1", Name: tt.input.Name, Email: tt.input.Email}, nil)
            }

            result, err := service.CreateUser(context.Background(), tt.input)

            if tt.wantErr {
                assert.Error(t, err)
                if tt.expectedErr != nil {
                    assert.ErrorIs(t, err, tt.expectedErr)
                }
            } else {
                assert.NoError(t, err)
                assert.NotNil(t, result)
            }
        })
    }
}

// Benchmark test
func BenchmarkUserService_GetUser(b *testing.B) {
    mockRepo := mocks.NewUserRepository(b)
    service := NewUserService(mockRepo)
    
    user := &models.User{ID: "1", Name: "John", Email: "john@example.com"}
    mockRepo.On("FindByID", mock.Anything, "1").Return(user, nil)

    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        service.GetUser(context.Background(), "1")
    }
}
```

## Playwright Configuration

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html', { open: 'never' }],
    ['junit', { outputFile: 'reports/e2e-junit.xml' }],
    ['json', { outputFile: 'reports/e2e-results.json' }],
  ],
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
    {
      name: 'Mobile Safari',
      use: { ...devices['iPhone 12'] },
    },
  ],
  webServer: {
    command: 'npm run start',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120000,
  },
});
```

### E2E Test Example

```typescript
// tests/e2e/auth.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Authentication', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('should display login form', async ({ page }) => {
    await expect(page.getByRole('heading', { name: 'Sign In' })).toBeVisible();
    await expect(page.getByLabel('Email')).toBeVisible();
    await expect(page.getByLabel('Password')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Sign In' })).toBeVisible();
  });

  test('should login with valid credentials', async ({ page }) => {
    await page.getByLabel('Email').fill('user@example.com');
    await page.getByLabel('Password').fill('password123');
    await page.getByRole('button', { name: 'Sign In' }).click();

    await expect(page).toHaveURL('/dashboard');
    await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();
  });

  test('should show error for invalid credentials', async ({ page }) => {
    await page.getByLabel('Email').fill('user@example.com');
    await page.getByLabel('Password').fill('wrongpassword');
    await page.getByRole('button', { name: 'Sign In' }).click();

    await expect(page.getByText('Invalid credentials')).toBeVisible();
    await expect(page).toHaveURL('/');
  });

  test('should redirect unauthenticated users', async ({ page }) => {
    await page.goto('/dashboard');
    await expect(page).toHaveURL('/login?redirect=/dashboard');
  });
});

test.describe('User Flow', () => {
  test.use({ storageState: 'tests/e2e/.auth/user.json' });

  test('should create and view a new item', async ({ page }) => {
    await page.goto('/items');
    
    // Create new item
    await page.getByRole('button', { name: 'New Item' }).click();
    await page.getByLabel('Name').fill('Test Item');
    await page.getByLabel('Description').fill('This is a test item');
    await page.getByRole('button', { name: 'Create' }).click();

    // Verify item appears in list
    await expect(page.getByText('Test Item')).toBeVisible();

    // View item details
    await page.getByText('Test Item').click();
    await expect(page.getByRole('heading', { name: 'Test Item' })).toBeVisible();
    await expect(page.getByText('This is a test item')).toBeVisible();
  });
});
```

## Mocking Strategies

### Jest Mocking

```typescript
// Manual mock
jest.mock('../services/externalApi', () => ({
  fetchData: jest.fn().mockResolvedValue({ data: 'mocked' }),
}));

// Spy
const spy = jest.spyOn(service, 'processData');
spy.mockImplementation(() => 'mocked result');

// Mock return values
mockFn.mockReturnValue('sync value');
mockFn.mockResolvedValue('async value');
mockFn.mockRejectedValue(new Error('error'));

// Mock implementation
mockFn.mockImplementation((arg) => arg * 2);
```

### Python Mocking

```python
from unittest.mock import Mock, patch, AsyncMock

# Patch decorator
@patch('mymodule.external_service')
def test_with_mock(mock_service):
    mock_service.fetch.return_value = {'data': 'mocked'}
    # test code

# Async mock
@patch('mymodule.async_service', new_callable=AsyncMock)
async def test_async(mock_service):
    mock_service.fetch.return_value = {'data': 'mocked'}
    # test code

# Context manager
with patch.object(MyClass, 'method', return_value='mocked'):
    # test code
```

## Related Resources

- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [pytest Documentation](https://docs.pytest.org/)
- [Playwright Documentation](https://playwright.dev/docs/intro)
- [Go Testing](https://golang.org/pkg/testing/)
