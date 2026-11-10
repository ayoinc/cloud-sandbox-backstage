# ${{ values.name }}

${{ values.description }}

## Overview

Responsive marketing landing page for **${{ values.companyName }}**, written in plain HTML, CSS and JavaScript. There is no build step and nothing to install.

## Getting Started

Serve the repository root with any static file server:

```bash
python3 -m http.server 8000
```

Open [http://localhost:8000](http://localhost:8000).

## Project Structure

```
├── index.html             # Page markup
├── css/style.css          # Styles; the brand colour is the --primary-color variable
├── js/main.js             # Mobile navigation, smooth scrolling, contact form
├── images/                # Favicon and image assets
├── scripts/build-site.sh  # Collects the published files into _site/
├── docs/                  # TechDocs documentation
├── catalog-info.yaml
└── mkdocs.yml
```

## Continuous Integration

The `Deploy Landing Page` workflow runs on every push and pull request:

| Job | What it does |
| --- | --- |
| Validate HTML | Assembles the site and checks its HTML, CSS and links |
| Security Scan | Scans the repository for misconfigurations and committed secrets |
| Build Documentation | Builds the TechDocs documentation with `mkdocs build --strict` |
| Deploy to GitHub Pages | Publishes `_site/` from `main` once GitHub Pages is enabled |

## Deployment

The page is published with GitHub Pages. Pages is off for a new repository, and the deploy job is skipped until it is switched on:

1. Open **Settings > Pages** in the repository
2. Under **Build and deployment**, set **Source** to **GitHub Actions**
3. Run the `Deploy Landing Page` workflow again from the **Actions** tab, or push to `main`

The site is then served at `https://${{ values.destination.owner }}.github.io/${{ values.destination.repo }}/`.

## Owner

${{ values.owner }}
