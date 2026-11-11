# Next.js Application Template

Creates a Next.js 14 application (App Router, TypeScript) in a new GitHub
repository, with tests and a pipeline that passes on the first push.

## Form

| Field         | Effect                                                                                          |
| ------------- | ----------------------------------------------------------------------------------------------- |
| Project Name  | Name of the application, the package and the catalog entry                                      |
| Description   | Shown on the home page and in the page metadata                                                 |
| Owner         | Owner of the catalog entry                                                                      |
| Environment   | Reported by `/api/health`; lifecycle of the catalog entry                                       |
| Styling       | Tailwind CSS (Tailwind, PostCSS, utility classes) or CSS Modules (plain CSS, no extra packages) |
| Enable Docker | Adds a Dockerfile, Kubernetes manifests and a workflow that builds and publishes the image      |
| Repository    | GitHub repository to create                                                                     |

## What is generated

- `src/app/`: home page, root layout and the `GET /api/health` route
- `__tests__/`: Jest unit tests with React Testing Library
- `e2e/`: Playwright tests that run against the production build
- ESLint (Next.js rules) and Prettier configuration
- `package-lock.json` matching the selected styling option
- `.github/workflows/nextjs.yaml`: lint, unit tests, build, end-to-end tests,
  dependency report
- With Docker: `Dockerfile`, `k8s/`, and `.github/workflows/docker.yaml`, which
  lints the Dockerfile and manifests, builds the image, starts it, calls the
  health endpoint and publishes to the GitHub Container Registry on `main`
- `catalog-info.yaml`, `mkdocs.yml` and `docs/index.md` for the portal

No secret or variable has to be configured: the image is published with the
workflow's own token.

## Template layout

| Directory                      | Used                      |
| ------------------------------ | ------------------------- |
| `skeleton/base`                | Always                    |
| `skeleton/styling-tailwind`    | Styling is Tailwind CSS   |
| `skeleton/styling-css-modules` | Styling is CSS Modules    |
| `skeleton/docker`              | Enable Docker is selected |

Each styling directory holds the `package-lock.json` for its dependency set.
After changing `skeleton/base/package.json`, render the template for both
styling options, run `npm install` in each result and copy the lockfile back
with the package name replaced by `${{ values.name }}`.
