# ${{ values.name }}

${{ values.description }}

TypeScript API built with [Hono](https://hono.dev/) for Cloudflare Workers{% if values.binding == 'd1' %}, with a D1 database{% elif values.binding == 'kv' %}, with a KV namespace{% endif %}.

## Getting started

Requires Node.js 22 or later.

```bash
npm install
{%- if values.binding == 'd1' %}
npm run db:migrate:local
{%- endif %}
npm run dev
curl http://localhost:8787/health
```

`wrangler dev` runs the Worker locally in the Workers runtime; bindings are
backed by local storage in `.wrangler/`.

## Scripts

- `npm run dev` starts the Worker locally
- `npm test` runs the Vitest tests inside the Workers runtime
- `npm run typecheck` regenerates the `Env` types from `wrangler.jsonc` and type-checks
- `npm run lint` checks linting and formatting with Biome (`npm run format` fixes)
{%- if values.binding == 'd1' %}
- `npm run db:migrate:local` applies `migrations/` to the local database
- `npm run deploy` deploys the Worker, then applies `migrations/` to the remote database
{%- else %}
- `npm run deploy` deploys the Worker
{%- endif %}

## Endpoints

| Method | Path              | Description                              |
| ------ | ----------------- | ---------------------------------------- |
| GET    | `/health`         | Service status and environment           |
| GET    | `/health/live`    | Liveness probe                           |
| GET    | `/health/ready`   | Readiness probe{% if values.binding != 'none' %}: the binding answers{% endif %} |
{%- if values.binding == 'd1' %}
| GET    | `/api/items`      | List items (D1)                          |
| POST   | `/api/items`      | Create an item: `{"name": "..."}`        |
| GET    | `/api/items/:id`  | One item                                 |
{%- elif values.binding == 'kv' %}
| GET    | `/api/items`      | List items (KV)                          |
| POST   | `/api/items`      | Create an item: `{"name": "..."}`        |
| GET    | `/api/items/:id`  | One item                                 |
{%- else %}
| GET    | `/api`            | Welcome message                          |
| POST   | `/api/echo`       | Validated body: `{"message": "..."}`     |
{%- endif %}

## Configuration

`wrangler.jsonc` holds no account identifier, no resource identifier and no
secret.

- Plain values go in `vars` of `wrangler.jsonc` (`APP_ENV` is there).
- Secrets are set with `npx wrangler secret put <NAME>` and never committed.
- Local-only values go in `.dev.vars` (see `.dev.vars.example`), which Git ignores.

Run `npm run types` after changing `wrangler.jsonc` to regenerate the `Env` type.

## Deployment

The pipeline deploys from `main` once the repository has:

| Kind     | Name                    | Value                                                         |
| -------- | ----------------------- | ------------------------------------------------------------- |
| Variable | `CLOUDFLARE_ACCOUNT_ID` | Identifier of the Cloudflare account                          |
| Secret   | `CLOUDFLARE_API_TOKEN`  | Token from the "Edit Cloudflare Workers" template{% if values.binding == 'd1' %} with D1 edit permission{% endif %}, limited to that account |

Until the variable exists the deployment job is skipped.
{%- if values.binding != 'none' %}

The first deployment creates the {% if values.binding == 'd1' %}D1 database{% else %}KV namespace{% endif %}, named after the Worker, and later
deployments reuse it. When you deploy from your machine, Wrangler writes the
identifier of the resource into `wrangler.jsonc`; committing it is safe, it is
not a credential.
{%- endif %}

## Owner

${{ values.owner }}
