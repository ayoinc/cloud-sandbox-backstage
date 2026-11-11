FROM node:24-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:24-alpine AS production
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

# adapter-node bundles the app and its dependencies into build/, so the image
# needs no node_modules; package.json marks the output as an ES module.
COPY --from=build /app/package.json ./
COPY --from=build /app/build ./build

# The node user of the base image
USER 1000:1000

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["wget", "-q", "--spider", "http://127.0.0.1:3000/health"]

CMD ["node", "build"]
