# Hono API on Cloudflare Workers Template

Creates a TypeScript API built with Hono for Cloudflare Workers in a new GitHub
repository, with an optional D1 database or KV namespace, tests that run inside
the Workers runtime and a pipeline that passes on the first push.

## Form

| Field           | Effect                                                                |
| --------------- | --------------------------------------------------------------------- |
| Project Name    | Name of the Worker, the package, the repository and the catalog entry |
| Description     | Package description, README, documentation and catalog entry          |
| Owner           | Owner of the catalog entry                                            |
| Storage Binding | None, a D1 database (`DB`) or a KV namespace (`KV`)                   |
| Repository      | GitHub repository to create                                           |

## What is generated

- `src/`: Hono application, JSON request logging, error handling, `/health`
  and `/api` routes for the selected binding
- `wrangler.jsonc`: Worker configuration without account or resource
  identifiers and without secrets; Wrangler creates the bound resource on the
  first deployment
- `test/`: Vitest tests that run in the Workers runtime with
  `@cloudflare/vitest-plugin`, against a local D1 database or KV namespace
- With D1: `migrations/`, applied to the test database and on deployment
- Biome for linting and formatting, strict TypeScript with generated `Env` types
- `package-lock.json`
- `.github/workflows/ci.yaml`: lint, type check, tests, and deployment once the
  repository is connected to a Cloudflare account
- `.github/dependabot.yml`: weekly updates of packages and actions
- `catalog-info.yaml`, `mkdocs.yml` and `docs/index.md` for the portal

## After creation

The pipeline passes without any setup and skips the deployment. To deploy from
`main`, add to the repository:

| Kind     | Name                    | Value                                                                          |
| -------- | ----------------------- | ------------------------------------------------------------------------------ |
| Variable | `CLOUDFLARE_ACCOUNT_ID` | Identifier of the Cloudflare account                                           |
| Secret   | `CLOUDFLARE_API_TOKEN`  | API token limited to that account, from the "Edit Cloudflare Workers" template |

Cloudflare does not accept GitHub's OIDC tokens, so a scoped API token is the
narrowest credential available. Give it an expiry and rotate it.

## Template layout

| Directory               | Used            |
| ----------------------- | --------------- |
| `skeleton/base`         | Always          |
| `skeleton/binding-none` | Binding is None |
| `skeleton/binding-d1`   | Binding is D1   |
| `skeleton/binding-kv`   | Binding is KV   |
