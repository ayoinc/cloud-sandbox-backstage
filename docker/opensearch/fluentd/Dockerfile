FROM fluent/fluentd:v1.16-debian

# Switch to root to install plugins and dependencies
USER root

# Install curl for health checks and OpenSearch plugins
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install OpenSearch plugin, S3 plugin for MinIO archival, and dependencies
RUN gem install fluent-plugin-opensearch --no-document \
    && gem install fluent-plugin-s3 --no-document \
    && gem install fluent-plugin-rewrite-tag-filter --no-document \
    && gem install fluent-plugin-record-modifier --no-document

# Create log directory
RUN mkdir -p /fluentd/log && chown -R fluent:fluent /fluentd

USER fluent

EXPOSE 24224 24224/udp 9880 24220

CMD ["fluentd", "-c", "/fluentd/etc/fluent.conf", "-p", "/fluentd/plugins"]
