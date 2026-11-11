# Operations

## Configuration

The API is configured with environment variables. The defaults of the feature
switches were chosen when the API was created and live in `src/defaults.ts`.

| Variable | Default | Meaning |
| --- | --- | --- |
| `PORT` | `4000` | Port the HTTP server listens on. |
{% if values.databaseType == 'postgresql' %}
| `DATABASE_URL` | `postgres://app:app@localhost:5432/app` | PostgreSQL connection string. |
{% elif values.databaseType == 'mysql' %}
| `DATABASE_URL` | `mysql://app:app@localhost:3306/app` | MySQL connection string. |
{% else %}
| `DATABASE_URL` | `./data/app.db` | Path of the SQLite database file. |
{% endif %}
| `SUBSCRIPTIONS_ENABLED` | `${{ 'true' if values.enableSubscriptions else 'false' }}` | Serve subscriptions over WebSocket. |
| `QUERY_COMPLEXITY_LIMIT` | `${{ values.queryComplexity }}` | Highest cost an operation may have. |
| `CACHE_ENABLED` | `${{ 'true' if values.enableCache else 'false' }}` | Cache query responses. |
| `CACHE_TTL_SECONDS` | `30` | How long a cached response is reused. |
| `REDIS_URL` | | Redis that holds the cache. Without it each process caches in memory. |
| `AUTH_ENABLED` | `${{ 'true' if values.enableAuth else 'false' }}` | Require a token for mutations. |
| `AUTH_PROVIDER` | `${{ values.authProvider }}` | `jwt` (shared secret) or `oauth2` (identity provider). |
| `AUTH_RBAC` | `${{ 'true' if values.enableRBAC else 'false' }}` | Require the `admin` role for mutations. |
| `AUTH_ROLES_CLAIM` | `roles` | Token claim that lists the roles. |
| `JWT_SECRET` | | Secret of the HS256 tokens. Required for the `jwt` provider. |
| `AUTH_ISSUER` | | Issuer the tokens must come from. Required for the `oauth2` provider. |
| `AUTH_AUDIENCE` | | Audience the tokens must be for. |
| `AUTH_JWKS_URI` | `<issuer>/.well-known/jwks.json` | Where the identity provider publishes its signing keys. |
| `METRICS_ENABLED` | `${{ 'true' if values.enableMetrics else 'false' }}` | Serve Prometheus metrics on `/metrics`. |
| `TRACING_ENABLED` | `${{ 'true' if values.enableTracing else 'false' }}` | Trace requests with OpenTelemetry. |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | | OTLP/HTTP collector, for example `http://otel-collector:4318`. Tracing stays off without it. |
| `PLAYGROUND_ENABLED` | `${{ 'true' if values.enablePlayground else 'false' }}` | Serve Apollo Sandbox on `/graphql` and allow introspection in production. |

The API refuses to start with an invalid configuration, for example with
authentication on and no `JWT_SECRET`.

## Endpoints

| Path | Purpose |
| --- | --- |
| `/graphql` | GraphQL over HTTP and WebSocket. |
| `/healthz` | Liveness: the process is up. |
| `/readyz` | Readiness: the database answers. |
| `/metrics` | Prometheus metrics, while `METRICS_ENABLED` is `true`. |

## Observability

`/metrics` serves the Node.js process metrics and the histogram
`graphql_request_duration_seconds`, labelled with the operation name, the
operation type and whether it failed.

With tracing on and a collector configured, every HTTP request and GraphQL
operation produces OpenTelemetry spans. `OTEL_SERVICE_NAME` sets the service
name (`${{ values.apiName }}` by default), and the other `OTEL_EXPORTER_OTLP_*`
variables apply.

## Pipeline

`.github/workflows/ci.yaml` runs on every push to `main` and on pull requests:

| Job | What it checks |
| --- | --- |
| Lint, test and build | Generated types match the schema, ESLint, TypeScript, the tests{% if values.databaseType != 'sqlite' %} against a ${{ 'PostgreSQL' if values.databaseType == 'postgresql' else ('MySQL' if values.databaseType == 'mysql' else 'SQLite') }} service{% endif %}{% if values.enableCache %}${{ ' and Redis' if values.databaseType != 'sqlite' else ' against a Redis service' }}{% endif %}, the build. |
| Build and smoke-test the image | Builds the image, starts it with `docker compose` and queries it. |
{% if values.enableSchemaRegistry %}
| Schema registry | Checks pull requests against, and publishes `main` to, the Apollo GraphOS schema registry. |
{% endif %}

The pipeline needs no secrets.
{% if values.enableSchemaRegistry %}

### Schema registry

The schema registry job is skipped until the repository has both:

- the secret `APOLLO_KEY`: a graph API key from Apollo GraphOS;
- the variable `APOLLO_GRAPH_REF`: the graph and variant, for example `my-graph@current`.

It then runs `rover graph check` on pull requests and `rover graph publish` on
pushes to `main`, with the schema printed by `npm run schema:print`.
{% endif %}

## Deployment

`.github/workflows/release.yaml` publishes the container image to
`ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}` when a tag such as `v${{ values.apiVersion }}` is pushed.
Run it with the variables above; it listens on port 4000 and migrates its
database when it starts.
{% if values.databaseType == 'sqlite' %}

SQLite keeps the data in one file on the disk of the container: mount a volume
on `/app/data`, and run a single replica.
{% endif %}
