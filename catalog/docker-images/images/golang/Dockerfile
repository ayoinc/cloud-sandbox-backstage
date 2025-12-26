# Go Base Image
# Multi-stage build for minimal production binaries
# Uses distroless for maximum security

ARG GO_VERSION=1.22
ARG ALPINE_VERSION=3.19

# =============================================================================
# Builder stage for compiling the application
# =============================================================================
FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} AS builder

# Install build dependencies
RUN apk add --no-cache \
    git \
    ca-certificates \
    tzdata \
    && update-ca-certificates

WORKDIR /app

# Download dependencies first for better caching
COPY go.mod go.sum ./
RUN go mod download && go mod verify

# Copy source code
COPY . .

# Build arguments for versioning
ARG VERSION=dev
ARG COMMIT=unknown
ARG BUILD_TIME=unknown

# Build the binary with optimizations
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s -X main.version=${VERSION} -X main.commit=${COMMIT} -X main.buildTime=${BUILD_TIME} -extldflags '-static'" \
    -trimpath \
    -o /app/server \
    ./cmd/server

# =============================================================================
# Production stage - distroless for minimal attack surface
# =============================================================================
FROM gcr.io/distroless/static-debian12:nonroot AS production

# Labels for metadata
LABEL org.opencontainers.image.title="Go Application" \
      org.opencontainers.image.description="Production-ready Go application using distroless" \
      org.opencontainers.image.vendor="Platform Team" \
      org.opencontainers.image.licenses="MIT"

# Copy CA certificates for HTTPS
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy timezone data
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Copy binary from builder
COPY --from=builder /app/server /server

# Environment configuration
ENV PORT=8080 \
    TZ=UTC

# Use non-root user (provided by distroless:nonroot)
USER nonroot:nonroot

# Expose application port
EXPOSE ${PORT}

# Entry point
ENTRYPOINT ["/server"]

# =============================================================================
# Debug stage - includes shell for debugging (don't use in production)
# =============================================================================
FROM gcr.io/distroless/static-debian12:debug-nonroot AS debug

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /app/server /server

USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/server"]
