# ${{ values.name }}

${{ values.description }}

## Tech Stack

- **Framework**: React 19
- **Build Tool**: Vite 6
- **Language**: TypeScript 5.7
- **Package Manager**: pnpm 9
- **Linting/Formatting**: Biome 1.9+
- **Testing**: Vitest 2.1+ with React Testing Library
{%- if values.ui_framework != 'none' %}
- **UI Framework**: ${{ values.ui_framework | title }}
{%- endif %}
{%- if values.state_management != 'context' %}
- **State Management**: ${{ values.state_management | title }}
{%- endif %}
{%- if values.api_client != 'fetch' %}
- **API Client**: ${{ values.api_client | title }}
{%- endif %}

## Getting Started

### Prerequisites

- Node.js 22 LTS
- pnpm 9+

### Installation

```bash
# Install dependencies
pnpm install

# Start development server
pnpm dev
```

### Available Scripts

| Command | Description |
|---------|-------------|
| `pnpm dev` | Start development server at http://localhost:5173 |
| `pnpm build` | Build for production |
| `pnpm preview` | Preview production build |
| `pnpm test` | Run tests |
| `pnpm test:coverage` | Run tests with coverage |
| `pnpm lint` | Run Biome linter |
| `pnpm format` | Format code with Biome |
| `pnpm type-check` | Run TypeScript type checking |
{%- if values.enable_storybook %}
| `pnpm storybook` | Start Storybook at http://localhost:6006 |
| `pnpm build-storybook` | Build Storybook for deployment |
{%- endif %}

## Project Structure

```
${{ values.name }}/
├── src/
│   ├── components/     # Reusable UI components
│   ├── hooks/          # Custom React hooks
│   ├── pages/          # Page components
│   ├── services/       # API client and services
│   ├── styles/         # Global styles and theme
│   ├── App.tsx         # Main application component
│   └── main.tsx        # Application entry point
├── tests/              # Test files
│   ├── mocks/          # MSW mock handlers
│   ├── setup.ts        # Test setup configuration
│   └── *.test.tsx      # Test files
├── public/             # Static assets
├── docker/             # Docker configuration
├── .github/            # GitHub Actions workflows
├── biome.json          # Biome configuration
├── vite.config.ts      # Vite configuration
├── tsconfig.json       # TypeScript configuration
└── package.json        # Project dependencies
```

## Development

### Code Style

This project uses [Biome](https://biomejs.dev/) for linting and formatting. It replaces ESLint and Prettier with a single, faster tool.

```bash
# Check for issues
pnpm lint

# Fix auto-fixable issues
pnpm lint:fix

# Format code
pnpm format
```

### Testing

Tests are written using [Vitest](https://vitest.dev/) and [React Testing Library](https://testing-library.com/react).

```bash
# Run tests
pnpm test

# Run tests in watch mode
pnpm test:watch

# Generate coverage report
pnpm test:coverage
```

{%- if values.enable_mock_api %}

### API Mocking

This project uses [MSW (Mock Service Worker)](https://mswjs.io/) for API mocking during development and testing.

Mock handlers are defined in `tests/mocks/handlers.ts`.
{%- endif %}

## Docker

### Development

```bash
# Start development environment
docker compose up app

# Start with hot reload
docker compose up --build
```

### Production

```bash
# Build and run production image
docker compose --profile preview up preview

# Or build manually
docker build --target production -t ${{ values.name }}:latest .
docker run -p 8080:8080 ${{ values.name }}:latest
```

## Deployment

{%- if values.deployment_target == 'static' %}
### Static Hosting (Vercel/Netlify)

1. Connect your repository to Vercel/Netlify
2. Set build command: `pnpm build`
3. Set output directory: `dist`
4. Deploy!
{%- elif values.deployment_target == 'docker' %}
### Docker

The Dockerfile includes a multi-stage build:
- `deps`: Install dependencies
- `builder`: Build the application
- `production`: nginx-based production image
- `development`: Development server

```bash
docker build --target production -t ${{ values.name }}:latest .
docker run -p 8080:8080 ${{ values.name }}:latest
```
{%- elif values.deployment_target == 'kubernetes' %}
### Kubernetes

```bash
# Build and push image
docker build --target production -t registry.example.com/${{ values.name }}:latest .
docker push registry.example.com/${{ values.name }}:latest

# Deploy to Kubernetes
kubectl apply -f k8s/
```
{%- endif %}

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `VITE_API_URL` | Backend API base URL | `/api` |
| `VITE_APP_ENV` | Application environment | `development` |

## Contributing

1. Create a feature branch from `main`
2. Make your changes
3. Run tests: `pnpm test`
4. Run linting: `pnpm lint`
5. Submit a pull request

## License

This project is licensed under the MIT License.
