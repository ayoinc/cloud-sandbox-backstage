# Contributing

Thank you for your interest in contributing to ${{ values.name }}!

## Code of Conduct

Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md).

## How to Contribute

### Reporting Issues

1. Check existing issues first
2. Use the issue template
3. Provide detailed information:
   - Steps to reproduce
   - Expected behavior
   - Actual behavior
   - Environment details

### Submitting Changes

1. Fork the repository
2. Create a feature branch:
   ```bash
   git checkout -b feature/my-feature
   ```
3. Make your changes
4. Write/update tests
5. Update documentation
6. Submit a pull request

### Pull Request Guidelines

- Keep changes focused and atomic
- Write clear commit messages
- Include tests for new features
- Update documentation as needed
- Ensure CI passes

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/${{ values.name }}.git
cd ${{ values.name }}

# Install dependencies
npm install

# Run tests
npm test

# Start development server
npm run dev
```

## Coding Standards

### Style Guide

- Use TypeScript
- Follow ESLint rules
- Format with Prettier
- Write meaningful comments

### Commit Messages

Follow conventional commits:

```
type(scope): description

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

## Documentation

- Update docs for new features
- Use clear, concise language
- Include code examples
- Check for broken links

## Getting Help

- Join our Slack channel
- Ask in GitHub Discussions
- Contact maintainers

## Recognition

Contributors are recognized in:

- CONTRIBUTORS.md file
- Release notes
- Project documentation

Thank you for contributing!
