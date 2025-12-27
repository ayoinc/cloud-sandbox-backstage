# ${{ values.name }}

${{ values.description }}

## Overview

This is a production-ready Hugo static website using the **${{ values.hugoTheme }}** theme, designed for marketing and content-driven websites. The template provides:

- Fast, SEO-optimized static site generation with Hugo
- Automated CI/CD pipeline with GitHub Actions
- GitHub Pages deployment with zero configuration
- Responsive design with customizable themes
- Built-in content management structure
- TechDocs integration for Backstage documentation

```d2
direction: right

title: {
  label: Static Site Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

developer: Developer {
  shape: person
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

repo: GitHub Repository {
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"

  content: Content {
    label: "Markdown\nFiles"
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"
  }

  config: Config {
    label: "config.toml\nTheme Settings"
    style.fill: "#FFF3E0"
    style.stroke: "#FF9800"
  }

  static: Static Assets {
    label: "CSS/JS\nImages"
    style.fill: "#E1F5FE"
    style.stroke: "#0288D1"
  }
}

actions: GitHub Actions {
  style.fill: "#FFEBEE"
  style.stroke: "#C62828"

  build: Hugo Build {
    label: "Build &\nMinify"
    style.fill: "#FCE4EC"
    style.stroke: "#C2185B"
  }

  deploy: Deploy {
    label: "GitHub\nPages"
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"
  }

  build -> deploy
}

cdn: GitHub Pages CDN {
  shape: cloud
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
}

users: Website Visitors {
  shape: person
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
}

developer -> repo.content: writes
repo -> actions: triggers
actions -> cdn: deploys
cdn -> users: serves
```

## Configuration Summary

| Setting          | Value                                                               |
| ---------------- | ------------------------------------------------------------------- |
| Project Name     | `${{ values.name }}`                                                |
| Hugo Theme       | `${{ values.hugoTheme }}`                                           |
| Base URL         | `${{ values.baseUrl }}`                                             |
| Owner            | `${{ values.owner }}`                                               |
| Repository       | `${{ values.destination.owner }}/${{ values.destination.repo }}`    |
| Deployment       | GitHub Pages                                                        |

## Project Structure

```
${{ values.name }}/
├── .github/
│   └── workflows/
│       └── hugo.yaml           # CI/CD pipeline configuration
├── content/
│   ├── _index.md               # Homepage content
│   ├── about/
│   │   └── index.md            # About page
│   ├── contact/
│   │   └── index.md            # Contact page
│   └── posts/                  # Blog posts directory
│       └── *.md
├── static/
│   ├── css/
│   │   └── style.css           # Custom styles
│   ├── js/
│   │   └── main.js             # Custom JavaScript
│   └── images/                 # Image assets
├── layouts/                    # Custom layout overrides
│   ├── partials/
│   │   ├── header.html
│   │   └── footer.html
│   └── _default/
│       └── baseof.html
├── themes/
│   └── ${{ values.hugoTheme }}/ # Hugo theme (git submodule)
├── docs/
│   └── index.md                # TechDocs documentation
├── config.toml                 # Hugo configuration
├── catalog-info.yaml           # Backstage component definition
├── mkdocs.yml                  # TechDocs configuration
└── README.md                   # Project readme
```

| Directory/File      | Purpose                                          |
| ------------------- | ------------------------------------------------ |
| `content/`          | Markdown content files for pages and posts       |
| `static/`           | Static assets (CSS, JS, images)                  |
| `layouts/`          | Custom HTML templates and overrides              |
| `themes/`           | Hugo theme files                                 |
| `config.toml`       | Site configuration and settings                  |
| `catalog-info.yaml` | Backstage service catalog metadata               |

---

## CI/CD Pipeline

This repository includes an automated GitHub Actions pipeline for building and deploying the static site:

- **Build Stage**: Hugo extended version builds and minifies assets
- **Deploy Stage**: Automatic deployment to GitHub Pages on main branch
- **Preview**: Pull request builds for testing before merge
- **Artifact Upload**: Build outputs preserved for deployment

### Pipeline Workflow

```d2
direction: right

pr: Pull Request {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

push: Push to Main {
  shape: oval
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
}

checkout: Checkout {
  style.fill: "#F5F5F5"
  style.stroke: "#616161"
  label: "Clone Repo\nFetch Submodules"
}

setup: Setup Hugo {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
  label: "Hugo Extended\nLatest Version"
}

build: Build {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  label: "hugo --minify\nGenerate Static Files"
}

upload: Upload Artifact {
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"
  label: "pages-artifact\npublic/"
}

deploy: Deploy {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "GitHub Pages\nProduction"
}

check: Main Branch? {
  shape: diamond
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"
}

pr -> checkout
push -> checkout
checkout -> setup -> build -> upload -> check
check -> deploy: Yes
```

### Pipeline Triggers

| Trigger                | Actions                              |
| ---------------------- | ------------------------------------ |
| Pull Request to `main` | Build and validate (no deploy)       |
| Push to `main`         | Build, validate, and deploy to Pages |

---

## Prerequisites

### 1. Hugo Installation

Hugo Extended is required for SCSS/SASS processing and advanced features.

#### macOS

```bash
# Using Homebrew
brew install hugo

# Verify installation
hugo version
```

#### Linux

```bash
# Using Snap
sudo snap install hugo --channel=extended

# Or download from GitHub releases
wget https://github.com/gohugoio/hugo/releases/download/v0.120.0/hugo_extended_0.120.0_linux-amd64.deb
sudo dpkg -i hugo_extended_0.120.0_linux-amd64.deb
```

#### Windows

```powershell
# Using Chocolatey
choco install hugo-extended

# Using Scoop
scoop install hugo-extended
```

### 2. Git

Git is required for cloning the repository and managing theme submodules.

```bash
# Verify Git installation
git --version
```

### 3. Node.js (Optional)

Required only if using themes with npm dependencies or build tools.

```bash
# Check Node.js version (v18+ recommended)
node --version
npm --version
```

### 4. GitHub Repository Setup

#### Enable GitHub Pages

1. Navigate to repository **Settings > Pages**
2. Under **Build and deployment**, select:
   - **Source**: GitHub Actions
3. Save changes

#### Repository Permissions

Ensure GitHub Actions has write permissions:

1. Go to **Settings > Actions > General**
2. Under **Workflow permissions**, select:
   - **Read and write permissions**
3. Check **Allow GitHub Actions to create and approve pull requests** (optional)

---

## Usage

### Local Development

```bash
# Clone the repository with submodules
git clone --recurse-submodules https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}.git
cd ${{ values.destination.repo }}

# If you already cloned without submodules
git submodule update --init --recursive

# Start the development server
hugo server -D

# Site will be available at http://localhost:1313
# The -D flag includes draft content
```

#### Development Server Options

| Command                      | Description                        |
| ---------------------------- | ---------------------------------- |
| `hugo server`                | Start server with live reload      |
| `hugo server -D`             | Include draft content              |
| `hugo server --bind 0.0.0.0` | Allow external connections         |
| `hugo server -p 8080`        | Use custom port                    |
| `hugo server --disableFastRender` | Full rebuild on changes       |

### Building for Production

```bash
# Build with minification
hugo --minify

# Build with specific environment
hugo --environment production --minify

# Build with garbage collection (remove unused cache)
hugo --gc --minify
```

Built files will be output to the `public/` directory.

### Deploying Manually

While CI/CD handles automatic deployment, you can deploy manually:

```bash
# Build the site
hugo --minify

# Deploy using GitHub CLI (if gh-pages branch setup)
gh-pages -d public

# Or using any static hosting
# Copy contents of public/ to your hosting provider
```

---

## Content Management

### Adding New Pages

```bash
# Create a new page
hugo new about/index.md

# Create a new blog post
hugo new posts/my-first-post.md

# Create content in a specific section
hugo new products/product-name.md
```

### Content Front Matter

Each content file starts with front matter in YAML, TOML, or JSON format:

```yaml
---
title: "Page Title"
date: 2024-01-15
draft: false
description: "A brief description for SEO"
tags: ["marketing", "product"]
categories: ["announcements"]
author: "${{ values.owner }}"
featured_image: "/images/featured.jpg"
---

Your content goes here in Markdown format.
```

### Front Matter Fields

| Field             | Description                              | Required |
| ----------------- | ---------------------------------------- | -------- |
| `title`           | Page or post title                       | Yes      |
| `date`            | Publication date                         | Yes      |
| `draft`           | If true, excluded from production build  | No       |
| `description`     | SEO meta description                     | No       |
| `tags`            | Taxonomy tags for categorization         | No       |
| `categories`      | Content categories                       | No       |
| `author`          | Content author                           | No       |
| `featured_image`  | Hero image path                          | No       |
| `weight`          | Sort order in lists                      | No       |

### Content Organization

```
content/
├── _index.md           # Homepage (required)
├── about/
│   └── index.md        # /about/ page
├── contact/
│   └── index.md        # /contact/ page
├── posts/              # Blog section
│   ├── _index.md       # Blog listing page
│   ├── first-post.md   # /posts/first-post/
│   └── second-post.md  # /posts/second-post/
└── products/           # Products section
    ├── _index.md       # Products listing
    └── widget.md       # /products/widget/
```

### Adding Images

```markdown
<!-- Reference from static directory -->
![Alt text](/images/my-image.jpg)

<!-- Reference with Hugo processing -->
{{< figure src="/images/my-image.jpg" title="Image Title" >}}
```

### Shortcodes

Hugo includes built-in shortcodes for common content patterns:

```markdown
<!-- YouTube embed -->
{{< youtube video_id >}}

<!-- Twitter embed -->
{{< tweet user="username" id="tweet_id" >}}

<!-- GitHub Gist -->
{{< gist username gist_id >}}

<!-- Syntax highlighted code -->
{{< highlight go >}}
func main() {
    fmt.Println("Hello, World!")
}
{{< /highlight >}}
```

---

## Theme Customization

### Configuration Options

Edit `config.toml` to customize the site:

```toml
baseURL = "${{ values.baseUrl }}"
languageCode = "en-us"
title = "${{ values.name }}"
theme = "${{ values.hugoTheme }}"

[params]
  description = "${{ values.description }}"
  author = "${{ values.owner }}"
  
  # Theme-specific parameters
  logo = "/images/logo.png"
  favicon = "/images/favicon.ico"
  primaryColor = "#1976D2"
  
  # Social links
  github = "https://github.com/${{ values.destination.owner }}"
  twitter = "https://twitter.com/yourhandle"
  linkedin = "https://linkedin.com/company/yourcompany"

[markup]
  [markup.goldmark]
    [markup.goldmark.renderer]
      unsafe = true
  [markup.highlight]
    style = "monokai"
    lineNos = true
```

### Custom CSS

Add custom styles in `static/css/style.css`:

```css
/* Custom styles for ${{ values.name }} */
:root {
  --primary-color: #1976D2;
  --secondary-color: #FF9800;
  --text-color: #333333;
  --background-color: #FFFFFF;
}

/* Override theme styles */
.header {
  background-color: var(--primary-color);
}

.btn-primary {
  background-color: var(--secondary-color);
}
```

Include custom CSS in your layouts:

```html
<!-- In layouts/partials/head.html -->
<link rel="stylesheet" href="/css/style.css">
```

### Custom Layouts

Override theme templates by creating files in `layouts/`:

```
layouts/
├── _default/
│   ├── baseof.html    # Base template
│   ├── single.html    # Single page template
│   └── list.html      # List page template
├── partials/
│   ├── header.html    # Header partial
│   ├── footer.html    # Footer partial
│   └── head.html      # Head partial (CSS, meta)
├── posts/
│   └── single.html    # Blog post template
└── index.html         # Homepage template
```

### Menu Configuration

Configure navigation menus in `config.toml`:

```toml
[menu]
  [[menu.main]]
    identifier = "home"
    name = "Home"
    url = "/"
    weight = 1
  [[menu.main]]
    identifier = "about"
    name = "About"
    url = "/about/"
    weight = 2
  [[menu.main]]
    identifier = "blog"
    name = "Blog"
    url = "/posts/"
    weight = 3
  [[menu.main]]
    identifier = "contact"
    name = "Contact"
    url = "/contact/"
    weight = 4

  # Footer menu
  [[menu.footer]]
    name = "Privacy Policy"
    url = "/privacy/"
    weight = 1
  [[menu.footer]]
    name = "Terms of Service"
    url = "/terms/"
    weight = 2
```

---

## Troubleshooting

### Build Errors

**Error: Theme not found**

```
Error: module "themes/${{ values.hugoTheme }}" not found
```

**Resolution:**

```bash
# Initialize/update git submodules
git submodule update --init --recursive

# Or add theme manually
git submodule add https://github.com/theme-author/${{ values.hugoTheme }}.git themes/${{ values.hugoTheme }}
```

---

**Error: SCSS/SASS compilation failed**

```
Error: error building site: SCSS processing failed
```

**Resolution:**

Ensure you have Hugo Extended installed:

```bash
# Check Hugo version (should show "extended")
hugo version
# hugo v0.120.0+extended linux/amd64 ...

# If not extended, reinstall
brew install hugo  # macOS
```

---

### Development Server Issues

**Port already in use**

```
Error: listen tcp 127.0.0.1:1313: bind: address already in use
```

**Resolution:**

```bash
# Use a different port
hugo server -p 1314

# Or kill the existing process
lsof -ti:1313 | xargs kill -9
```

---

**Live reload not working**

**Resolution:**

1. Check browser console for WebSocket errors
2. Try with `--disableFastRender` flag
3. Clear browser cache

```bash
hugo server --disableFastRender
```

---

### Deployment Issues

**GitHub Pages build failing**

**Resolution:**

1. Check GitHub Actions logs for specific errors
2. Verify workflow permissions in Settings > Actions
3. Ensure GitHub Pages is enabled with "GitHub Actions" source

---

**404 errors on deployed site**

**Resolution:**

1. Verify `baseURL` in `config.toml` matches your GitHub Pages URL
2. Check that paths use relative URLs or correct base path
3. Ensure `public/` directory was uploaded correctly

```toml
# For GitHub Pages with custom domain
baseURL = "https://yourdomain.com/"

# For GitHub Pages without custom domain
baseURL = "https://${{ values.destination.owner }}.github.io/${{ values.destination.repo }}/"
```

---

### Content Issues

**Draft content not appearing**

**Resolution:**

Draft content is excluded from production builds. Either:

```bash
# Include drafts in development
hugo server -D

# Or remove draft status from front matter
---
draft: false  # Changed from true
---
```

---

**Images not loading**

**Resolution:**

1. Ensure images are in the `static/` directory
2. Use absolute paths from site root: `/images/photo.jpg`
3. Check file extensions match exactly (case-sensitive)

---

## Related Templates

| Template                                                              | Description                          |
| --------------------------------------------------------------------- | ------------------------------------ |
| [react-spa](/docs/default/template/react-spa)                         | React Single Page Application        |
| [nextjs-website](/docs/default/template/nextjs-website)               | Next.js website with SSR/SSG         |
| [gatsby-blog](/docs/default/template/gatsby-blog)                     | Gatsby static blog                   |
| [jekyll-docs](/docs/default/template/jekyll-docs)                     | Jekyll documentation site            |
| [aws-cloudfront-s3](/docs/default/template/aws-cloudfront-s3)         | S3 + CloudFront static hosting       |
| [azure-static-web-app](/docs/default/template/azure-static-web-app)   | Azure Static Web Apps                |

---

## References

- [Hugo Documentation](https://gohugo.io/documentation/)
- [Hugo Themes](https://themes.gohugo.io/)
- [${{ values.hugoTheme }} Theme Documentation](https://themes.gohugo.io/themes/${{ values.hugoTheme }}/)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [GitHub Actions for Hugo](https://github.com/peaceiris/actions-hugo)
- [Backstage TechDocs](https://backstage.io/docs/features/techdocs/)
- [Markdown Guide](https://www.markdownguide.org/)
- [Hugo Shortcodes](https://gohugo.io/content-management/shortcodes/)
