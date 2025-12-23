# Node.js API Template

This template creates a production-ready Node.js REST API with Express, TypeScript, and best practices.

## Features

- **Express.js** - Fast, unopinionated web framework
- **TypeScript** - Full type safety
- **OpenAPI/Swagger** - API documentation
- **Jest** - Testing framework
- **Docker** - Containerization ready
- **GitHub Actions** - CI/CD pipeline

## Prerequisites

- Node.js 18+
- npm or yarn
- Docker (optional)

## Quick Start

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Run tests
npm test

# Build for production
npm run build
npm start
```

## Project Structure

```
├── src/
│   ├── controllers/    # Request handlers
│   ├── middleware/     # Express middleware
│   ├── models/         # Data models
│   ├── routes/         # API routes
│   ├── services/       # Business logic
│   ├── utils/          # Utility functions
│   └── index.ts        # Application entry
├── tests/              # Test files
├── docs/               # API documentation
└── Dockerfile          # Container definition
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/api/v1/items` | List items |
| POST | `/api/v1/items` | Create item |
| GET | `/api/v1/items/:id` | Get item |
| PUT | `/api/v1/items/:id` | Update item |
| DELETE | `/api/v1/items/:id` | Delete item |

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | `3000` |
| `NODE_ENV` | Environment | `development` |
| `DATABASE_URL` | Database connection | - |

## Support

Contact the Platform Team for assistance.
