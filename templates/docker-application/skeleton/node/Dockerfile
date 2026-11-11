FROM ${{ values.baseImage }} AS base
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
ENV PORT=${{ values.port }}

USER 10001:10001

EXPOSE ${{ values.port }}
{%- if values.includeHealthcheck %}

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["wget", "-q", "--spider", "http://127.0.0.1:${{ values.port }}/health"]
{%- endif %}

CMD ["node", "src/index.js"]
