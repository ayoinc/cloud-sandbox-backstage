# ${{ values.name }}

${{ values.description }}

## Overview

A React frontend application.

## Quick Start

### Prerequisites

- Node.js 18+
- npm or yarn

### Installation

```bash
# Install dependencies
npm install

# Start development server
npm run dev
```

### Building

```bash
npm run build
```

### Testing

```bash
npm test
```

## Project Structure

```
.
├── src/
│   ├── components/      # React components
│   ├── pages/           # Page components
│   ├── hooks/           # Custom hooks
│   ├── services/        # API services
│   └── styles/          # CSS/SCSS files
├── public/              # Static assets
├── tests/               # Test files
├── docs/                # Documentation
└── catalog-info.yaml    # Backstage metadata
```

## Configuration

Environment variables (create `.env.local`):
- `REACT_APP_API_URL`: Backend API URL
- `REACT_APP_AUTH_DOMAIN`: Authentication domain

## Deployment

```bash
npm run build
# Deploy dist/ folder to your hosting provider
```
