# Operations

## Configuration of the API

| Variable | Default | Meaning |
| --- | --- | --- |
| `PORT` | `8080` | Port the API listens on. |
| `DATABASE_URL` | `postgres://store:store@localhost:5432/store` | PostgreSQL connection string. |
| `REDIS_URL` | | Redis for the catalogue cache. Without it nothing is cached. |
| `ADMIN_TOKEN` | | Bearer token of the admin API. Without it the admin API answers 503. |
| `SEED_SAMPLE_DATA` | `true`, `false` when `NODE_ENV=production` | Fill an empty catalogue with sample products. |
| `FEATURE_PRODUCT_MANAGEMENT` | `${{ 'true' if values.enableCMS else 'false' }}` | Admin API and page for products. |
| `FEATURE_PAYMENTS` | `${{ 'true' if values.enablePayments else 'false' }}` | Payment step at checkout. |
| `FEATURE_SEARCH` | `${{ 'true' if values.enableSearch else 'false' }}` | Catalogue search. |
| `FEATURE_REVIEWS` | `${{ 'true' if values.enableReviews else 'false' }}` | Reviews and ratings. |
| `FEATURE_INVENTORY` | `${{ 'true' if values.enableInventory else 'false' }}` | Stock levels. |
| `FEATURE_ANALYTICS` | `${{ 'true' if values.enableAnalytics else 'false' }}` | Sales figures. |
| `FEATURE_CACHING` | `${{ 'true' if values.enableCaching else 'false' }}` | Catalogue cache in Redis. |

`/healthz` answers while the process is up and `/readyz` while the database
answers.

The storefront container needs one variable: `BACKEND_URL`, the address its
nginx sends `/api/` to.

## Pipeline

`.github/workflows/ci.yaml` runs on every push to `main` and on pull requests:

| Job | What it checks |
| --- | --- |
| Backend | ESLint, TypeScript, the tests against a PostgreSQL{% if values.enableCaching %} and a Redis{% endif %} service, the build. |
| Frontend | ESLint, TypeScript, the tests, the build. |
| Infrastructure | `terraform fmt`, `terraform validate` and TFLint on `infra/`. |
| Build the images and smoke-test the store | Starts the store with `docker compose`, loads the page and the catalogue through the storefront and places an order. |

The pipeline needs no secrets and does not deploy.

`.github/workflows/release.yaml` runs when a tag such as `v1.0.0` is pushed and
publishes `ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}/backend` and `.../frontend` with that version
and `latest`.{% if values.provider != 'gcp' %} Make the two packages public in GitHub, or give the platform
credentials to pull them.{% endif %}


## Deployment on ${{ 'Microsoft Azure' if values.provider == 'azure' else ('Amazon Web Services' if values.provider == 'aws' else 'Google Cloud') }}

`infra/` creates what the store runs on in `${{ values.region }}`:

{% if values.provider == 'azure' %}
- a resource group, and a Container Apps environment with its log workspace;
- the API and the storefront as container apps; only the storefront is reachable from outside;
- Azure Database for PostgreSQL (flexible server);
- Azure Cache for Redis, when `enable_cache` is `true` (${{ 'on' if values.enableCaching else 'off' }} by default);
- Azure Front Door in front of the storefront, when `enable_cdn` is `true` (${{ 'on' if values.enableCDN else 'off' }} by default).
{% elif values.provider == 'aws' %}
- a VPC with public subnets for the load balancer and containers, and private subnets for the data stores;
- the API and the storefront as ECS services on Fargate behind an Application Load Balancer, which sends `/api/*` to the API;
- Amazon RDS for PostgreSQL, with the connection string in Systems Manager Parameter Store;
- ElastiCache for Redis, when `enable_cache` is `true` (${{ 'on' if values.enableCaching else 'off' }} by default);
- Amazon CloudFront in front of the load balancer, when `enable_cdn` is `true` (${{ 'on' if values.enableCDN else 'off' }} by default).
{% else %}
- the API and the storefront as Cloud Run services;
- an Artifact Registry repository through which Cloud Run pulls the images from the GitHub Container Registry;
- Cloud SQL for PostgreSQL, with the connection string in Secret Manager;
- Memorystore for Redis with a VPC connector, when `enable_cache` is `true` (${{ 'on' if values.enableCaching else 'off' }} by default);
- a global load balancer with Cloud CDN in front of the storefront, when `enable_cdn` is `true` (${{ 'on' if values.enableCDN else 'off' }} by default).
{% endif %}

With `enable_autoscaling` (${{ 'on' if values.autoScaling else 'off' }} by default) the API and the storefront
scale between `min_replicas` and `max_replicas` with the load; without it both
run `min_replicas` instances. `infra/environments/` holds the sizes for `dev`,
`stg` and `prod`; this store was created for `${{ values.environment }}`.

### First deployment

1. Publish the images: `git tag v1.0.0 && git push origin v1.0.0`.
{% if values.provider == 'azure' %}
2. Sign in with `az login` and set `ARM_SUBSCRIPTION_ID` to your subscription.
{% elif values.provider == 'aws' %}
2. Give Terraform AWS credentials, for example with `aws configure sso`.
{% else %}
2. Sign in with `gcloud auth application-default login`.
{% endif %}
3. Apply the Terraform code:

    ```sh
    cd infra
    terraform init
    terraform apply -var-file=environments/${{ values.environment }}.tfvars{% if values.provider == 'gcp' %} -var project_id=<your project>{% endif %}

    ```

4. `terraform output store_url` prints the address of the store, and
   `terraform output -raw admin_token` the token of the admin API.

Terraform keeps its state in a local file until you configure a backend:
`infra/versions.tf` shows where. Do that before more than one person, or a
pipeline, applies the code.

The infrastructure code is checked by `terraform validate` and TFLint in the
pipeline. Review it against your organisation's network and security rules
before the first production deployment: the starting point favours a small,
readable setup{% if values.provider == 'aws' %} (plain HTTP on the load balancer, containers in public subnets){% elif values.provider == 'gcp' %} (public Cloud Run services, plain HTTP on the load balancer address){% else %} (a database firewall rule that admits Azure-internal traffic){% endif %}.
