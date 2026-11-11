# ${{ values.name }}

${{ values.description }}

## Overview

| Setting    | Value                                                                               |
| ---------- | ----------------------------------------------------------------------------------- |
| Service    | `${{ values.name }}`                                                                |
| Owner      | `${{ values.owner }}`                                                               |
| Runtime    | Cloudflare Workers                                                                  |
| Framework  | Hono 4, TypeScript                                                                  |
| Binding    | {% if values.binding == 'd1' %}D1 database `DB`{% elif values.binding == 'kv' %}KV namespace `KV`{% else %}None{% endif %} |
| Repository | <https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}> |

## Project structure

```
${{ values.name }}/
├── .github/
│   ├── dependabot.yml        # Weekly dependency updates
│   └── workflows/ci.yaml     # Lint, type check, tests, deployment
{%- if values.binding == 'd1' %}
├── migrations/               # D1 migrations
{%- endif %}
├── src/
│   ├── index.ts              # Worker entry point
│   ├── app.ts                # Hono application: middleware, health, errors
│   ├── config.ts             # Service name
│   ├── logger.ts             # JSON logs and request logging
│   ├── validation.ts         # Zod validation of JSON bodies
│   └── routes/api.ts         # /api routes
├── test/                     # Vitest tests, run in the Workers runtime
├── wrangler.jsonc            # Worker configuration, without identifiers or secrets
├── vitest.config.ts
├── biome.json                # Lint and format rules
├── catalog-info.yaml         # Catalog entry
└── mkdocs.yml                # TechDocs configuration
```

## Request handling

Every request gets an `X-Request-Id`, is logged as one JSON line with method,
path, status and duration, and receives security headers. Workers Logs is
enabled in `wrangler.jsonc` and indexes the fields of those lines.

Errors are returned as `{ "error": "..." }`. A JSON body that does not match
its Zod schema is answered with `422` and the list of problems; unhandled
errors are logged with their stack and answered with a plain `500`.
{%- if values.binding == 'd1' %}

## Database

The Worker reads and writes the D1 database bound as `DB`. Schema changes are
SQL files in `migrations/`, applied in order:

```bash
npx wrangler d1 migrations create DB <name>   # new migration file
npm run db:migrate:local                      # local database
npm run deploy                                # deploys, then migrates the remote database
```

Because the Worker is deployed before the remote migration runs, write
migrations that the previous and the new version of the code both work with.
The tests apply the same migrations to a local database before they run.
{%- elif values.binding == 'kv' %}

## Storage

Items are stored in the KV namespace bound as `KV`, one key per item, with the
item repeated in the key's metadata so that listing takes a single request.
KV is eventually consistent: a write can take up to a minute to be visible at
other locations. Use D1 or Durable Objects when reads must see the latest
write.
{%- endif %}

## Tests

`@cloudflare/vitest-plugin` runs the tests inside the Workers runtime with the
bindings of `wrangler.jsonc` backed by local resources, so the code under test
uses the same APIs as in production. Storage is shared by the tests of a run.

## Continuous integration

`.github/workflows/ci.yaml` runs on every push to `main` and on demand:

| Job    | What it does                                                             |
| ------ | ------------------------------------------------------------------------ |
| Lint   | Biome and the TypeScript type check                                      |
| Test   | Vitest in the Workers runtime, then a bundle without deployment          |
| Deploy | `npm run deploy`, on `main`, once `CLOUDFLARE_ACCOUNT_ID` is configured  |

Cloudflare does not accept GitHub's OIDC tokens. Use an API token limited to
the account and to Workers{% if values.binding == 'd1' %} and D1{% elif values.binding == 'kv' %} and KV{% endif %}, give it an expiry and rotate it.

## References

- [Hono](https://hono.dev/docs/)
- [Cloudflare Workers](https://developers.cloudflare.com/workers/)
- [Wrangler configuration](https://developers.cloudflare.com/workers/wrangler/configuration/)
- [Testing Workers with Vitest](https://developers.cloudflare.com/workers/testing/vitest-integration/)
