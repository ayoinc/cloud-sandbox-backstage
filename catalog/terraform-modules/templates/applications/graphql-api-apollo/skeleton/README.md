# ${{ values.apiName }}

${{ values.description }}

A GraphQL API built with Apollo Server, TypeScript and ${{ 'PostgreSQL' if values.databaseType == 'postgresql' else ('MySQL' if values.databaseType == 'mysql' else 'SQLite') }}.

## Quick start

You need Node.js 24 (see `.nvmrc`){% if values.databaseType != 'sqlite' or values.enableCache %} and Docker{% endif %}.

```sh
npm ci
cp .env.example .env
{% if values.databaseType != 'sqlite' and values.enableCache %}
docker compose up --detach db redis
{% elif values.databaseType != 'sqlite' %}
docker compose up --detach db
{% elif values.enableCache %}
docker compose up --detach redis
{% endif %}
npm run dev
```

The API listens on <http://localhost:4000/graphql>.{% if values.enablePlayground %} Open that address in a browser for Apollo Sandbox.{% endif %}


```graphql
query {
  products {
    id
    name
    priceCents
  }
}
```
{% if values.enableAuth and values.authProvider == 'jwt' %}

Changing data needs a token. `npm run token` prints one for local use; send it
as the `Authorization: Bearer <token>` header.
{% endif %}

`docker compose up --build` runs the API in its container image together with
what it depends on.

## Scripts

| Script | What it does |
| --- | --- |
| `npm run dev` | Runs the API and restarts it when a file changes. |
| `npm test` | Runs the tests{% if values.databaseType != 'sqlite' %} against the database `DATABASE_URL` points at{% endif %}. |
| `npm run lint` | Runs ESLint. |
| `npm run typecheck` | Checks the types of the source, tests and scripts. |
| `npm run codegen` | Regenerates `src/generated/graphql.ts` from the schema. |
| `npm run build` | Compiles to `dist/`. |
| `npm start` | Runs the compiled API. |
{% if values.enableAuth and values.authProvider == 'jwt' %}
| `npm run token` | Prints a development token. |
{% endif %}

## Pipeline

`.github/workflows/ci.yaml` runs on every push to `main` and on pull requests.
It checks that the generated types match the schema, lints, checks types, runs
the tests{% if values.databaseType != 'sqlite' %} against a real ${{ 'PostgreSQL' if values.databaseType == 'postgresql' else ('MySQL' if values.databaseType == 'mysql' else 'SQLite') }}{% endif %}{% if values.enableCache %}${{ ' and Redis' if values.databaseType != 'sqlite' else ' against a real Redis' }}{% endif %}, builds, and starts the container image to query it.
It needs no secrets.{% if values.enableSchemaRegistry %} The schema registry job runs once `APOLLO_KEY` and
`APOLLO_GRAPH_REF` are configured.{% endif %}


`.github/workflows/release.yaml` publishes the image to
`ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}` when you push a tag such as `v${{ values.apiVersion }}`.

More in [docs/](docs/index.md): the [API](docs/api.md) and
[operations](docs/operations.md).
