# ${{ values.name }}

Marketing landing page for **${{ values.companyName }}** - ${{ values.tagline }}

## Overview

This is a responsive, production-ready marketing landing page built with modern HTML5, CSS3, and JavaScript. The page is optimized for performance, SEO, and accessibility, with automatic deployment to GitHub Pages.

Key features include:

- Fully responsive design for all device sizes
- CSS custom properties for easy theming
- Smooth scrolling and mobile navigation
- Contact form integration
- Optimized for Core Web Vitals
- Automated CI/CD deployment pipeline

```d2
direction: right

title: {
  label: Landing Page Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

user: User {
  shape: person
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

cdn: CDN / GitHub Pages {
  shape: cloud
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
}

hosting: Static Hosting {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"

  html: index.html {
    shape: document
    style.fill: "#FFECB3"
    style.stroke: "#FFA000"
  }

  assets: Static Assets {
    style.fill: "#FCE4EC"
    style.stroke: "#C2185B"

    css: CSS Styles {
      shape: document
    }
    js: JavaScript {
      shape: document
    }
    images: Images {
      shape: cylinder
    }
  }

  html -> assets.css: links
  html -> assets.js: loads
  html -> assets.images: references
}

analytics: Analytics {
  shape: hexagon
  style.fill: "#E1F5FE"
  style.stroke: "#0288D1"
}

forms: Form Handler {
  shape: hexagon
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"
}

user -> cdn: HTTPS Request
cdn -> hosting: Serves
hosting.html -> analytics: Tracks
hosting.html -> forms: Submits
```

## Configuration Summary

| Setting       | Value                                                               |
| ------------- | ------------------------------------------------------------------- |
| Project Name  | `${{ values.name }}`                                                |
| Company       | `${{ values.companyName }}`                                         |
| Tagline       | `${{ values.tagline }}`                                             |
| Primary Color | `${{ values.primaryColor }}`                                        |
| Owner         | `${{ values.owner }}`                                               |
| Repository    | `${{ values.destination.owner }}/${{ values.destination.repo }}`    |
| Hosting       | GitHub Pages                                                        |
| Framework     | Vanilla HTML/CSS/JS                                                 |

## Project Structure

```
${{ values.name }}/
├── index.html              # Main HTML file with semantic markup
├── css/
│   └── style.css           # CSS styles with custom properties
├── js/
│   └── main.js             # JavaScript for interactivity
├── images/                 # Image assets directory
│   └── .gitkeep
├── docs/
│   └── index.md            # This documentation
├── .github/
│   └── workflows/
│       └── deploy.yaml     # CI/CD pipeline configuration
├── catalog-info.yaml       # Backstage component definition
├── mkdocs.yml              # MkDocs configuration for TechDocs
└── README.md               # Project readme
```

### File Descriptions

| File/Directory       | Purpose                                              |
| -------------------- | ---------------------------------------------------- |
| `index.html`         | Main page with hero, features, about, CTA, contact   |
| `css/style.css`      | Complete styling with CSS variables for theming      |
| `js/main.js`         | Mobile navigation toggle and smooth scrolling        |
| `images/`            | Store logos, hero images, feature icons              |
| `.github/workflows/` | GitHub Actions for validation and deployment         |
| `catalog-info.yaml`  | Backstage service catalog registration               |

---

## CI/CD Pipeline

This repository includes a GitHub Actions pipeline that validates and deploys the landing page automatically.

### Pipeline Features

- **HTML Validation**: Checks for broken links and HTML issues
- **Automatic Deployment**: Deploys to GitHub Pages on push to `main`
- **Environment URL**: Provides deployment URL in GitHub environment

### Pipeline Workflow

```d2
direction: right

pr: Pull Request {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

validate: Validate {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "HTML Validation\nLink Checking"
}

merge: Merge to Main {
  shape: diamond
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"
}

build: Build {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  label: "Setup Pages\nUpload Artifact"
}

deploy: Deploy {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "GitHub Pages\nDeployment"
}

live: Live Site {
  shape: oval
  style.fill: "#C8E6C9"
  style.stroke: "#2E7D32"
}

pr -> validate -> merge -> build -> deploy -> live
```

### Workflow Triggers

| Trigger             | Actions                      |
| ------------------- | ---------------------------- |
| Pull Request        | HTML validation, link checks |
| Push to `main`      | Validate + Deploy            |

---

## Prerequisites

### Required Tools

| Tool         | Version | Purpose                    |
| ------------ | ------- | -------------------------- |
| Git          | 2.30+   | Version control            |
| Node.js      | 18+     | Local development server   |
| Python       | 3.8+    | Alternative local server   |
| Modern browser | Latest | Testing and development   |

### Optional Tools

| Tool                | Purpose                                |
| ------------------- | -------------------------------------- |
| VS Code Live Server | Hot-reload development                 |
| ImageOptim          | Image optimization                     |
| Lighthouse          | Performance/SEO auditing               |
| axe DevTools        | Accessibility testing                  |

### GitHub Repository Setup

#### Enable GitHub Pages

1. Navigate to **Settings > Pages**
2. Under "Build and deployment", select **GitHub Actions** as the source
3. The workflow will handle deployment automatically

#### Required Permissions

The workflow requires these permissions (already configured):

```yaml
permissions:
  pages: write      # Deploy to GitHub Pages
  id-token: write   # OIDC token for deployment
```

---

## Usage

### Local Development

#### Option 1: Python HTTP Server

```bash
# Clone the repository
git clone <repository-url>
cd ${{ values.name }}

# Start local server
python -m http.server 8000

# Open in browser
open http://localhost:8000
```

#### Option 2: Node.js Serve

```bash
# Install serve globally (one-time)
npm install -g serve

# Clone and run
git clone <repository-url>
cd ${{ values.name }}
serve .

# Open http://localhost:3000
```

#### Option 3: VS Code Live Server

1. Install the "Live Server" extension in VS Code
2. Open the project folder
3. Right-click `index.html` and select "Open with Live Server"
4. Changes will auto-reload in the browser

### Build for Production

This is a static site, so no build step is required. However, you can optimize assets:

```bash
# Minify CSS (optional)
npx csso css/style.css --output css/style.min.css

# Minify JavaScript (optional)
npx terser js/main.js --output js/main.min.js

# Optimize images (optional)
npx imagemin images/* --out-dir=images/optimized
```

### Deploy

#### Automatic Deployment

Push to the `main` branch to trigger automatic deployment:

```bash
git add .
git commit -m "Update landing page content"
git push origin main
```

The site will be available at: `https://${{ values.destination.owner }}.github.io/${{ values.destination.repo }}/`

#### Manual Deployment

1. Navigate to **Actions** tab in GitHub
2. Select **Deploy Landing Page** workflow
3. Click **Run workflow**
4. Select the `main` branch
5. Click **Run workflow**

---

## Customization Guide

### Theme Colors

Edit CSS custom properties in `css/style.css`:

```css
:root {
  /* Primary brand color */
  --primary-color: ${{ values.primaryColor }};
  
  /* Automatically calculated darker shade */
  --primary-dark: color-mix(in srgb, ${{ values.primaryColor }} 80%, black);
  
  /* Text colors */
  --text-color: #333;
  --text-light: #666;
  
  /* Backgrounds */
  --background: #fff;
  --background-alt: #f8f9fa;
  
  /* UI elements */
  --border-radius: 8px;
  --shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}
```

### Color Palette Examples

| Theme      | Primary Color | Usage                    |
| ---------- | ------------- | ------------------------ |
| Blue       | `#2196F3`     | Technology, Trust        |
| Green      | `#4CAF50`     | Health, Environment      |
| Purple     | `#9C27B0`     | Creative, Luxury         |
| Orange     | `#FF9800`     | Energy, Action           |
| Red        | `#F44336`     | Urgency, Bold            |

### Content Sections

Edit `index.html` to customize:

#### Hero Section

```html
<section class="hero">
  <div class="container">
    <h1>Your Compelling Headline</h1>
    <p>Your value proposition goes here</p>
    <div class="hero-buttons">
      <a href="#cta" class="btn btn-primary btn-large">Primary CTA</a>
      <a href="#features" class="btn btn-secondary btn-large">Secondary CTA</a>
    </div>
  </div>
</section>
```

#### Feature Cards

```html
<div class="feature-card">
  <div class="feature-icon">
    <!-- Replace with SVG icon or emoji -->
    <svg>...</svg>
  </div>
  <h3>Feature Title</h3>
  <p>Feature description text.</p>
</div>
```

### Adding New Sections

1. Add HTML section in `index.html`:

```html
<section id="testimonials" class="testimonials">
  <div class="container">
    <h2>What Our Customers Say</h2>
    <!-- Testimonial content -->
  </div>
</section>
```

2. Add corresponding styles in `css/style.css`:

```css
.testimonials {
  padding: 80px 0;
  background: var(--background-alt);
}
```

3. Add navigation link:

```html
<li><a href="#testimonials">Testimonials</a></li>
```

### Typography

The page uses system fonts for optimal performance:

```css
font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 
             Oxygen, Ubuntu, sans-serif;
```

To use custom fonts:

```html
<!-- Add to <head> in index.html -->
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;700&display=swap" rel="stylesheet">
```

```css
/* Update in style.css */
body {
  font-family: 'Inter', sans-serif;
}
```

---

## Performance Optimization

### Current Optimizations

| Optimization              | Status    | Impact                    |
| ------------------------- | --------- | ------------------------- |
| System fonts              | Enabled   | No font loading delay     |
| CSS custom properties     | Enabled   | Smaller CSS file          |
| Minimal JavaScript        | Enabled   | Fast interactivity        |
| No external dependencies  | Enabled   | Reduced HTTP requests     |
| Semantic HTML             | Enabled   | Better parsing            |

### Recommended Optimizations

#### Image Optimization

```bash
# Convert images to WebP format
for file in images/*.{jpg,png}; do
  cwebp "$file" -o "${file%.*}.webp"
done
```

Use responsive images in HTML:

```html
<picture>
  <source srcset="images/hero.webp" type="image/webp">
  <source srcset="images/hero.jpg" type="image/jpeg">
  <img src="images/hero.jpg" alt="Hero image" loading="lazy">
</picture>
```

#### Critical CSS

Inline critical CSS for above-the-fold content:

```html
<head>
  <style>
    /* Inline critical styles here */
    .hero { ... }
    .header { ... }
  </style>
  <link rel="stylesheet" href="css/style.css" media="print" onload="this.media='all'">
</head>
```

#### Preload Key Resources

```html
<head>
  <link rel="preload" href="css/style.css" as="style">
  <link rel="preload" href="js/main.js" as="script">
  <link rel="preload" href="images/hero.webp" as="image">
</head>
```

### Performance Targets

| Metric                    | Target    | Tool                   |
| ------------------------- | --------- | ---------------------- |
| Lighthouse Performance    | 95+       | Chrome DevTools        |
| First Contentful Paint    | < 1.5s    | PageSpeed Insights     |
| Largest Contentful Paint  | < 2.5s    | PageSpeed Insights     |
| Cumulative Layout Shift   | < 0.1     | PageSpeed Insights     |
| Total Page Size           | < 500KB   | Chrome Network tab     |

---

## SEO Configuration

### Current SEO Features

The template includes essential SEO elements:

```html
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="${{ values.description }}">
  <title>${{ values.companyName }} - ${{ values.tagline }}</title>
</head>
```

### Enhanced SEO Setup

Add these meta tags for better SEO:

```html
<head>
  <!-- Basic Meta -->
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="${{ values.description }}">
  <meta name="keywords" content="keyword1, keyword2, keyword3">
  <meta name="author" content="${{ values.companyName }}">
  
  <!-- Open Graph (Facebook, LinkedIn) -->
  <meta property="og:title" content="${{ values.companyName }} - ${{ values.tagline }}">
  <meta property="og:description" content="${{ values.description }}">
  <meta property="og:image" content="https://example.com/images/og-image.jpg">
  <meta property="og:url" content="https://example.com">
  <meta property="og:type" content="website">
  
  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${{ values.companyName }}">
  <meta name="twitter:description" content="${{ values.description }}">
  <meta name="twitter:image" content="https://example.com/images/twitter-card.jpg">
  
  <!-- Canonical URL -->
  <link rel="canonical" href="https://example.com">
  
  <!-- Favicon -->
  <link rel="icon" type="image/png" href="/images/favicon.png">
  <link rel="apple-touch-icon" href="/images/apple-touch-icon.png">
  
  <title>${{ values.companyName }} - ${{ values.tagline }}</title>
</head>
```

### Structured Data

Add JSON-LD for rich search results:

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "${{ values.companyName }}",
  "url": "https://example.com",
  "logo": "https://example.com/images/logo.png",
  "description": "${{ values.description }}",
  "sameAs": [
    "https://twitter.com/yourcompany",
    "https://linkedin.com/company/yourcompany"
  ]
}
</script>
```

### Sitemap

Create `sitemap.xml` in the root:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://example.com/</loc>
    <lastmod>2024-01-01</lastmod>
    <priority>1.0</priority>
  </url>
</urlset>
```

### robots.txt

Create `robots.txt` in the root:

```
User-agent: *
Allow: /

Sitemap: https://example.com/sitemap.xml
```

---

## Troubleshooting

### Deployment Issues

**Error: Pages build and deployment failed**

```
Error: No uploaded artifact was found!
```

**Resolution:**
1. Verify GitHub Pages is enabled in repository settings
2. Check that the workflow has `pages: write` permission
3. Ensure artifact upload step completed successfully

**Error: 404 Page Not Found after deployment**

**Resolution:**
1. Verify `index.html` exists in the repository root
2. Check the deployment URL is correct
3. Wait a few minutes for DNS propagation

### Local Development Issues

**Error: Port already in use**

```bash
# Find and kill process using the port
lsof -i :8000
kill -9 <PID>

# Or use a different port
python -m http.server 8080
```

**Error: CSS changes not reflecting**

**Resolution:**
1. Hard refresh the browser (Cmd+Shift+R / Ctrl+Shift+R)
2. Clear browser cache
3. Check for CSS syntax errors in DevTools

### Styling Issues

**Problem: Colors not applying correctly**

**Resolution:**
1. Verify CSS custom property syntax: `var(--primary-color)`
2. Check for typos in property names
3. Ensure `:root` block is at the top of the CSS file

**Problem: Mobile menu not working**

**Resolution:**
1. Verify `js/main.js` is loaded correctly
2. Check browser console for JavaScript errors
3. Ensure `.nav-toggle` and `.nav-menu` classes match

### Form Issues

**Problem: Contact form not submitting**

The default form uses browser validation but needs a backend handler. Options:

1. **Formspree** (no backend required):
```html
<form action="https://formspree.io/f/YOUR_FORM_ID" method="POST">
```

2. **Netlify Forms** (if using Netlify):
```html
<form name="contact" netlify>
```

3. **Custom backend endpoint**:
```html
<form action="/api/contact" method="POST">
```

---

## Related Templates

| Template                                                                  | Description                          |
| ------------------------------------------------------------------------- | ------------------------------------ |
| [nextjs-landing-page](/docs/default/template/nextjs-landing-page)         | Next.js landing page with React      |
| [gatsby-marketing-site](/docs/default/template/gatsby-marketing-site)     | Gatsby static site generator         |
| [react-spa](/docs/default/template/react-spa)                             | React single-page application        |
| [documentation-site](/docs/default/template/documentation-site)           | MkDocs documentation website         |
| [static-website-s3](/docs/default/template/static-website-s3)             | AWS S3 + CloudFront hosting          |

---

## References

- [HTML5 Specification](https://html.spec.whatwg.org/)
- [CSS Custom Properties](https://developer.mozilla.org/en-US/docs/Web/CSS/Using_CSS_custom_properties)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [Web Vitals](https://web.dev/vitals/)
- [Schema.org Structured Data](https://schema.org/)
- [Google Search Central](https://developers.google.com/search)
- [Lighthouse Performance Auditing](https://developers.google.com/web/tools/lighthouse)
- [Web Accessibility Guidelines (WCAG)](https://www.w3.org/WAI/standards-guidelines/wcag/)
