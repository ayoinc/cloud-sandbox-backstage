# ${{ values.name }}

${{ values.description }}

## Overview

| Setting     | Value                                                                               |
| ----------- | ----------------------------------------------------------------------------------- |
| Application | `${{ values.name }}`                                                                |
| Owner       | `${{ values.owner }}`                                                               |
| Stack       | React ${{ values.react_version }}, TypeScript, Vite                                 |
| UI          | {% if values.ui_framework == 'mui' %}Material UI 9{% elif values.ui_framework == 'tailwind' %}Tailwind CSS 4{% else %}CSS modules{% endif %}                                                                          |
| State       | {% if values.state_management == 'zustand' %}Zustand 5{% elif values.state_management == 'redux' %}Redux Toolkit 2{% else %}React Context{% endif %}                                                                       |
| Routing     | {% if values.routing == 'react-router' %}React Router 7{% else %}None (single page){% endif %}                                                                     |
| API client  | {% if values.api_client == 'axios' %}Axios{% elif values.api_client == 'react-query' %}TanStack Query 5 over `fetch`{% else %}`fetch`{% endif %}, base URL `${{ values.api_base_url }}`                                  |
| Tests       | Vitest, React Testing Library{% if values.enable_mock_api %}, Mock Service Worker{% endif %} |
| Node.js     | 22 (see `.nvmrc`)                                                                   |
| Repository  | <https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}> |

```d2
direction: right

browser: Browser {
  shape: oval
}

app: ${{ values.name }} {
  entry: "main.tsx\nAppProviders"
  shell: "App\n{% if values.routing == 'react-router' %}Home, About, Not Found{% else %}Home{% endif %}"
  store: "store/counter\n{% if values.state_management == 'zustand' %}Zustand{% elif values.state_management == 'redux' %}Redux Toolkit{% else %}React Context{% endif %}"
  api: "api/client\n{% if values.api_client == 'axios' %}Axios{% elif values.api_client == 'react-query' %}TanStack Query{% else %}fetch{% endif %}"
  entry -> shell
  shell -> store: Counter
  shell -> api: ItemList
}

backend: "Backend API\n${{ values.api_base_url }}" {
  shape: cylinder
}

browser -> app.entry: loads the bundle
app.api -> backend: GET /items
```

## Project structure

```
${{ values.name }}/
├── .github/workflows/
{%- if values.enable_docker %}
│   ├── docker.yaml           # Image build, smoke test and publish
{%- endif %}
{%- if values.enable_linting %}
│   ├── lint.yaml             # Biome
{%- endif %}
{%- if values.enable_storybook %}
│   ├── storybook.yaml        # Storybook build
{%- endif %}
│   └── ci.yaml               # Type check, tests, build, dependency scan
{%- if values.enable_storybook %}
├── .storybook/               # Storybook configuration
{%- endif %}
├── docs/index.md             # This page
{%- if values.enable_docker %}
├── nginx/default.conf        # nginx server block used by the image
{%- endif %}
├── public/                   # Files copied to the build as they are
├── src/
│   ├── main.tsx              # Entry point: mounts the application
{%- if values.routing == 'react-router' %}
│   ├── App.tsx               # Layout, navigation and routes
{%- else %}
│   ├── App.tsx               # Layout and home page
{%- endif %}
│   ├── AppProviders.tsx      # Strict mode and the providers of the application
│   ├── app.json              # Name, description and default API base URL
│   ├── config.ts             # API base URL in effect
{%- if values.ui_framework == 'mui' %}
│   ├── theme.ts              # Material UI theme
{%- endif %}
{%- if values.api_client == 'react-query' %}
│   ├── api/                  # client.ts, useItems.ts, queryClient.ts, types.ts
{%- else %}
│   ├── api/                  # client.ts, useItems.ts, types.ts
{%- endif %}
{%- if values.enable_storybook %}
│   ├── components/           # Button, Layout, Section, Counter, ItemList, stories
{%- else %}
│   ├── components/           # Button, Layout, Section, Counter, ItemList
{%- endif %}
{%- if values.enable_mock_api %}
│   ├── mocks/                # Mock Service Worker handlers and browser worker
{%- endif %}
{%- if values.enable_monitoring %}
│   ├── monitoring/           # Web Vitals reporting
{%- endif %}
{%- if values.routing == 'react-router' %}
│   ├── pages/                # Home, About, NotFound
{%- else %}
│   ├── pages/                # Home
{%- endif %}
{%- if values.ui_framework == 'mui' %}
│   └── store/                # Counter state
{%- else %}
│   ├── store/                # Counter state
│   └── styles/index.css      # Global styles
{%- endif %}
├── tests/                    # Vitest tests; support/ holds the shared helpers
{%- if values.enable_docker %}
├── Dockerfile
{%- endif %}
{%- if values.enable_linting %}
├── biome.json                # Biome configuration
{%- endif %}
├── catalog-info.yaml         # Backstage catalog entry
├── index.html                # HTML page that loads src/main.tsx
├── mkdocs.yml                # TechDocs configuration
├── package.json
├── tsconfig.json
└── vite.config.ts            # Vite and Vitest configuration
```

## Local development

Requires Node.js 22 and npm.

```bash
git clone https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}.git
cd ${{ values.destination.repo }}
npm install
npm run dev
```

The development server listens on <http://localhost:5173>.

| Command                   | Purpose                                              |
| ------------------------- | ---------------------------------------------------- |
| `npm run dev`             | Development server with hot module replacement       |
| `npm run build`           | Production build in `dist/`                          |
| `npm run preview`         | Serve the production build locally                   |
| `npm run typecheck`       | Type-check sources, tests and configuration          |
{%- if values.enable_linting %}
| `npm run lint`            | Biome: lint rules, formatting and import order       |
| `npm run lint:fix`        | Apply Biome's safe fixes and formatting              |
{%- endif %}
| `npm test`                | Vitest, single run                                   |
| `npm run test:watch`      | Vitest in watch mode                                 |
| `npm run test:coverage`   | Vitest with a coverage report in `coverage/`         |
{%- if values.enable_storybook %}
| `npm run storybook`       | Storybook on <http://localhost:6006>                 |
| `npm run build-storybook` | Static Storybook in `storybook-static/`              |
{%- endif %}

### Dependencies

Every dependency in `package.json` is pinned to an exact version. The
repository starts without a lockfile: the first `npm install` creates
`package-lock.json`. Commit that file so that every later install
{%- if values.enable_docker %}, in the
pipeline and in the image build,
{%- else %} in the
pipeline
{%- endif %} resolves the same transitive versions.

## Configuration

Vite reads variables from `.env` files and exposes those that start with
`VITE_` to the application. Copy `.env.example` to `.env.local` for local
overrides; `.env.local` is ignored by Git.

| Variable               | Default                      | Purpose                                                      |
| ---------------------- | ---------------------------- | ------------------------------------------------------------ |
| `VITE_API_BASE_URL`    | `${{ values.api_base_url }}` | Base URL of the backend API, compiled into the bundle        |
{%- if values.enable_mock_api %}
| `VITE_ENABLE_MOCK_API` | `false`                      | `true` answers API requests in the development server with the mock handlers |
{%- endif %}
{%- if values.enable_monitoring %}
| `VITE_VITALS_ENDPOINT` | empty                        | URL that receives Web Vitals measurements; empty logs them to the console |
{%- endif %}

The default API base URL is stored in `src/app.json` together with the name
and description shown in the application.

## Application

### Components

`src/components/` holds three building blocks,
{%- if values.ui_framework == 'mui' %} built on Material UI and styled by the theme in `src/theme.ts`:
{%- elif values.ui_framework == 'tailwind' %} styled with Tailwind CSS utility classes (`src/styles/index.css` imports Tailwind):
{%- else %} each styled by a CSS module next to it (`src/styles/index.css` holds the global styles):
{%- endif %}

| Component | Purpose                                                       |
| --------- | ------------------------------------------------------------- |
| `Button`  | Button with a `primary` and a `secondary` variant             |
| `Layout`  | Header with the application name and navigation, page content |
| `Section` | Titled block of a page                                        |

`Counter` and `ItemList` are the two example features built with them.

### State

{%- if values.state_management == 'zustand' %}

`src/store/counter.ts` creates a Zustand store. `useCounter()` returns the
count and the `increment`, `decrement` and `reset` actions; pass a selector to
subscribe to a single value.
{%- elif values.state_management == 'redux' %}

`src/store/counterSlice.ts` defines the counter slice with Redux Toolkit,
`src/store/store.ts` creates the store and its types, and `useCounter()` in
`src/store/counter.ts` gives components the count and the `increment`,
`decrement` and `reset` actions. `AppProviders` creates the store and provides
it to the application.
{%- else %}

`src/store/counter.tsx` keeps the count in a reducer and shares it through
React Context. `CounterProvider` is mounted by `AppProviders`; `useCounter()`
returns the count and the `increment`, `decrement` and `reset` actions.
{%- endif %}
{%- if values.routing == 'react-router' %}

### Routing

`src/main.tsx` creates a `BrowserRouter` and `src/App.tsx` declares the routes:

| Path     | Page                     |
| -------- | ------------------------ |
| `/`      | `src/pages/Home.tsx`     |
| `/about` | `src/pages/About.tsx`    |
| other    | `src/pages/NotFound.tsx` |

The host that serves the build must answer unknown paths with `index.html`
so that a page reload on `/about` still loads the application.
{%- if values.enable_docker %} The nginx configuration of the image does this.
{%- endif %}
{%- endif %}

### API client

`src/api/client.ts` calls the backend with {% if values.api_client == 'axios' %}an Axios instance{% else %}`fetch`{% endif %} and exposes
`listItems()`, which requests `GET ${{ values.api_base_url }}/items` and
expects a JSON array of `{ "id": string, "name": string }`. A response with a
status outside 2xx is thrown as `ApiError` with the status code.
{%- if values.api_client == 'react-query' %}
`useItems()` in `src/api/useItems.ts` wraps the call in a query with the key
`["items"]`; `src/api/queryClient.ts` sets the cache defaults.
{%- else %}
`useItems()` in `src/api/useItems.ts` loads the items when a component mounts
and cancels the request when it unmounts.
{%- endif %}
{%- if values.enable_mock_api %}

### Mock API

`src/mocks/handlers.ts` defines Mock Service Worker handlers for the API. The
tests use them through `tests/support/server.ts`, so no test needs a backend.
To use the same handlers in the browser, start the development server with
`VITE_ENABLE_MOCK_API=true`; the worker script is served by the `msw` Vite
plugin and is not part of the production build.
{%- endif %}
{%- if values.enable_monitoring %}

### Web Vitals

`src/monitoring/webVitals.ts` measures CLS, INP, LCP, FCP and TTFB with the
`web-vitals` library. Measurements are written to the browser console, or
posted as JSON with `navigator.sendBeacon` to the URL in
`VITE_VITALS_ENDPOINT` when that variable is set at build time.
{%- endif %}
{%- if values.enable_pwa %}

### Progressive web app

`vite-plugin-pwa` is configured in `vite.config.ts`. A production build emits
`dist/manifest.webmanifest` and the service worker `dist/sw.js`, which
precaches the build output and replaces itself when a new version is deployed.
The icons `public/pwa-192x192.png` and `public/pwa-512x512.png` are
placeholders to replace with the real application icon. The service worker is
not registered by the development server.
{%- endif %}
{%- if values.enable_linting %}

### Linting

`biome.json` configures Biome, which lints and formats the TypeScript, CSS,
JSON, HTML and workflow files and keeps imports sorted. `docs/`, `README.md`,
`catalog-info.yaml` and `mkdocs.yml` are excluded: the portal wrote them with
the text entered in its form, and Biome would require its own table widths
and quoting style for that text.
{%- endif %}

## Testing

Tests live in `tests/` and run in jsdom with Vitest and React Testing Library.
`tests/support/render.tsx` renders a component inside `AppProviders`, and
{%- if values.enable_mock_api %}
`tests/support/api.ts` starts the Mock Service Worker server and lets a test
replace the response of `GET /items`. A request without a handler fails the
test, so no test reaches the network.
{%- elif values.api_client == 'axios' %}
`tests/support/api.ts` replaces the adapter of the Axios instance, so no test
reaches the network, and lets a test choose the response of `GET /items`.
{%- else %}
`tests/support/api.ts` replaces `fetch`, so no test reaches the network, and
lets a test choose the response of `GET /items`.
{%- endif %}

## Continuous integration

`.github/workflows/ci.yaml` runs on every push and pull request to `main`:

| Job                 | What it does                                                             |
| ------------------- | ------------------------------------------------------------------------ |
| Type check and test | `tsc --noEmit`, then Vitest with coverage                                |
| Build               | Production build, checks the output, serves it and requests the page     |
| Dependency scan     | Trivy report of known vulnerabilities in `package-lock.json`             |

The dependency scan reports and does not fail the build. It has nothing to
report until `package-lock.json` is committed. In a public repository its
results also appear in the repository's Security tab.
{%- if values.enable_linting or values.enable_storybook or values.enable_docker %}

These workflows run on the same events:

| Workflow         | What it does                                                                   |
| ---------------- | ------------------------------------------------------------------------------ |
{%- if values.enable_linting %}
| `lint.yaml`      | Biome check: lint rules, formatting and import order                           |
{%- endif %}
{%- if values.enable_storybook %}
| `storybook.yaml` | Builds the static Storybook and uploads it as an artifact                      |
{%- endif %}
{%- if values.enable_docker %}
| `docker.yaml`    | Hadolint, image build, container start with calls to `/healthz` and the page, Trivy image report |
{%- endif %}
{%- endif %}
{%- if values.enable_docker %}

On pushes to `main` the image is published to the GitHub Container Registry
with the workflow's own token; no secret has to be configured.

## Docker

The `Dockerfile` builds the bundle with Node.js 22 and copies it into an
unprivileged nginx image that runs as user `101` and listens on port `8080`.

```bash
docker build -t ${{ values.name }} .
docker run --rm -p 8080:8080 ${{ values.name }}
curl http://localhost:8080/healthz
```

`nginx/default.conf` answers `/healthz` for health checks, serves the hashed
files under `/assets/` with a one-year cache lifetime and answers every other
unknown path with `index.html`. Pass
`--build-arg VITE_API_BASE_URL=https://api.example.com` to compile a different
API base URL into the image.
{%- endif %}
