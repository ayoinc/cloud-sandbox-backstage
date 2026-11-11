FROM golang:1.27-alpine AS build
WORKDIR /src
ENV CGO_ENABLED=0
COPY go.mod ./
COPY *.go ./
RUN go build -trimpath -ldflags="-s -w" -o /out/app .

# Built by the pipeline with --target test: runs go vet and the unit tests.
FROM build AS test
RUN go vet ./... && go test ./...

FROM alpine:3.24
WORKDIR /app
COPY --from=build /out/app ./

ENV PORT=8080

USER 10001:10001

EXPOSE 8080

CMD ["./app"]
