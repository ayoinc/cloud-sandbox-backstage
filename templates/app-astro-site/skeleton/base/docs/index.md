# ${{ values.name }}

${{ values.description }}

## Overview

| Setting    | Value                                                                               |
| ---------- | ----------------------------------------------------------------------------------- |
| Site       | <${{ values.siteUrl }}${{ values.basePath }}>                                       |
| Owner      | `${{ values.owner }}`                                                               |
| Framework  | Astro 7, static output                                                              |
| Styles     | Tailwind CSS v4 with the typography plugin                                          |
| Hosting    | {% if values.hosting == 'github-pages' %}GitHub Pages{% elif values.hosting == 'cloudflare' %}Cloudflare Workers static assets{% else %}Amazon S3 with CloudFront{% endif %} |
| Repository | <https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}> |

## Project structure

```
${{ values.name }}/
├── .github/
│   ├── dependabot.yml        # Weekly dependency updates
│   └── workflows/
│       ├── ci.yaml           # Format, type check, tests, build
│       └── deploy.yaml       # Build and publish
├── public/                   # Files copied as they are
├── src/
│   ├── content/posts/        # Markdown posts
│   ├── content.config.ts     # Schema of the posts' front matter
│   ├── components/           # Header, footer, post list
│   ├── layouts/Base.astro    # HTML shell and metadata of every page
│   ├── lib/                  # Link, date and post helpers, with tests
│   ├── pages/                # One file per route
│   ├── styles/global.css     # Tailwind CSS and theme tokens
│   └── site.ts               # Navigation
├── site.config.json          # Title, description, URL and base path
├── astro.config.ts
{%- if values.hosting == 'cloudflare' %}
├── wrangler.jsonc            # Static assets deployment
{%- endif %}
├── catalog-info.yaml         # Catalog entry
└── mkdocs.yml                # TechDocs configuration
```

## Pages

| Route             | Source                              |
| ----------------- | ----------------------------------- |
| `/`               | `src/pages/index.astro`             |
| `/posts/`         | `src/pages/posts/index.astro`       |
| `/posts/<name>/`  | `src/pages/posts/[...slug].astro`   |
| `/rss.xml`        | `src/pages/rss.xml.ts`              |
| `/robots.txt`     | `src/pages/robots.txt.ts`           |
| `/health.json`    | `src/pages/health.json.ts`          |
| `/404.html`       | `src/pages/404.astro`               |

`/health.json` reports the time and commit of the build that is live; point an
uptime check at it. The sitemap is generated at `/sitemap-index.xml`.

Internal links are built with `href()` from `src/lib/paths.ts`, which prefixes
the base path, so the site works at the root of a domain and under a sub-path.

## Styles

`src/styles/global.css` imports Tailwind CSS v4 and declares the theme tokens
(`--color-brand-*`, `--font-sans`) in an `@theme` block; there is no
`tailwind.config.js`. Markdown content is styled by the typography plugin's
`prose` classes.

## Continuous integration

`.github/workflows/ci.yaml` runs on every push to `main` and on demand:

| Job   | What it does                                                        |
| ----- | ------------------------------------------------------------------- |
| Check | Prettier, `astro check` (types and content schema) and Vitest       |
| Build | Builds the site and verifies that the expected files exist          |

## Deployment

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

## References

- [Astro](https://docs.astro.build/)
- [Content collections](https://docs.astro.build/en/guides/content-collections/)
- [Tailwind CSS](https://tailwindcss.com/docs)
