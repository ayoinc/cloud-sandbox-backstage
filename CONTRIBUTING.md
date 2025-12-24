# Contributing to Cloud Sandbox Backstage

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Style](#code-style)
- [Pull Request Process](#pull-request-process)
- [Testing Requirements](#testing-requirements)
- [Commit Messages](#commit-messages)
- [Documentation](#documentation)

## Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to:

- Be respectful and inclusive
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards other community members

## Getting Started

### Prerequisites

- Node.js 22 or 24
- Yarn 4.4.1 (via Corepack)
- Docker and Docker Compose
- Git

### Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR-USERNAME/backstage.git
   cd backstage
   ```
3. Add the upstream remote:
   ```bash
   git remote add upstream https://github.com/ORIGINAL-OWNER/backstage.git
   ```
4. Install dependencies:
   ```bash
   corepack enable
   yarn install
   ```
5. Copy environment configuration:
   ```bash
   cp .env.example .env
   ```

## Development Workflow

### Branch Naming

Use descriptive branch names with prefixes:

- `feature/` - New features (e.g., `feature/add-azure-template`)
- `fix/` - Bug fixes (e.g., `fix/auth-redirect-loop`)
- `docs/` - Documentation updates (e.g., `docs/update-readme`)
- `refactor/` - Code refactoring (e.g., `refactor/branding-plugin`)
- `chore/` - Maintenance tasks (e.g., `chore/update-dependencies`)

### Development Commands

```bash
# Start development server
yarn start

# Run TypeScript compiler (check for errors)
yarn tsc

# Run tests
yarn test

# Run linting
yarn lint:all

# Format code
yarn prettier:check

# Build for production
yarn build:backend
```

### Working with Docker

```bash
# Start infrastructure services
docker compose -f docker-compose.services.yaml up -d

# Start full stack
docker compose up -d

# View logs
docker compose logs -f

# Rebuild after changes
docker compose build backstage
```

## Code Style

### TypeScript

- Use TypeScript for all new code
- Enable strict mode
- Avoid `any` types when possible
- Use explicit return types for functions

### Formatting

This project uses Prettier for code formatting:

```bash
# Check formatting
yarn prettier:check

# Fix formatting
npx prettier --write .
```

### Linting

ESLint is configured with the Backstage preset:

```bash
# Run linting
yarn lint:all

# Lint with auto-fix
yarn lint:all --fix
```

### File Organization

```
packages/backend/src/
├── index.ts              # Entry point
├── pluginName.ts         # Single-file plugins
└── pluginName/           # Multi-file plugins
    ├── index.ts          # Plugin export
    ├── types.ts          # TypeScript interfaces
    ├── routes.ts         # Express routes
    ├── database.ts       # Database operations
    └── storage.ts        # External storage
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Files | camelCase | `brandingSettings.ts` |
| Classes | PascalCase | `GitHubOrgPermissionPolicy` |
| Functions | camelCase | `getCurrentSettings` |
| Constants | SCREAMING_SNAKE_CASE | `DEFAULT_SETTINGS` |
| Interfaces | PascalCase | `BrandingSettings` |

## Pull Request Process

### Before Submitting

1. Sync with upstream:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```
2. Ensure all tests pass: `yarn test`
3. Ensure linting passes: `yarn lint:all`
4. Ensure TypeScript compiles: `yarn tsc`
5. Update documentation if needed

### PR Template

When creating a pull request, include:

```markdown
## Summary
Brief description of the changes.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
Describe how you tested the changes.

## Checklist
- [ ] TypeScript compiles without errors
- [ ] All tests pass
- [ ] Linting passes
- [ ] Documentation updated (if applicable)
```

### Review Process

1. At least one maintainer must approve the PR
2. All CI checks must pass
3. Conflicts must be resolved
4. Changes must be squashed into logical commits

## Testing Requirements

### Unit Tests

- Write tests for new functionality
- Place tests in `__tests__` directories or `.test.ts` files
- Aim for meaningful coverage, not just line coverage

```typescript
// packages/backend/src/__tests__/example.test.ts
describe('ExampleFunction', () => {
  it('should handle normal input', () => {
    expect(exampleFunction('input')).toBe('expected');
  });

  it('should handle edge cases', () => {
    expect(exampleFunction('')).toBe('default');
  });
});
```

### Running Tests

```bash
# Run all tests
yarn test

# Run tests with coverage
yarn test:all

# Run specific test file
yarn test packages/backend/src/__tests__/example.test.ts

# Run tests in watch mode
yarn test --watch
```

### E2E Tests

For end-to-end tests using Playwright:

```bash
# Run all E2E tests
yarn test:e2e

# Run with UI
yarn test:e2e:ui
```

## Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types

- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation only
- `style` - Formatting, no code change
- `refactor` - Code change that neither fixes a bug nor adds a feature
- `test` - Adding or updating tests
- `chore` - Maintenance tasks

### Examples

```
feat(branding): add primary color customization

fix(auth): resolve redirect loop on token refresh

docs(readme): add Docker deployment instructions

refactor(permission): implement catalog-based group lookup
```

## Documentation

### Updating Documentation

- Update README.md for user-facing changes
- Update ARCHITECTURE.md for structural changes
- Add inline comments for complex logic
- Update .env.example for new environment variables

### Template Documentation

When adding new scaffolder templates:

1. Add a description in `template.yaml`
2. Include a README in the skeleton
3. Add the template to the appropriate section in the catalog

### API Documentation

For new API endpoints:

1. Add JSDoc comments to route handlers
2. Document request/response formats
3. Include error responses

```typescript
/**
 * Get current branding settings
 * 
 * @route GET /api/branding-settings
 * @returns {BrandingSettings} Current branding configuration
 */
router.get('/', async (_req, res) => {
  // ...
});
```

## Questions?

If you have questions about contributing, please:

1. Check existing issues and PRs
2. Open a new issue with the `question` label
3. Join the community discussions

Thank you for contributing!
