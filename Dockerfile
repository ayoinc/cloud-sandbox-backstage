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

# Install runtime dependencies including Python pip for mkdocs
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
        g++ \
        build-essential \
        libsqlite3-dev \
        curl \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install D2 diagramming tool (direct binary download for reliability)
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "arm64" ]; then D2_ARCH="linux-arm64"; else D2_ARCH="linux-amd64"; fi && \
    D2_VERSION="v0.7.1" && \
    curl -fsSL "https://github.com/terrastruct/d2/releases/download/${D2_VERSION}/d2-${D2_VERSION}-${D2_ARCH}.tar.gz" -o /tmp/d2.tar.gz && \
    mkdir -p /tmp/d2 && \
    tar -xzf /tmp/d2.tar.gz -C /tmp/d2 --strip-components=1 && \
    cp /tmp/d2/bin/d2 /usr/local/bin/d2 && \
    chmod +x /usr/local/bin/d2 && \
    rm -rf /tmp/d2 /tmp/d2.tar.gz && \
    d2 --version

# Install mkdocs and plugins for TechDocs generation (including D2 support)
RUN pip3 install --break-system-packages \
    mkdocs \
    mkdocs-material \
    mkdocs-techdocs-core \
    mkdocs-monorepo-plugin \
    mkdocs-d2-plugin

# Install MinIO client for TechDocs upload
RUN curl -fsSL https://dl.min.io/client/mc/release/linux-amd64/mc -o /usr/local/bin/mc && \
    chmod +x /usr/local/bin/mc

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

# Pre-build TechDocs for all components with mkdocs.yml
RUN for dir in catalog/*/; do \
      if [ -f "${dir}mkdocs.yml" ]; then \
        echo "Building TechDocs for ${dir}"; \
        cd "/app/${dir}" && mkdocs build -d /app/techdocs-output/$(basename ${dir}) && cd /app; \
      fi; \
    done && \
    for dir in templates/*/; do \
      if [ -f "${dir}mkdocs.yml" ]; then \
        echo "Building TechDocs for ${dir}"; \
        cd "/app/${dir}" && mkdocs build -d /app/techdocs-output/$(basename ${dir}) && cd /app; \
      fi; \
    done || true

# Copy and extract the bundle
COPY --from=build --chown=node:node /app/packages/backend/dist/bundle.tar.gz ./
RUN tar xzf bundle.tar.gz && rm bundle.tar.gz

# Copy configuration files
COPY --chown=node:node app-config.yaml app-config.production.yaml ./

# Copy entrypoint script
COPY --chown=node:node docker/entrypoint.sh ./entrypoint.sh

# Expose port
EXPOSE 7007

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:7007/healthcheck || exit 1

# Start the backend via entrypoint script
CMD ["./entrypoint.sh"]
