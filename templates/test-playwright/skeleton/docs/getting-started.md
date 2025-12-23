# Getting Started

## Prerequisites

- Node.js 18 or higher
- npm or yarn
- Access to the target application

## Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd ${{ values.name }}
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Install Playwright browsers:
   ```bash
   npx playwright install
   ```

## Running Tests

### Run all tests
```bash
npm test
```

### Run with UI mode (interactive)
```bash
npm run test:ui
```

### Run specific test file
```bash
npx playwright test tests/example.spec.ts
```

### Run tests in headed mode
```bash
npx playwright test --headed
```

### Debug tests
```bash
npx playwright test --debug
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `BASE_URL` | Target application URL | `${{ values.baseUrl }}` |
| `CI` | Running in CI environment | `false` |

## Next Steps

- Read [Writing Tests](writing-tests.md) to learn how to write test cases
- Review [Page Objects](page-objects.md) for maintainable test code
- Check [CI/CD](ci-cd.md) for pipeline integration
