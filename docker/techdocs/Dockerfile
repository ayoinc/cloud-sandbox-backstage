FROM spotify/techdocs:v1.2.3

# Install additional plugins commonly used with TechDocs
RUN pip install --no-cache-dir \
    mkdocs-material \
    mkdocs-monorepo-plugin \
    mkdocs-awesome-pages-plugin \
    mkdocs-techdocs-core \
    markdown-inline-mermaid \
    plantuml-markdown \
    pygments

# Create working directory
WORKDIR /content

# Default command - generate docs
ENTRYPOINT ["mkdocs"]
CMD ["build", "--strict"]
