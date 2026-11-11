FROM ${{ values.baseImage }} AS build
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

ENV PORT=${{ values.port }}

USER 10001:10001

EXPOSE ${{ values.port }}
{%- if values.includeHealthcheck %}

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["wget", "-q", "--spider", "http://127.0.0.1:${{ values.port }}/health"]
{%- endif %}

CMD ["./app"]
