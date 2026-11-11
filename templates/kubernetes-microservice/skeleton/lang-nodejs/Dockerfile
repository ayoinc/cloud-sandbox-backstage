FROM node:24-alpine AS base
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY src ./src

# Built by the pipeline with --target test: runs the unit tests.
FROM base AS test
COPY test ./test
RUN node --test

FROM base

ENV NODE_ENV=production
ENV PORT=8080

USER 10001:10001

EXPOSE 8080

CMD ["node", "src/index.js"]
