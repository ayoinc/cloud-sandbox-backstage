# ${{ values.name }}

${{ values.description }}

## Overview

Next.js application with React, TypeScript, and modern tooling.

## Getting Started

```bash
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000)

## Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run lint` - Run ESLint
- `npm test` - Run tests

## Project Structure

```
├── app/              # App router pages
├── components/       # React components
├── lib/              # Utility functions
├── public/           # Static assets
└── styles/           # CSS/SCSS files
```

## Environment Variables

Copy `.env.example` to `.env.local` and configure.

## Deployment

Build and deploy via CI/CD pipeline or:

```bash
npm run build
npm run start
```

## License

MIT

## Author

${{ values.owner }}
