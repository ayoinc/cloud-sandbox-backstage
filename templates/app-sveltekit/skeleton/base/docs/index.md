# ${{ values.name }}

${{ values.description }}

## Overview

| Setting    | Value                                                                               |
| ---------- | ----------------------------------------------------------------------------------- |
| App        | `${{ values.name }}`                                                                |
| Owner      | `${{ values.owner }}`                                                               |
| Framework  | SvelteKit 3, Svelte 5 (runes), TypeScript                                           |
| Adapter    | {% if values.adapter == 'node' %}Node.js server{% elif values.adapter == 'static' %}Static site{% else %}Cloudflare Workers{% endif %} |
| Repository | <https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}> |

## Project structure

```
${{ values.name }}/
├── .github/
│   ├── dependabot.yml        # Weekly dependency updates
│   └── workflows/            # ci.yaml{% if values.adapter == 'node' %}, docker.yaml{% elif values.adapter == 'cloudflare' %}, deploy.yaml{% endif %}
├── e2e/                      # Playwright tests against the production build
├── src/
│   ├── app.html              # HTML shell
│   ├── app.css               # Global styles and design tokens
│   ├── app.d.ts              # App-wide types
{%- if values.server %}
│   ├── hooks.server.ts       # Request identifier, request log, error log
{%- endif %}
│   ├── lib/
│   │   ├── components/       # Components and their browser tests
│   │   ├── todos.svelte.ts   # Reactive class written with runes
{%- if values.server %}
│   │   ├── server/logger.ts  # JSON logs; server-only
{%- endif %}
│   │   └── site.json         # Name and description of the app
│   └── routes/               # Pages{% if values.server %} and the /health endpoint{% endif %}
├── static/                   # Files served as they are
├── vite.config.ts            # SvelteKit, adapter and Vitest configuration
├── playwright.config.ts
├── eslint.config.js
{%- if values.adapter == 'node' %}
├── Dockerfile
{%- elif values.adapter == 'cloudflare' %}
├── wrangler.jsonc            # Worker configuration, without identifiers or secrets
{%- endif %}
├── catalog-info.yaml         # Catalog entry
└── mkdocs.yml                # TechDocs configuration
```

## Tests

| Kind       | Files                    | Runs in                             |
| ---------- | ------------------------ | ----------------------------------- |
| Unit       | `src/**/*.spec.ts`       | Node.js (Vitest)                    |
| Component  | `src/**/*.svelte.spec.ts`| Chromium (Vitest browser mode)      |
| End-to-end | `e2e/*.e2e.ts`           | Chromium against `vite preview`     |

Every Vitest test must make at least one assertion (`requireAssertions`).

## Continuous integration

`.github/workflows/ci.yaml` runs on every push to `main` and on demand:

| Job  | What it does                                                          |
| ---- | --------------------------------------------------------------------- |
| Lint | Prettier, ESLint and `svelte-check`                                   |
| Test | Unit and component tests, then a build and the end-to-end tests       |
{%- if values.adapter == 'node' %}

`.github/workflows/docker.yaml` lints the `Dockerfile`, builds the image,
starts it, calls `/health`, reports known vulnerabilities and publishes to the
GitHub Container Registry with the workflow's own token:

```
ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:latest
ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:sha-<commit>
```

The image contains the bundled server only and runs as the unprivileged `node`
user.
{%- elif values.adapter == 'cloudflare' %}

`.github/workflows/deploy.yaml` builds and deploys the Worker from `main`. It
is skipped until the repository variable `CLOUDFLARE_ACCOUNT_ID` and the secret
`CLOUDFLARE_API_TOKEN` exist. Cloudflare does not accept GitHub's OIDC tokens:
limit the token to the account and to Workers, give it an expiry and rotate it.
{%- endif %}

## References

- [SvelteKit](https://svelte.dev/docs/kit)
- [Svelte runes](https://svelte.dev/docs/svelte/what-are-runes)
- [Vitest browser mode](https://vitest.dev/guide/browser/)
- [Playwright](https://playwright.dev/docs/intro)
