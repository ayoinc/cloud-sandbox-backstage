# SvelteKit App Template

Creates a SvelteKit 3 app with Svelte 5 runes and TypeScript in a new GitHub
repository, with unit, component and end-to-end tests, the adapter for the
selected host and a pipeline that passes on the first push.

## Form

| Field        | Effect                                                             |
| ------------ | ------------------------------------------------------------------ |
| Project Name | Name of the app, the package, the repository and the catalog entry |
| Description  | Page description, package description, README and catalog entry    |
| Owner        | Owner of the catalog entry                                         |
| Adapter      | Node.js server, static site, or Cloudflare Workers                 |
| Repository   | GitHub repository to create                                        |

## What is generated

- `src/routes/`: layout and home page written with runes (`$props`, `$state`,
  `$derived`)
- `src/lib/`: a reactive class in a `.svelte.ts` module and a component using it
- Vitest in two projects: plain modules in Node.js, components in a real
  browser; Playwright for end-to-end tests against the production build
- ESLint, Prettier and `svelte-check` with strict TypeScript
- `package-lock.json` matching the selected adapter
- `.github/workflows/ci.yaml`: lint, type check, unit and component tests,
  build and end-to-end tests
- `.github/dependabot.yml`: weekly updates of packages and actions
- `catalog-info.yaml`, `mkdocs.yml` and `docs/index.md` for the portal

Depending on the adapter:

| Adapter    | Adds                                                                                                                                                          |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Node.js    | `/health` endpoint, JSON request logs, `Dockerfile` and a workflow publishing the image to the GitHub Container Registry                                      |
| Static     | Prerendering of every page; the build output in `build/` can be hosted anywhere                                                                               |
| Cloudflare | `/health` endpoint, JSON request logs, `wrangler.jsonc` and a deployment workflow, skipped until the repository has the Cloudflare account variable and token |

## Template layout

| Directory                     | Used                             |
| ----------------------------- | -------------------------------- |
| `skeleton/base`               | Always                           |
| `skeleton/adapter-node`       | Adapter is Node.js               |
| `skeleton/adapter-static`     | Adapter is Static                |
| `skeleton/adapter-cloudflare` | Adapter is Cloudflare            |
| `skeleton/server`             | Adapter is Node.js or Cloudflare |

Svelte files are copied without templating, because Svelte's `{#if}` blocks
look like template comments to the scaffolder. Values from the form reach the
app through `src/lib/site.json`.
