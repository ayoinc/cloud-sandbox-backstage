# ${{ values.projectName }}

${{ values.description }}

An online store: a React storefront, a Node.js API with a PostgreSQL database,
and Terraform code to run it on ${{ 'Microsoft Azure' if values.provider == 'azure' else ('Amazon Web Services' if values.provider == 'aws' else 'Google Cloud') }}.

## Quick start

You need Docker.

```sh
docker compose up --build
```

The storefront is on <http://localhost:3000>, with sample products to browse
and order. The API is on <http://localhost:8080/api/v1>.{% if values.enableCMS or values.enableAnalytics %} The admin page asks for
the admin token, which is `local-admin-token` in this setup.{% endif %}


To work on the code, see [docs/development.md](docs/development.md).

## What is in the repository

| Path | Content |
| --- | --- |
| `frontend/` | The storefront: React, TypeScript and Vite. |
| `backend/` | The API: Express, TypeScript and PostgreSQL. |
| `infra/` | Terraform code for ${{ 'Microsoft Azure' if values.provider == 'azure' else ('Amazon Web Services' if values.provider == 'aws' else 'Google Cloud') }}. |
| `docker-compose.yml` | The whole store on one machine. |
| `docs/` | The documentation shown in the developer portal. |

## Features

Each feature is a switch of the API; the storefront follows it. The defaults
were chosen when the store was created.

| Feature | Default | Variable | What it adds |
| --- | --- | --- | --- |
| Product management | ${{ 'On' if values.enableCMS else 'Off' }} | `FEATURE_PRODUCT_MANAGEMENT` | Admin API and admin page to add and delete products. |
| Payments | ${{ 'On' if values.enablePayments else 'Off' }} | `FEATURE_PAYMENTS` | A payment step at checkout, through a payment provider you plug in. |
| Search | ${{ 'On' if values.enableSearch else 'Off' }} | `FEATURE_SEARCH` | Text search in the catalogue. |
| Reviews | ${{ 'On' if values.enableReviews else 'Off' }} | `FEATURE_REVIEWS` | Customer reviews and ratings. |
| Inventory | ${{ 'On' if values.enableInventory else 'Off' }} | `FEATURE_INVENTORY` | Stock levels: orders reduce them and cannot exceed them. |
| Analytics | ${{ 'On' if values.enableAnalytics else 'Off' }} | `FEATURE_ANALYTICS` | Sales figures on the admin page. |
| Caching | ${{ 'On' if values.enableCaching else 'Off' }} | `FEATURE_CACHING` | Catalogue reads cached in Redis. |

## Pipeline

`.github/workflows/ci.yaml` runs on every push to `main` and on pull requests.
It lints, type-checks, tests and builds the API (against a real PostgreSQL{% if values.enableCaching %} and Redis{% endif %})
and the storefront, validates the Terraform code, and starts the whole store
from its container images to browse the catalogue and place an order. It needs
no secrets.

`.github/workflows/release.yaml` publishes the two images to
`ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}` when you push a tag such as `v1.0.0`.

Deploying is described in [docs/operations.md](docs/operations.md).
