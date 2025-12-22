# Multi-stage Dockerfile for Backstage
# Builds both frontend and backend for production deployment

# =============================================================================
# Stage 1: Build the application
# =============================================================================
FROM node:22-bookworm-slim AS build

ENV PYTHON=/usr/bin/python3

RUN apt-get update && \
    apt-get install -y --no-install-recommends python3 g++ build-essential git libsqlite3-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy package files for dependency installation
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn
COPY backstage.json ./
COPY packages/app/package.json ./packages/app/
COPY packages/backend/package.json ./packages/backend/

# Install dependencies
RUN yarn install --immutable

# Copy the rest of the source code
COPY . .

# Build the backend (this creates the tarballs)
RUN yarn build:backend

# =============================================================================
# Stage 2: Production image
# =============================================================================
FROM node:22-bookworm-slim AS production

# Labels
LABEL maintainer="Platform Team"
LABEL description="Cloud Sandbox Backstage Developer Portal"
LABEL version="1.0.0"

ENV PYTHON=/usr/bin/python3
ENV NODE_ENV=production
ENV NODE_OPTIONS="--no-node-snapshot"

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        g++ \
        build-essential \
        libsqlite3-dev \
        curl \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Use the node user
USER node

WORKDIR /app

# Copy yarn files
COPY --from=build --chown=node:node /app/.yarn ./.yarn
COPY --from=build --chown=node:node /app/.yarnrc.yml ./
COPY --from=build --chown=node:node /app/backstage.json ./

# Copy the skeleton tarball and extract it
COPY --from=build --chown=node:node /app/yarn.lock /app/package.json /app/packages/backend/dist/skeleton.tar.gz ./
RUN tar xzf skeleton.tar.gz && rm skeleton.tar.gz

# Install production dependencies
RUN yarn workspaces focus --all --production

# Copy examples, catalog, and templates
COPY --chown=node:node examples ./examples
COPY --chown=node:node catalog ./catalog
COPY --chown=node:node templates ./templates

# Copy and extract the bundle
COPY --from=build --chown=node:node /app/packages/backend/dist/bundle.tar.gz ./
RUN tar xzf bundle.tar.gz && rm bundle.tar.gz

# Copy configuration files
COPY --chown=node:node app-config.yaml app-config.production.yaml ./

# Expose port
EXPOSE 7007

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:7007/healthcheck || exit 1

# Start the backend
CMD ["node", "packages/backend", "--config", "app-config.yaml", "--config", "app-config.production.yaml"]
