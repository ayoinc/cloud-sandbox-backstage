# ${{ values.name }}

${{ values.description }}

## Overview

Static marketing site with optimized build and CDN deployment.

## Getting Started

```bash
npm install
npm run dev
```

## Build

```bash
npm run build
```

Output in `dist/` folder.

## Project Structure

```
├── src/
│   ├── pages/        # HTML pages
│   ├── styles/       # CSS files
│   └── scripts/      # JavaScript
├── public/           # Static assets
└── package.json
```

## Deployment

Static files can be deployed to:
- AWS S3
- GitHub Pages
- Netlify
- Vercel

## License

MIT

## Author

${{ values.owner }}
