FROM rust:1.99-slim-trixie AS build
WORKDIR /src

COPY Cargo.toml Cargo.lock ./
COPY src ./src
{%- if values.database == 'postgres' %}
COPY migrations ./migrations
{%- endif %}

RUN cargo build --release --locked

# No shell and no package manager: the image holds the binary, glibc and CA
# certificates. Health is checked by the orchestrator's HTTP probes.
FROM gcr.io/distroless/cc-debian13:nonroot AS production

ENV PORT=${{ values.port }}

COPY --from=build /src/target/release/${{ values.name }} /usr/local/bin/service

USER 65532:65532

EXPOSE ${{ values.port }}

ENTRYPOINT ["/usr/local/bin/service"]
