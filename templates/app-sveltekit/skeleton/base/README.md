# ${{ values.name }}

${{ values.description }}

[SvelteKit](https://svelte.dev/docs/kit) app with Svelte 5 runes and TypeScript, built with the {% if values.adapter == 'node' %}Node.js{% elif values.adapter == 'static' %}static{% else %}Cloudflare{% endif %} adapter.

## Getting started

Requires Node.js 24 (see `.nvmrc`).

```bash
npm install
npm run dev
```

## Scripts

- `npm run dev` starts the development server
- `npm run build` builds the app
- `npm run preview` serves the production build on port 4173
- `npm run check` type-checks the project with `svelte-check`
- `npm run lint` runs Prettier and ESLint (`npm run format` fixes formatting)
- `npm run test:unit` runs Vitest: modules in Node.js, components in Chromium
- `npm run test:e2e` builds the app and runs the Playwright tests against it

The browser tests need Chromium once: `npx playwright install chromium`.

## Conventions

- Components and `.svelte.ts` modules use runes (`$props`, `$state`, `$derived`).
- `#lib` resolves to `src/lib` (declared under `imports` in `package.json`);
  imports through it name the file extension: `#lib/todos.svelte.ts`.
- Test files ending in `.svelte.spec.ts` run in the browser; other `.spec.ts`
  files run in Node.js. End-to-end tests are `e2e/*.e2e.ts`.
- SvelteKit's configuration is in `vite.config.ts`.
- The name and description of the app are in `src/lib/site.json`.
{%- if values.server %}

## Server

`src/hooks.server.ts` gives every request an identifier, returns it as
`x-request-id` and logs one JSON line per request. Errors thrown by your code
are logged with their stack; the page shows a safe message and the identifier.

`GET /health` answers `{ "status": "ok", ... }` for probes.
{%- endif %}
{%- if values.adapter == 'node' %}

## Container image

```bash
docker build -t ${{ values.name }} .
docker run --rm -p 3000:3000 ${{ values.name }}
```

The server reads `PORT` (default 3000). Behind a proxy that terminates TLS,
set `ORIGIN` to the public URL, for example `ORIGIN=https://app.your-organisation.org`,
so that form submissions pass the cross-site check.
{%- elif values.adapter == 'static' %}

## Hosting

`npm run build` writes the whole site to `build/`: every page is prerendered
(`src/routes/+layout.ts`) and `404.html` is the page for unknown paths. Upload
the directory to any static host. Pages that need a server at request time
are not possible with this adapter.
{%- else %}

## Deployment

`.github/workflows/deploy.yaml` deploys the Worker from `main` once the
repository has:

| Kind     | Name                    | Value                                                                      |
| -------- | ----------------------- | -------------------------------------------------------------------------- |
| Variable | `CLOUDFLARE_ACCOUNT_ID` | Identifier of the Cloudflare account                                       |
| Secret   | `CLOUDFLARE_API_TOKEN`  | Token from the "Edit Cloudflare Workers" template, limited to that account |

`wrangler.jsonc` holds no account identifier and no secret. Bindings declared
there are available as `event.platform.env`.
{%- endif %}

## Owner

${{ values.owner }}
