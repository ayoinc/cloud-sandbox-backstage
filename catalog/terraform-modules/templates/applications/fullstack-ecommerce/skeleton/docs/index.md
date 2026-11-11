# ${{ values.projectName }}

${{ values.description }}

`${{ values.projectName }}` is an online store made of three parts:

| Part | What it is | Where |
| --- | --- | --- |
| Storefront | A single-page application in React and TypeScript, served by nginx | `frontend/` |
| API | A REST API in Node.js and TypeScript with a PostgreSQL database | `backend/` |
| Infrastructure | Terraform code for ${{ 'Microsoft Azure' if values.provider == 'azure' else ('Amazon Web Services' if values.provider == 'aws' else 'Google Cloud') }} (${{ values.region }}) | `infra/` |

Customers browse the catalogue, fill a cart and place an order. The API takes
the prices from its own catalogue, never from the browser.

## Features

Each feature is a switch of the API, and the storefront shows what the API
reports as on. The defaults below were chosen when the store was created; set
the variable to `true` or `false` to change one in an environment.

| Feature | Default | Variable | What it adds |
| --- | --- | --- | --- |
| Product management | ${{ 'On' if values.enableCMS else 'Off' }} | `FEATURE_PRODUCT_MANAGEMENT` | Admin API and admin page to add and delete products. |
| Payments | ${{ 'On' if values.enablePayments else 'Off' }} | `FEATURE_PAYMENTS` | A payment step at checkout, through a payment provider you plug in. |
| Search | ${{ 'On' if values.enableSearch else 'Off' }} | `FEATURE_SEARCH` | Text search in the catalogue. |
| Reviews | ${{ 'On' if values.enableReviews else 'Off' }} | `FEATURE_REVIEWS` | Customer reviews and ratings. |
| Inventory | ${{ 'On' if values.enableInventory else 'Off' }} | `FEATURE_INVENTORY` | Stock levels: orders reduce them and cannot exceed them. |
| Analytics | ${{ 'On' if values.enableAnalytics else 'Off' }} | `FEATURE_ANALYTICS` | Sales figures on the admin page. |
| Caching | ${{ 'On' if values.enableCaching else 'Off' }} | `FEATURE_CACHING` | Catalogue reads cached in Redis. |

The defaults live in `backend/src/features.ts`.

## Run it

```sh
docker compose up --build
```

The storefront is on <http://localhost:3000> and the API on
<http://localhost:8080/api/v1>. A new store starts with six sample products.

## Where to go next

- [Development](development.md): working on the storefront and the API.
- [Operations](operations.md): configuration, pipeline and deployment.
