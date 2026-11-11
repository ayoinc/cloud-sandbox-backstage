# ${{ values.name }}

${{ values.description }}

## Overview

`${{ values.name }}` is a Model Context Protocol server. An MCP client, such as an AI
assistant or an agent runtime, connects to it, discovers its tools, resources
and prompts, and calls them on behalf of a model.

| | |
| --- | --- |
| Endpoint | `POST /mcp` (Streamable HTTP) |
| Health check | `GET /healthz` |
| Default port | `${{ values.port }}` |
| Image | `ghcr.io/${{ values.destination.owner }}/${{ values.destination.repo }}` |

## Architecture

| Module | Responsibility |
| --- | --- |
| `src/index.ts` | Loads the configuration and starts one of the transports |
| `src/config.ts` | Reads and validates environment variables |
| `src/server.ts` | Registers tools, resources and the prompt on an `McpServer` |
| `src/http.ts` | Express application for Streamable HTTP |
| `src/notes.ts` | The sample domain: an in-memory note store |

### Transports

- **Streamable HTTP** runs in stateless mode. Each request is served by a new
  `McpServer` and transport, no session id is issued, and responses are plain
  JSON or a short event stream. Any replica can answer any request, so the
  server scales horizontally behind a load balancer without sticky sessions.
- **stdio** serves one client that started the process. Logs go to stderr.

State lives in the store, not in the MCP server object. The sample store is in
memory: with more than one replica, or to survive restarts, back it with a
database.

## Security

| Control | Behaviour |
| --- | --- |
| Authentication | `Authorization: Bearer <MCP_AUTH_TOKEN>` on `/mcp`, compared in constant time. Without a token the server only starts on a loopback address |
| DNS rebinding | Requests to `/mcp` with a `Host` header outside `MCP_ALLOWED_HOSTS` (or the loopback names) get `403` |
| Input validation | Tool arguments are validated against Zod schemas before the handler runs |
| Request size | JSON bodies are limited to 1 MB |
| Secrets | Read from the environment at start-up; none in the repository or the image |
| Container | Runs as the unprivileged `node` user |

A single shared token suits service-to-service use inside your organisation.
To give each user their own identity, put the server behind an OAuth 2.1
authorisation server; the SDK ships the resource-server pieces in
`@modelcontextprotocol/sdk/server/auth`.

## Deployment notes

- Set `HOST=0.0.0.0`, `MCP_AUTH_TOKEN` from a secret, and `MCP_ALLOWED_HOSTS`
  to the public host name.
- Terminate TLS in front of the server.
- Use `/healthz` for liveness and readiness probes.
- The process exits cleanly on `SIGTERM`.

## Testing

| Suite | What it covers |
| --- | --- |
| `test/server.test.ts` | Every tool, resource and prompt through an in-memory MCP client |
| `test/http.test.ts` | A real client over HTTP, authentication, Host validation, allowed methods |
| `test/config.test.ts` | Defaults and the refusal to listen publicly without a token |
