# syntax=docker/dockerfile:1

FROM bufbuild/buf:1.75.0 AS buf

FROM golang:1.27-alpine AS build
WORKDIR /src
COPY --from=buf /usr/local/bin/buf /usr/local/bin/buf

COPY go.mod go.sum ./
RUN go mod download

COPY . .
ARG VERSION=${{ values.serviceVersion }}
RUN buf generate
RUN CGO_ENABLED=0 go build -trimpath \
      -ldflags "-s -w -X ${{ values.modulePath }}/internal/version.Version=${VERSION}" \
      -o /out/server ./cmd/server

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/server /server
# 50051: gRPC${{ '. 9090: Prometheus metrics.' if values.enableMetrics else '.' }}
EXPOSE 50051${{ ' 9090' if values.enableMetrics }}
USER nonroot:nonroot
ENTRYPOINT ["/server"]
