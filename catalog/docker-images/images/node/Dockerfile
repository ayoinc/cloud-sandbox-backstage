# Node.js Base Image
# Multi-stage build for production applications
# Supports both builder and production stages

ARG NODE_VERSION=20
ARG ALPINE_VERSION=3.19

# =============================================================================
# Base stage with common configurations
# =============================================================================
FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION} AS base

# Install security updates and common utilities
RUN apk update && apk upgrade && \
    apk add --no-cache \
        tini \
        dumb-init \
    && rm -rf /var/cache/apk/*

# Set npm configuration for better performance and security
RUN npm config set fund false && \
    npm config set audit-level critical && \
    npm config set update-notifier false

WORKDIR /app

# =============================================================================
# Builder stage for compiling TypeScript and installing dependencies
# =============================================================================
FROM base AS builder

# Install build dependencies
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    && rm -rf /var/cache/apk/*

# Copy package files first for better caching
COPY package*.json ./

# Install all dependencies (including devDependencies for build)
RUN npm ci && npm cache clean --force

# Copy source code
COPY . .

# Build application (TypeScript, bundling, etc.)
RUN npm run build --if-present

# Remove devDependencies for production
RUN npm prune --production && npm cache clean --force

# =============================================================================
# Production stage - minimal image for running the application
# =============================================================================
FROM base AS production

# Labels for metadata
LABEL org.opencontainers.image.title="Node.js Application" \
      org.opencontainers.image.description="Production-ready Node.js base image" \
      org.opencontainers.image.vendor="Platform Team" \
      org.opencontainers.image.licenses="MIT"

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs && \
    mkdir -p /app/logs /app/tmp && \
    chown -R nodejs:nodejs /app

# Copy production artifacts from builder
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/package.json ./

# Environment configuration
ENV NODE_ENV=production \
    PORT=3000 \
    # Disable npm update checks
    NO_UPDATE_NOTIFIER=1 \
    # Reduce memory footprint
    NODE_OPTIONS="--max-old-space-size=512"

# Switch to non-root user
USER nodejs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD node -e "require('http').get('http://localhost:${PORT}/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

# Expose application port
EXPOSE ${PORT}

# Use tini as init process for proper signal handling
ENTRYPOINT ["/sbin/tini", "--"]

# Default command - override in derived images
CMD ["node", "dist/main.js"]
