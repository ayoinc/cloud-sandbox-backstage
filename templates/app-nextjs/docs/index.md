# Next.js Application Template

This template creates a production-ready Next.js application with TypeScript, testing, and CI/CD.

## Features

- **Next.js 14** - Latest App Router with React Server Components
- **TypeScript** - Full type safety
- **Tailwind CSS** - Utility-first styling
- **ESLint & Prettier** - Code quality tools
- **Jest & Testing Library** - Unit and integration tests
- **GitHub Actions** - CI/CD pipeline

## Prerequisites

- Node.js 18+
- npm or yarn
- Git

## Quick Start

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build

# Run tests
npm test
```

## Project Structure

```
├── app/                # App Router pages and layouts
│   ├── layout.tsx      # Root layout
│   ├── page.tsx        # Home page
│   └── api/            # API routes
├── components/         # React components
├── lib/                # Utility functions
├── public/             # Static assets
├── styles/             # Global styles
└── tests/              # Test files
```

## Environment Variables

| Variable              | Description                | Required |
| --------------------- | -------------------------- | -------- |
| `NEXT_PUBLIC_API_URL` | Backend API URL            | Yes      |
| `DATABASE_URL`        | Database connection string | No       |

## Deployment

The application can be deployed to:

- Vercel (recommended)
- AWS Amplify
- Docker container

## Support

Contact the Platform Team for assistance.
