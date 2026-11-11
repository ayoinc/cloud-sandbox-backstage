# syntax=docker/dockerfile:1

FROM node:24-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build && npm prune --omit=dev

FROM node:24-slim
ENV NODE_ENV=production
WORKDIR /app
COPY --from=build /app/package.json ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
{% if values.databaseType == 'sqlite' %}
# The SQLite database file lives here: mount a volume to keep it.
RUN mkdir data && chown node:node data
{% endif %}
USER node
EXPOSE 4000
CMD ["node", "--import", "./dist/instrument.js", "dist/index.js"]
