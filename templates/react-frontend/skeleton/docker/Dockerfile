FROM node:22-alpine AS build
WORKDIR /app

# package-lock.json is copied when the repository has one; npm install then
# installs exactly the versions it records.
COPY package.json package-lock.json* ./
RUN npm install --no-audit --no-fund

COPY . .

# Optional: API base URL compiled into the bundle instead of the default in
# src/app.json (docker build --build-arg VITE_API_BASE_URL=https://...).
ARG VITE_API_BASE_URL=""
ENV VITE_API_BASE_URL=${VITE_API_BASE_URL}

RUN npm run build

# nginx that runs without root privileges and listens on port 8080.
FROM nginxinc/nginx-unprivileged:1.30-alpine AS production

COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

# The nginx user of the base image
USER 101:101

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["wget", "-q", "--spider", "http://127.0.0.1:8080/healthz"]
