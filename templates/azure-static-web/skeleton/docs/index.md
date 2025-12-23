# ${{ values.name }}

${{ values.description }}

## Overview

This Azure Static Web App hosts a **${{ values.framework }}** application for the **${{ values.environment }}** environment.

## Configuration

| Setting | Value |
|---------|-------|
| Framework | ${{ values.framework }} |
| SKU Tier | ${{ values.skuTier }} |
| Location | ${{ values.location }} |
| Environment | ${{ values.environment }} |

## Features

- **Global CDN**: Content served from edge locations worldwide
- **Free SSL**: Automatic HTTPS certificates
- **Staging Environments**: Preview deployments for pull requests
- **Integrated API**: Optional Azure Functions backend
- **Authentication**: Built-in auth with Azure AD, GitHub, Twitter

## Local Development

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build
```

## Deployment

Deployments are triggered automatically via GitHub Actions when pushing to `main`.

### Manual Deployment

```bash
# Install SWA CLI
npm install -g @azure/static-web-apps-cli

# Login
swa login

# Deploy
swa deploy ./build --deployment-token <token>
```

## Environment Variables

Set environment variables in Azure Portal or via Terraform:

```hcl
resource "azurerm_static_web_app" "main" {
  # ... existing config
  
  app_settings = {
    "API_URL" = "https://api.example.com"
  }
}
```

## Custom Domain (Standard Tier)

To add a custom domain:

1. Add CNAME record pointing to the default hostname
2. Update Terraform with `custom_domain` variable
3. Apply changes

## Owner

This resource is owned by **${{ values.owner }}**.
