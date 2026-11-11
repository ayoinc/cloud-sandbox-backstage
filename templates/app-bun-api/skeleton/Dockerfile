FROM oven/bun:1.4.4-slim AS dependencies
WORKDIR /app
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile --production

FROM oven/bun:1.4.4-slim AS production
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=${{ values.port }}

COPY --from=dependencies /app/node_modules ./node_modules
COPY package.json ./
COPY src ./src

# The unprivileged bun user of the base image
USER 1000:1000

EXPOSE ${{ values.port }}

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["bun", "-e", "const r = await fetch(`http://127.0.0.1:${Bun.env.PORT}/health/live`); process.exit(r.ok ? 0 : 1)"]

CMD ["bun", "src/index.ts"]
