# API

The schema is in `src/schema/schema.graphql` and, for subscriptions,
`src/schema/subscriptions.graphql`.

| Operation | Kind | Access |
| --- | --- | --- |
| `products(limit, offset)` | Query | Everyone |
| `product(id)` | Query | Everyone |
| `viewer` | Query | Everyone; `null` without a token |
| `createProduct(input)` | Mutation | See [Authentication](#authentication) |
| `deleteProduct(id)` | Mutation | See [Authentication](#authentication) |
| `productCreated` | Subscription | Everyone, while subscriptions are on |

```graphql
mutation {
  createProduct(input: { name: "Widget", priceCents: 1250 }) {
    id
    createdAt
  }
}
```

Subscriptions use the `graphql-ws` protocol on `ws://localhost:4000/graphql`.
Events are delivered within one process: to run more than one replica, replace
the `PubSub` in `src/server.ts` with one backed by a message broker.

## Authentication

While `AUTH_ENABLED` is `true`, mutations need an `Authorization: Bearer <token>`
header. With `AUTH_RBAC=true` the token must also carry the `admin` role in its
`roles` claim (`AUTH_ROLES_CLAIM` names another claim). Queries stay open; add
`authorize(...)` to a resolver to protect it.

| `AUTH_PROVIDER` | Tokens | Configuration |
| --- | --- | --- |
| `jwt` | HS256 tokens signed with a shared secret | `JWT_SECRET` |
| `oauth2` | Tokens of an OAuth 2.0 / OpenID Connect identity provider, checked against its published signing keys | `AUTH_ISSUER`, optionally `AUTH_AUDIENCE` and `AUTH_JWKS_URI` |

For the `jwt` provider, `npm run token` prints a development token with the
`admin` role, and `npm run token -- editor` one with other roles.

## Query complexity

Every field costs 1, and a list costs its page size times the cost of one
item. An operation that costs more than `QUERY_COMPLEXITY_LIMIT` is rejected
with the code `QUERY_TOO_COMPLEX` before it runs.

## Caching

While `CACHE_ENABLED` is `true`, query responses are cached for
`CACHE_TTL_SECONDS` (30 by default): in Redis when `REDIS_URL` is set, else in
the memory of each process. A response that depends on the caller is cached
per caller. Use the `@cacheControl` directive in the schema to give a type or
field its own lifetime. A change only shows in cached queries once their entry
expires.

## Changing the schema

1. Edit the `.graphql` files.
2. Run `npm run codegen` and commit `src/generated/graphql.ts`: the pipeline
   fails when it does not match the schema.
3. Implement the resolvers in `src/schema/resolvers.ts`; TypeScript reports
   the ones that are missing or have the wrong shape.
4. Schema changes that need new tables or columns get a new migration at the
   end of the list in `src/db/migrations.ts`. Migrations run when the API starts.
