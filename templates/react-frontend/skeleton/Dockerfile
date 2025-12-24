# syntax=docker/dockerfile:1

# =============================================================================
# React Frontend Application Dockerfile
# Multi-stage build for production-optimized static file serving with nginx
# =============================================================================

ARG NODE_VERSION=22
ARG NGINX_VERSION=1.27

# =============================================================================
# Stage 1: Dependencies
# =============================================================================
FROM node:${NODE_VERSION}-alpine AS deps

# Install pnpm
RUN corepack enable && corepack prepare pnpm@9 --activate

WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# =============================================================================
# Stage 2: Build
# =============================================================================
FROM node:${NODE_VERSION}-alpine AS builder

# Install pnpm
RUN corepack enable && corepack prepare pnpm@9 --activate

WORKDIR /app

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy source files
COPY . .

# Build arguments for environment variables
ARG VITE_API_URL=/api
ARG VITE_APP_ENV=production

# Set environment variables for build
ENV VITE_API_URL=${VITE_API_URL}
ENV VITE_APP_ENV=${VITE_APP_ENV}

# Build the application
RUN pnpm run build

# =============================================================================
# Stage 3: Production
# =============================================================================
FROM nginx:${NGINX_VERSION}-alpine AS production

# Install required packages
RUN apk add --no-cache \
    curl \
    tini

# Remove default nginx config
RUN rm -rf /etc/nginx/conf.d/*

# Copy custom nginx configuration
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/default.conf /etc/nginx/conf.d/default.conf

# Copy built application from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Create non-root user for nginx
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup && \
    chown -R appuser:appgroup /usr/share/nginx/html && \
    chown -R appuser:appgroup /var/cache/nginx && \
    chown -R appuser:appgroup /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown appuser:appgroup /var/run/nginx.pid

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Expose port
EXPOSE 8080

# Use tini as init system
ENTRYPOINT ["/sbin/tini", "--"]

# Switch to non-root user
USER appuser

# Start nginx
CMD ["nginx", "-g", "daemon off;"]

# =============================================================================
# Stage 4: Development
# =============================================================================
FROM node:${NODE_VERSION}-alpine AS development

# Install pnpm
RUN corepack enable && corepack prepare pnpm@9 --activate

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

WORKDIR /app

# Copy package files
COPY --chown=appuser:appgroup package.json pnpm-lock.yaml ./

# Install all dependencies (including dev)
RUN pnpm install

# Copy source files
COPY --chown=appuser:appgroup . .

# Switch to non-root user
USER appuser

# Expose development server port
EXPOSE 5173

# Start development server
CMD ["pnpm", "run", "dev", "--host", "0.0.0.0"]
