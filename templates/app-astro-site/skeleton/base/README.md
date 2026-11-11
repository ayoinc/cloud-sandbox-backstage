# ${{ values.name }}

${{ values.description }}

Content site built with [Astro](https://astro.build/), Tailwind CSS v4 and
TypeScript. Published at <${{ values.siteUrl }}${{ values.basePath }}>.

## Getting started

Requires Node.js 24 (see `.nvmrc`).

```bash
npm install
npm run dev
```

## Scripts

- `npm run dev` starts the development server with live reload
- `npm run build` builds the site into `dist/`
- `npm run preview` serves the built site locally
- `npm run check` type-checks the project and validates the content
- `npm test` runs the Vitest tests
- `npm run format` formats with Prettier (`npm run format:check` verifies)

## Writing

Add a Markdown file to `src/content/posts/`. Its front matter is validated by
`src/content.config.ts`:

```yaml
---
title: Release notes
description: What changed this month.
pubDate: 2026-02-01
draft: true # optional: visible in development only
---
```

The title and description of the site, its URL and its base path are in
`site.config.json`.

## Deployment

`.github/workflows/deploy.yaml` builds and publishes the site on every push to
`main`. It is skipped until the repository is configured:

{%- if values.hosting == 'github-pages' %}
The site is published to GitHub Pages. In the repository:

1. Open **Settings > Pages** and set **Source** to **GitHub Actions**.
2. Add the repository variable `PAGES_ENABLED` with the value `true`.

The deployment is authorised by the workflow's OIDC token; no secret is stored.
Private repositories need a plan that includes GitHub Pages.
{%- elif values.hosting == 'cloudflare' %}
The site is published as static assets of a Cloudflare Worker, configured in
`wrangler.jsonc`; `public/_headers` sets its security and cache headers. Add
to the repository:

| Kind     | Name                    | Value                                                                            |
| -------- | ----------------------- | -------------------------------------------------------------------------------- |
| Variable | `CLOUDFLARE_ACCOUNT_ID` | Identifier of the Cloudflare account                                             |
| Secret   | `CLOUDFLARE_API_TOKEN`  | Token from the "Edit Cloudflare Workers" template, limited to that account       |

Cloudflare does not accept GitHub's OIDC tokens: give the token an expiry and
rotate it. Attach your domain to the Worker in the Cloudflare dashboard or with
a `routes` entry in `wrangler.jsonc`.
{%- else %}
The site is published to a private Amazon S3 bucket served by a CloudFront
distribution. The workflow assumes an IAM role with GitHub's OIDC token; no
access key is stored. Add these repository variables:

| Variable                     | Value                                                    |
| ---------------------------- | -------------------------------------------------------- |
| `AWS_ROLE_ARN`               | Role the workflow assumes                                |
| `AWS_REGION`                 | Region of the bucket                                     |
| `S3_BUCKET`                  | Name of the bucket                                       |
| `CLOUDFRONT_DISTRIBUTION_ID` | Distribution to invalidate after an upload               |

The role's trust policy should allow only
`repo:${{ values.destination.owner }}/${{ values.destination.repo }}:environment:production`
as the OIDC subject, and its permissions only `s3:ListBucket` on the bucket,
`s3:PutObject` and `s3:DeleteObject` on its objects, and
`cloudfront:CreateInvalidation` on the distribution. Keep the bucket private
and let CloudFront read it through origin access control. Astro writes pages as
`<path>/index.html`: add a CloudFront function that appends `index.html` to
requests ending in `/`, and set the distribution's 404 response to `/404.html`.
{%- endif %}

## Owner

${{ values.owner }}
