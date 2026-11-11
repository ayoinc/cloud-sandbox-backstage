# syntax=docker/dockerfile:1

FROM node:24-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
# Set to the address of a content delivery network to load the built assets from there.
ARG ASSET_BASE_URL=/
RUN ASSET_BASE_URL="$ASSET_BASE_URL" npm run build

FROM nginxinc/nginx-unprivileged:1.29-alpine
COPY nginx.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/dist /usr/share/nginx/html
# Where the API is reached from this container.
ENV BACKEND_URL=http://backend:8080
EXPOSE 8080
