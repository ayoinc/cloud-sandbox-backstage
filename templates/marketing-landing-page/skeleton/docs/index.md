# ${{ values.name }}

${{ values.description }}

## Overview

This is a responsive marketing landing page for **${{ values.companyName }}**.

## Development

### Local Development

Open `index.html` in a browser, or use a local server:

```bash
# Using Python
python -m http.server 8000

# Using Node.js
npx serve .
```

### Structure

```
.
├── index.html      # Main HTML file
├── css/
│   └── style.css   # Styles
├── js/
│   └── main.js     # JavaScript
└── images/         # Image assets
```

## Customization

### Colors

Edit the CSS variables in `css/style.css`:

```css
:root {
  --primary-color: ${{ values.primaryColor }};
}
```

### Content

Edit `index.html` to update:
- Hero section text
- Features
- Call-to-action buttons
- Footer content

## Deployment

The page automatically deploys to GitHub Pages on push to `main`.
