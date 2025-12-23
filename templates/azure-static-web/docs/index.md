# Azure Static Web App Template

This template creates an Azure Static Web App for hosting static sites and SPAs.

## Features

- **Global CDN** - Fast content delivery worldwide
- **Free SSL** - Automatic HTTPS certificates
- **Staging environments** - Preview deployments for PRs
- **API integration** - Azure Functions backend
- **Custom domains** - Bring your own domain
- **Authentication** - Built-in auth providers

## Prerequisites

- Azure Subscription
- GitHub repository
- Terraform >= 1.5

## Supported Frameworks

- React
- Vue.js
- Angular
- Next.js
- Gatsby
- Hugo
- Plain HTML/CSS/JS

## Quick Start

```bash
terraform init
terraform apply
```

## Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `name` | App name | - |
| `sku_tier` | Pricing tier | `Free` |
| `sku_size` | SKU size | `Free` |

## Deployment

Push to your connected GitHub repository to trigger automatic deployments.

## Outputs

- `default_host_name` - Default URL
- `api_key` - Deployment token

## Support

Contact the Platform Team for assistance.
