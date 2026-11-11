# Astro Content Site Template

Creates a content site built with Astro in a new GitHub repository: Markdown
posts in a typed content collection, Tailwind CSS v4, strict TypeScript, an RSS
feed and a sitemap, with a pipeline that passes on the first push and a
deployment workflow for the selected host.

## Form

| Field        | Effect                                                                       |
| ------------ | ---------------------------------------------------------------------------- |
| Project Name | Name of the package, the repository and the catalog entry                    |
| Description  | Site description (meta tag, feed), README and catalog entry                  |
| Owner        | Owner of the catalog entry                                                   |
| Site Title   | Title in the header, the browser tab and the feed                            |
| Site URL     | Public origin: canonical links, sitemap and feed                             |
| Base Path    | Sub-path the site is served under; `/` for a site at the root of its domain  |
| Hosting      | GitHub Pages, Cloudflare Workers static assets, or Amazon S3 with CloudFront |
| Repository   | GitHub repository to create                                                  |

## What is generated

- `src/content/posts/`: Markdown posts; `src/content.config.ts` validates their
  front matter, so a missing title fails the build instead of reaching readers
- `src/pages/`: home, post list, post pages, 404, `rss.xml`, `robots.txt` and
  `health.json`
- `src/styles/global.css`: Tailwind CSS v4 with the typography plugin and theme
  tokens
- Strict TypeScript, `astro check`, Prettier with the Astro and Tailwind plugins
- Vitest tests of the helpers
- `package-lock.json`
- `.github/workflows/ci.yaml`: format check, type check, tests and build
- `.github/workflows/deploy.yaml`: deployment to the selected host, skipped
  until the repository is configured for it (the generated README lists what
  to set). Amazon S3 uses GitHub's OIDC token and a role, not access keys
- `.github/dependabot.yml`: weekly updates of packages and actions
- `catalog-info.yaml`, `mkdocs.yml` and `docs/index.md` for the portal

## Template layout

| Directory                      | Used                    |
| ------------------------------ | ----------------------- |
| `skeleton/base`                | Always                  |
| `skeleton/deploy-github-pages` | Hosting is GitHub Pages |
| `skeleton/deploy-cloudflare`   | Hosting is Cloudflare   |
| `skeleton/deploy-aws-s3`       | Hosting is Amazon S3    |
