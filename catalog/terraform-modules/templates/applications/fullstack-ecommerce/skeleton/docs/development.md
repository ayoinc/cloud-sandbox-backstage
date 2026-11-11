# Development

You need Node.js 24 (see `.nvmrc`) and Docker.

## API

```sh
docker compose up --detach db{% if values.enableCaching %} redis{% endif %}

cd backend
npm ci
cp .env.example .env
npm run dev
```

The API listens on <http://localhost:8080/api/v1> and restarts when a file
changes.

| Script | What it does |
| --- | --- |
| `npm run dev` | Runs the API and restarts it when a file changes. |
| `npm test` | Runs the tests against the database `DATABASE_URL` points at. They empty its tables. |
| `npm run lint` | Runs ESLint. |
| `npm run typecheck` | Checks the types. |
| `npm run build` | Compiles to `dist/`. |

| Path | Content |
| --- | --- |
| `src/app.ts` | The routes. A feature that is off has no routes. |
| `src/store.ts` | Reads and writes products, reviews and orders. |
| `src/db.ts` | Connection, migrations and the sample products. |
| `src/features.ts`, `src/config.ts` | Feature defaults and the configuration from environment variables. |
| `src/payments.ts` | The payment provider interface and its sandbox implementation. |
| `src/cache.ts` | The catalogue cache. |

### Endpoints

| Method and path | Purpose | Needs |
| --- | --- | --- |
| `GET /api/v1/config` | The feature switches | |
| `GET /api/v1/products?q=&limit=&offset=` | The catalogue | `q` needs search |
| `GET /api/v1/products/:id` | One product | |
| `GET`, `POST /api/v1/products/:id/reviews` | Reviews of a product | Reviews |
| `POST /api/v1/orders` | Place an order | |
| `GET /api/v1/orders/:id` | One order | |
| `POST /api/v1/admin/products`, `PUT`, `DELETE /api/v1/admin/products/:id` | Manage products | Product management, admin token |
| `GET /api/v1/admin/analytics/summary` | Sales figures | Analytics, admin token |

The admin endpoints need `Authorization: Bearer <ADMIN_TOKEN>`.

### Database changes

Add a migration to the end of the list in `src/db.ts`. Migrations run when the
API starts, each once.

### Payments

With payments on, an order needs a `paymentToken` and is only kept when the
payment provider accepts the charge. The store comes with a sandbox provider
that moves no money: it accepts every token except `tok_declined`. Before
taking real orders, implement `PaymentProvider` (`src/payments.ts`) for your
payment gateway and pass it to `createApp` in `src/index.ts`.

## Storefront

```sh
cd frontend
npm ci
npm run dev
```

The storefront is on <http://localhost:3000> and sends `/api` to the API on
port 8080 (`API_URL` names another address).

| Script | What it does |
| --- | --- |
| `npm run dev` | Runs the storefront with hot reloading. |
| `npm test` | Runs the tests, with a stand-in for the API. |
| `npm run lint` | Runs ESLint. |
| `npm run typecheck` | Checks the types. |
| `npm run build` | Builds the static files into `dist/`. |

| Path | Content |
| --- | --- |
| `src/App.tsx` | Header and routes. |
| `src/pages/` | Catalogue, product, cart and checkout, admin. |
| `src/api.ts` | The calls to the API. |
| `src/cart.tsx` | The cart, kept in the browser. |
| `src/site.ts` | The name of the store. |
