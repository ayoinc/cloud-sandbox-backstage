# MCP Server (TypeScript)

Creates a repository with a [Model Context Protocol](https://modelcontextprotocol.io/)
server written in TypeScript on the official SDK
(`@modelcontextprotocol/sdk`). AI clients and agents connect to it to call
tools and read resources.

## What you get

| Path                        | Content                                                                                                               |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `src/server.ts`             | The MCP server: three tools with input and output schemas, a static resource, a resource template and a prompt        |
| `src/http.ts`               | Streamable HTTP transport on Express: stateless, bearer-token authentication, Host header validation, health endpoint |
| `src/index.ts`              | Entry point that starts the HTTP transport or, with `--stdio`, the stdio transport                                    |
| `src/config.ts`             | Configuration read from environment variables and validated with Zod                                                  |
| `test/`                     | Vitest suites that drive the server through an in-memory client and over HTTP                                         |
| `Dockerfile`                | Multi-stage image that runs as a non-root user                                                                        |
| `.github/workflows/ci.yaml` | Lint, type check, tests, image build, smoke test, scan and publish with build provenance                              |

The sample domain is a small in-memory note store, so that every protocol
feature has working code and a test. Replace `src/notes.ts` and the
registrations in `src/server.ts` with your own.

## Parameters

| Parameter       | Meaning                                                                           |
| --------------- | --------------------------------------------------------------------------------- |
| Server Name     | Repository, npm package, catalog entry and the name the server reports to clients |
| Node.js Version | Version used in CI and in the image                                               |
| HTTP Port       | Default port of the HTTP transport; `PORT` overrides it at run time               |

## Security defaults

- The HTTP transport binds to `127.0.0.1` unless `HOST` is set.
- On any other address the server refuses to start without `MCP_AUTH_TOKEN`
  (a bearer token of at least 32 characters). The token is read from the
  environment only and compared in constant time.
- Host header validation protects local servers against DNS rebinding;
  `MCP_ALLOWED_HOSTS` sets the accepted host names behind a proxy.
- The image runs as the unprivileged `node` user and the published image
  carries a build provenance attestation signed with the workflow's OIDC
  identity.

## After creation

1. Clone the repository, run `npm ci` and `npm test`.
2. Try the server with the MCP Inspector: `npx @modelcontextprotocol/inspector node dist/index.js --stdio`
   after `npm run build`.
3. Pushes to `main` publish `ghcr.io/<owner>/<repository>`.
