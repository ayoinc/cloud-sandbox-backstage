# ${{ values.name }}

${{ values.description }}

## Overview

This is a Hugo static website using the **${{ values.hugoTheme }}** theme.

## Development

### Prerequisites

- [Hugo](https://gohugo.io/installation/) (extended version)
- Git

### Local Development

```bash
# Clone the repository
git clone https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}.git
cd ${{ values.destination.repo }}

# Start Hugo development server
hugo server -D

# Site will be available at http://localhost:1313
```

### Build

```bash
hugo --minify
```

Built files will be in the `public/` directory.

## Content Management

### Adding Pages

Create new content files in the `content/` directory:

```bash
hugo new posts/my-new-post.md
```

### Configuration

Site configuration is in `config.toml`. Key settings:

- `baseURL`: Production URL
- `title`: Site title
- `theme`: Hugo theme

## Deployment

The site automatically deploys to GitHub Pages when changes are pushed to the `main` branch.

## Resources

- [Hugo Documentation](https://gohugo.io/documentation/)
- [${{ values.hugoTheme }} Theme](https://themes.gohugo.io/)
