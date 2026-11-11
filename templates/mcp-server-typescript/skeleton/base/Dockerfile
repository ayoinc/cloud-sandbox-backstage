FROM node:${{ values.node_version }}-alpine AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY tsconfig.json tsconfig.build.json ./
COPY src ./src
RUN npm run build && npm prune --omit=dev

FROM node:${{ values.node_version }}-alpine
ENV NODE_ENV=production \
    HOST=0.0.0.0 \
    PORT=${{ values.port }}
WORKDIR /app

COPY --from=build /app/package.json ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist

# The server refuses to start on 0.0.0.0 without MCP_AUTH_TOKEN, which is
# supplied at run time and never built into the image.
USER node
EXPOSE ${{ values.port }}

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD ["node", "-e", "fetch('http://127.0.0.1:' + process.env.PORT + '/healthz').then(r => process.exit(r.ok ? 0 : 1), () => process.exit(1))"]

ENTRYPOINT ["node", "dist/index.js"]
