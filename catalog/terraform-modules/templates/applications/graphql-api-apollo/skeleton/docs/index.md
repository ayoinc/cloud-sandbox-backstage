# ${{ values.apiName }}

${{ values.description }}

`${{ values.apiName }}` is a GraphQL API built with Apollo Server and TypeScript.
It stores its data in ${{ 'PostgreSQL' if values.databaseType == 'postgresql' else ('MySQL' if values.databaseType == 'mysql' else 'SQLite') }} and serves GraphQL on `/graphql`.

## Features

Every feature below is a switch: the table shows how this API was created, and
each one can be changed per environment with the variable next to it.

| Feature | Default | Variable |
| --- | --- | --- |
| Subscriptions over WebSocket | ${{ 'On' if values.enableSubscriptions else 'Off' }} | `SUBSCRIPTIONS_ENABLED` |
| Query complexity limit | ${{ values.queryComplexity }} | `QUERY_COMPLEXITY_LIMIT` |
| Response cache | ${{ 'On' if values.enableCache else 'Off' }} | `CACHE_ENABLED` |
| Authentication | ${{ 'On' if values.enableAuth else 'Off' }} (${{ 'shared-secret JWT' if values.authProvider == 'jwt' else 'OAuth 2.0 identity provider' }}) | `AUTH_ENABLED`, `AUTH_PROVIDER` |
| Role-based access control | ${{ 'On' if values.enableRBAC else 'Off' }} | `AUTH_RBAC` |
| Prometheus metrics | ${{ 'On' if values.enableMetrics else 'Off' }} | `METRICS_ENABLED` |
| OpenTelemetry tracing | ${{ 'On' if values.enableTracing else 'Off' }} | `TRACING_ENABLED` |
| Apollo Sandbox and introspection in production | ${{ 'On' if values.enablePlayground else 'Off' }} | `PLAYGROUND_ENABLED` |

The defaults live in `src/defaults.ts`.

## Run it

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

The API listens on <http://localhost:4000/graphql>.

## Where things are

| Path | Content |
| --- | --- |
| `src/schema/` | The schema (`*.graphql`) and its resolvers. |
| `src/generated/` | TypeScript types generated from the schema by `npm run codegen`. |
| `src/db/` | Database access with Knex: connection, migrations and the product repository. |
| `src/auth.ts` | Token verification and the guard for resolvers that change data. |
| `src/plugins/` | Apollo Server plugins: query complexity limit and metrics. |
| `src/server.ts` | Puts the HTTP server together. |
| `src/config.ts`, `src/defaults.ts` | Configuration from environment variables, and its defaults. |
| `tests/` | Tests that call the API over HTTP and WebSocket. |

## Where to go next

- [API](api.md): the schema, authentication and how to change it.
- [Operations](operations.md): configuration, pipeline and deployment.
