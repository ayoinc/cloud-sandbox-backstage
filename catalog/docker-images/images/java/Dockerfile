# Java/Spring Boot Base Image
# Multi-stage build with layer extraction for efficient caching
# Uses Eclipse Temurin for production-grade JVM

ARG JAVA_VERSION=21
ARG ALPINE_VERSION=3.19

# =============================================================================
# Builder stage for compiling with Gradle
# =============================================================================
FROM eclipse-temurin:${JAVA_VERSION}-jdk-alpine AS builder

WORKDIR /app

# Install build tools
RUN apk add --no-cache bash

# Copy Gradle wrapper and build files first for caching
COPY gradlew ./
COPY gradle ./gradle
COPY build.gradle.kts settings.gradle.kts ./

# Download dependencies (this layer will be cached)
RUN ./gradlew dependencies --no-daemon --console=plain

# Copy source code
COPY src ./src

# Build the application
RUN ./gradlew bootJar --no-daemon --console=plain -x test

# Extract layers for better Docker caching
RUN java -Djarmode=layertools -jar build/libs/*.jar extract --destination extracted

# =============================================================================
# Production stage - JRE only for minimal footprint
# =============================================================================
FROM eclipse-temurin:${JAVA_VERSION}-jre-alpine AS production

# Labels for metadata
LABEL org.opencontainers.image.title="Java/Spring Boot Application" \
      org.opencontainers.image.description="Production-ready Spring Boot base image" \
      org.opencontainers.image.vendor="Platform Team" \
      org.opencontainers.image.licenses="MIT"

# Install runtime dependencies
RUN apk add --no-cache \
    tini \
    curl \
    && rm -rf /var/cache/apk/*

# Create non-root user
RUN addgroup -g 1001 -S spring && \
    adduser -S spring -u 1001 -G spring && \
    mkdir -p /app/logs /app/tmp && \
    chown -R spring:spring /app

WORKDIR /app

# Copy layers in order of change frequency (least to most)
COPY --from=builder --chown=spring:spring /app/extracted/dependencies/ ./
COPY --from=builder --chown=spring:spring /app/extracted/spring-boot-loader/ ./
COPY --from=builder --chown=spring:spring /app/extracted/snapshot-dependencies/ ./
COPY --from=builder --chown=spring:spring /app/extracted/application/ ./

# JVM configuration for containers
ENV JAVA_OPTS="-XX:+UseContainerSupport \
    -XX:MaxRAMPercentage=75.0 \
    -XX:InitialRAMPercentage=50.0 \
    -XX:+ExitOnOutOfMemoryError \
    -Djava.security.egd=file:/dev/./urandom \
    -Dspring.profiles.active=production"

ENV PORT=8080

# Switch to non-root user
USER spring

# Health check using Spring Actuator
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:${PORT}/actuator/health || exit 1

# Expose application port
EXPOSE ${PORT}

# Use tini for proper signal handling
ENTRYPOINT ["/sbin/tini", "--"]

# Start the application with layered jar launcher
CMD ["sh", "-c", "java ${JAVA_OPTS} org.springframework.boot.loader.launch.JarLauncher"]
