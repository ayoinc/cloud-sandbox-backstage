# ${{ values.name }}

${{ values.description }}

## Overview

This is a Playwright end-to-end testing project configured with:

- **Page Object Model** for maintainable test code
- **Multiple browser support**: {% for browser in values.browsers %}{{ browser }}{% if not loop.last %}, {% endif %}{% endfor %}
- **Parallel execution** with ${{ values.parallelWorkers }} workers
- **CI/CD integration** with GitHub Actions

## Quick Start

```bash
# Install dependencies
npm install

# Install Playwright browsers
npx playwright install

# Run tests
npm test

# Run tests with UI
npm run test:ui

# Run specific browser
npm run test:chromium
npm run test:firefox
npm run test:webkit
```

## Project Structure

```
.
├── tests/               # Test specifications
│   ├── example.spec.ts  # Example test file
│   └── fixtures/        # Test fixtures
├── pages/               # Page Object Models
│   └── BasePage.ts      # Base page class
├── playwright.config.ts # Playwright configuration
└── package.json         # Dependencies
```

## Configuration

- **Base URL**: `${{ values.baseUrl }}`
- **Parallel Workers**: ${{ values.parallelWorkers }}
- **Tracing**: ${{ values.enableTracing }}
- **Screenshots**: ${{ values.enableScreenshots }}

## Reports

Test reports are generated in the `playwright-report/` directory after each test run.

View the HTML report:
```bash
npx playwright show-report
```
