# ${{ values.name }}

${{ values.description }}

Next.js 14 application (App Router, TypeScript{% if values.styling == 'tailwind' %}, Tailwind CSS{% else %}, CSS Modules{% endif %}).

## Getting started

```bash
npm install
npm run dev
```

Open <http://localhost:3000>. The health endpoint is at `/api/health`.

## Scripts

- `npm run dev` starts the development server
- `npm run build` builds for production
- `npm run start` serves the production build
- `npm run lint` runs ESLint
- `npm run format:check` checks formatting with Prettier (`npm run format` fixes it)
- `npm test` runs the Jest unit tests
- `npm run test:e2e` runs the Playwright end-to-end tests (`npx playwright install chromium` once)

## Project structure

```
├── src/app/          # App Router pages, layout and API routes
├── src/site.json     # Name, description and environment shown by the app
├── __tests__/        # Jest unit tests
├── e2e/              # Playwright end-to-end tests
├── public/           # Static assets
{%- if values.enableDocker %}
├── Dockerfile        # Production image
├── k8s/              # Kubernetes Deployment and Service
{%- endif %}
└── docs/             # TechDocs shown in the developer portal
```

## Continuous integration

`.github/workflows/nextjs.yaml` lints, tests, builds and runs the end-to-end
tests on every push and pull request to `main`.
{%- if values.enableDocker %}
`.github/workflows/docker.yaml` builds the image, starts it, calls the health
endpoint and, on `main`, publishes it to
`ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}`.
{%- endif %}

## Owner

${{ values.owner }}
