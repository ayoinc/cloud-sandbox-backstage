# ${{ values.name }}

${{ values.description }}

## Overview

Static website built with [Hugo](https://gohugo.io/) and the `${{ values.hugoTheme }}` theme.

## Getting Started

Install Hugo Extended {% if values.hugoTheme == 'minimal' %}0.128.2{% else %}0.169.0{% endif %} and Go, then:

```bash
hugo server -D
```

Open [http://localhost:1313](http://localhost:1313). The theme is a Hugo Module pinned in `go.mod`; Hugo downloads it on the first run.

## Build

```bash
hugo --gc --minify
```

The site is written to `public/`.

## Project Structure

```
├── content/             # Pages and posts in Markdown
├── static/              # Files copied to the site as they are
├── hugo.toml            # Site configuration
├── go.mod, go.sum       # Version and checksums of the theme module
├── docs/                # TechDocs documentation
├── catalog-info.yaml
└── mkdocs.yml
```

## Continuous Integration

The `Hugo CI/CD` workflow runs on every push and pull request:

| Job | What it does |
| --- | --- |
| Build Site | Builds the site with Hugo |
| Security Scan | Scans the repository for misconfigurations and committed secrets |
| Build Documentation | Builds the TechDocs documentation with `mkdocs build --strict` |
| Deploy to GitHub Pages | Publishes the site from `main` once GitHub Pages is enabled |

## Deployment

The site is published with GitHub Pages. Pages is off for a new repository, and the deploy job is skipped until it is switched on:

1. Open **Settings > Pages** in the repository
2. Under **Build and deployment**, set **Source** to **GitHub Actions**
3. Run the `Hugo CI/CD` workflow again from the **Actions** tab, or push to `main`

The site is then served at `https://${{ values.destination.owner }}.github.io/${{ values.destination.repo }}/`. The deploy job builds the site for that address, whatever `baseURL` is set to in `hugo.toml`.

## Owner

${{ values.owner }}
