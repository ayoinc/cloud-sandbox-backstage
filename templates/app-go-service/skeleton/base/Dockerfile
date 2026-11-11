FROM golang:1.27-alpine AS build
WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY cmd ./cmd
COPY internal ./internal

ARG VERSION=dev
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w -X main.version=${VERSION}" -o /out/server ./cmd/server

# No shell and no package manager: the image holds the binary, CA certificates
# and time zone data. Health is checked by the orchestrator's HTTP probes.
FROM gcr.io/distroless/static-debian13:nonroot AS production

ENV PORT=${{ values.port }}

COPY --from=build /out/server /server

USER 65532:65532

EXPOSE ${{ values.port }}

ENTRYPOINT ["/server"]
