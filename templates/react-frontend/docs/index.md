# React Frontend Application Template

Creates a React single-page application in a new GitHub repository, with
tests and a pipeline that passes on the first push. The tool chain is fixed:
Vite, TypeScript, Vitest with React Testing Library, and Node.js 22.

## Form

| Field                         | Options                              | Effect                                                                                           |
| ----------------------------- | ------------------------------------ | ------------------------------------------------------------------------------------------------ |
| Application Name              |                                      | Repository, package and catalog entry name; shown in the header                                  |
| Description                   |                                      | Package and catalog description; shown on the home page                                          |
| Owner                         |                                      | Owner of the catalog entry                                                                       |
| Repository Location           | github.com                           | GitHub repository to create                                                                      |
| React Version                 | `18`, `19`                           | Versions of `react`, `react-dom` and their type packages                                         |
| UI Framework                  | `none`, `mui`, `tailwind`            | `Button`, `Layout` and `Section` built with CSS modules, Material UI or Tailwind CSS             |
| State Management              | `context`, `zustand`, `redux`        | Counter state in React Context, a Zustand store or a Redux Toolkit slice                         |
| Routing Library               | `none`, `react-router`               | Single page, or React Router with Home, About and Not Found pages                                |
| API Client                    | `fetch`, `axios`, `react-query`      | Item list loaded with `fetch`, an Axios instance, or TanStack Query                              |
| API Base URL                  | path or absolute URL, default `/api` | Default of `VITE_API_BASE_URL`, stored in `src/app.json`                                         |
| Enable Mock API               | on, off                              | Mock Service Worker handlers used by the tests and, on request, by the development server        |
| Enable Linting and Formatting | on, off                              | Biome, `npm run lint` and the `lint.yaml` workflow                                               |
| Enable Storybook              | on, off                              | Storybook, stories for `Button` and `Section`, and the `storybook.yaml` workflow                 |
| Progressive Web App           | on, off                              | `vite-plugin-pwa`: web app manifest, icons and a service worker in the production build          |
| Enable Web Vitals Reporting   | on, off                              | `web-vitals` measurements sent to the console or to `VITE_VITALS_ENDPOINT`                       |
| Enable Docker                 | on, off                              | nginx image with `/healthz`, and the `docker.yaml` workflow that builds, starts and publishes it |

Every option changes the generated repository; there are no informational
fields.

## What is generated

- `src/`: the application. `main.tsx` mounts `App` inside `AppProviders`;
  `components/` holds `Button`, `Layout`, `Section` and the two example
  features `Counter` (state) and `ItemList` (API); `store/` and `api/` hold
  the implementation chosen in the form
- `tests/`: Vitest tests for the components, the store, the API client, the
  application shell and, when enabled, the Web Vitals reporting. No test
  uses the network: requests are answered by Mock Service Worker, or by a
  stub of `fetch` or of the Axios adapter when the mock API is off
- `package.json` with every dependency pinned to an exact version, `.nvmrc`,
  `tsconfig.json`, `vite.config.ts`
- `.github/workflows/ci.yaml`: type check, tests with coverage, production
  build with a check of its output, and a Trivy dependency report
- Optional: `biome.json` and `lint.yaml`; `.storybook/` and `storybook.yaml`;
  `Dockerfile`, `nginx/default.conf` and `docker.yaml`
- `catalog-info.yaml`, `mkdocs.yml` and `docs/index.md` for the portal

No secret or variable has to be configured. The image is published to the
GitHub Container Registry with the workflow's own token.

## Lockfile

The options change the dependency set, so the template cannot ship a
`package-lock.json`. The workflows and the `Dockerfile` run `npm install`,
which resolves the exact versions in `package.json`. The first `npm install`
on a developer machine creates the lockfile; commit it to pin the transitive
dependencies as well.

## Layout of the template

`template.yaml` fetches `skeleton/base` and then one directory per choice:

| Directory                             | Added when                     |
| ------------------------------------- | ------------------------------ |
| `skeleton/ui-<ui_framework>`          | Always, by UI Framework        |
| `skeleton/state-<state_management>`   | Always, by State Management    |
| `skeleton/routing-<routing>`          | Always, by Routing Library     |
| `skeleton/api-<api_client>`           | Always, by API Client          |
| `skeleton/mock-api`                   | Mock API on                    |
| `skeleton/api-stub-fetch` or `-axios` | Mock API off, by API Client    |
| `skeleton/linting`                    | Linting on                     |
| `skeleton/storybook`                  | Storybook on                   |
| `skeleton/pwa`                        | Progressive Web App on (icons) |
| `skeleton/monitoring`                 | Web Vitals Reporting on        |
| `skeleton/docker`                     | Docker on                      |

Workflow files are copied without templating, so they contain no form values.
