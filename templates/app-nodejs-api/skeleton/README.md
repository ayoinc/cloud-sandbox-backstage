# ${{ values.name }}

${{ values.description }}

## Overview

Node.js REST API with Express, TypeScript, and comprehensive tooling.

## Getting Started

```bash
npm install
npm run dev
```

API available at [http://localhost:3000](http://localhost:3000)

## Scripts

- `npm run dev` - Start development server with hot reload
- `npm run build` - Compile TypeScript
- `npm run start` - Start production server
- `npm run lint` - Run ESLint
- `npm test` - Run tests

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /health | Health check |
| GET | /api/v1/* | API routes |

## Project Structure

```
├── src/
│   ├── controllers/  # Route handlers
│   ├── middleware/   # Express middleware
│   ├── models/       # Data models
│   ├── routes/       # API routes
│   └── index.ts      # Entry point
└── tests/            # Test files
```

## Environment Variables

Copy `.env.example` to `.env` and configure.

## License

MIT

## Author

${{ values.owner }}
