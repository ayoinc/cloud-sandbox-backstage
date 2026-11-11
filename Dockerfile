# syntax=docker/dockerfile:1
#
# Multi-stage build of the Backstage app + backend, based on the official
# https://backstage.io/docs/deployment/docker#multi-stage-build, extended with the
# TechDocs toolchain (mkdocs + d2) because TechDocs is generated in-process
# (`techdocs.generator.runIn: local`) and pre-built sites are published to MinIO.
#
# Targets:
#   toolchain  - Node 24 + mkdocs/techdocs-core + d2 + mc (TechDocs generator, dev base)
#   dev        - toolchain + native build deps for running `yarn start` from a bind mount
#   (default)  - production image
#
# Build: docker build -t backstage:local .

ARG NODE_IMAGE=node:24-trixie-slim

# MinIO stopped publishing images/binaries; Chainguard builds mc from source (static binary).
FROM cgr.dev/chainguard/minio-client:latest AS mc
FROM terrastruct/d2:v0.9.0 AS d2

# -----------------------------------------------------------------------------
# TechDocs toolchain
# -----------------------------------------------------------------------------
FROM ${NODE_IMAGE} AS toolchain

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends python3 python3-venv && \
    rm -rf /var/lib/apt/lists/*

ENV VIRTUAL_ENV=/opt/techdocs \
    PATH=/opt/techdocs/bin:$PATH
RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m venv "$VIRTUAL_ENV" && \
    pip install \
        mkdocs-techdocs-core==1.7.1 \
        mkdocs-d2-plugin==1.7.0 \
        mkdocs-monorepo-plugin==1.1.2 \
        mkdocs-awesome-pages-plugin==2.10.1 && \
    mkdocs --version

COPY --from=d2 /usr/local/bin/d2 /usr/local/bin/d2
COPY --from=mc /usr/bin/mc /usr/local/bin/mc
COPY docker/build-techdocs.sh /usr/local/bin/build-techdocs

# -----------------------------------------------------------------------------
# Development image: source is bind-mounted, deps installed into volumes at start
# -----------------------------------------------------------------------------
FROM toolchain AS dev

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends libsqlite3-dev g++ make git && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
EXPOSE 3000 7007 9229
CMD ["sh", "-c", "yarn install --immutable && yarn start"]

# -----------------------------------------------------------------------------
# Stage 1 - yarn install skeleton (only package.json files) for layer caching
# -----------------------------------------------------------------------------
FROM ${NODE_IMAGE} AS packages

WORKDIR /app
COPY backstage.json package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn
COPY packages packages
RUN find packages \! -name "package.json" -mindepth 2 -maxdepth 2 -exec rm -rf {} \+
# The Cloudflare Worker is a workspace too; yarn needs its manifest to install.
COPY edge/package.json edge/package.json

# -----------------------------------------------------------------------------
# Stage 2 - install dependencies and build packages
# -----------------------------------------------------------------------------
FROM ${NODE_IMAGE} AS build

# python3/g++/make: node-gyp builds for deps without linux-arm64/Node 24 prebuilds
# (tree-sitter via swagger-ui's apidom, ssh2's cpu-features). Build stage only.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends libsqlite3-dev python3 g++ make && \
    rm -rf /var/lib/apt/lists/*

USER node
WORKDIR /app

COPY --from=packages --chown=node:node /app .
RUN --mount=type=cache,target=/home/node/.yarn/berry,sharing=locked,uid=1000,gid=1000 \
    yarn install --immutable

COPY --chown=node:node . .
RUN yarn tsc
RUN yarn --cwd packages/backend build
RUN mkdir packages/backend/dist/skeleton packages/backend/dist/bundle \
    && tar xzf packages/backend/dist/skeleton.tar.gz -C packages/backend/dist/skeleton \
    && tar xzf packages/backend/dist/bundle.tar.gz -C packages/backend/dist/bundle

# -----------------------------------------------------------------------------
# Pre-built TechDocs sites (uploaded to MinIO by the entrypoint)
# -----------------------------------------------------------------------------
FROM toolchain AS techdocs

WORKDIR /src
COPY catalog ./catalog
COPY templates ./templates
RUN build-techdocs /techdocs-output

# -----------------------------------------------------------------------------
# Stage 3 - production image
# -----------------------------------------------------------------------------
FROM toolchain AS production

LABEL org.opencontainers.image.title="cloud-sandbox-backstage" \
      org.opencontainers.image.description="Cloud Sandbox Backstage Developer Portal" \
      org.opencontainers.image.source="https://github.com/ayoinc/cloud-sandbox-backstage"

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends libsqlite3-dev && \
    rm -rf /var/lib/apt/lists/*

# From here on we use the least-privileged `node` user to run the backend.
USER node
WORKDIR /app

COPY --from=build --chown=node:node /app/.yarn ./.yarn
COPY --from=build --chown=node:node /app/.yarnrc.yml ./
COPY --from=build --chown=node:node /app/backstage.json ./
COPY --from=build --chown=node:node /app/yarn.lock /app/package.json /app/packages/backend/dist/skeleton/ ./

RUN --mount=type=cache,target=/home/node/.yarn/berry,sharing=locked,uid=1000,gid=1000 \
    yarn workspaces focus --all --production && rm -rf "$(yarn cache clean)"

COPY --from=build --chown=node:node /app/packages/backend/dist/bundle/ ./

# Runtime files: config, catalog/templates (file locations), examples, TechDocs output
COPY --chown=node:node app-config.yaml app-config.production.yaml ./
COPY --chown=node:node examples ./examples
COPY --chown=node:node catalog ./catalog
COPY --chown=node:node templates ./templates
COPY --from=techdocs --chown=node:node /techdocs-output ./techdocs-output
COPY --chown=node:node docker/entrypoint.sh ./entrypoint.sh

# This switches many Node.js dependencies to production mode.
ENV NODE_ENV=production

EXPOSE 7007

HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
    CMD ["node", "-e", "fetch('http://127.0.0.1:7007/.backstage/health/v1/readiness').then(r => process.exit(r.ok ? 0 : 1), () => process.exit(1))"]

CMD ["./entrypoint.sh"]
