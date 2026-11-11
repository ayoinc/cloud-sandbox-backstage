# ${{ values.name }}

${{ values.description }}

A [Model Context Protocol](https://modelcontextprotocol.io/) (MCP) server in
TypeScript, built on the official SDK. AI clients connect to it over
**Streamable HTTP** or **stdio** to call its tools and read its resources.

| Capability | Name | Purpose |
| --- | --- | --- |
| Tool | `add_note` | Save a note; returns it as structured content |
| Tool | `search_notes` | Find notes by text or tag (read-only) |
| Tool | `delete_note` | Delete a note by id (destructive) |
| Resource | `notes://all` | Every note as JSON |
| Resource template | `notes://note/{id}` | One note |
| Prompt | `summarise_notes` | Summarise the notes, optionally for one tag |

The note store in `src/notes.ts` is the sample domain. Replace it, and the
registrations in `src/server.ts`, with what your server exposes.

## Requirements

Node.js ${{ values.node_version }} (see `.node-version`) and npm.

## Development

```sh
npm ci
npm run dev          # HTTP transport on http://127.0.0.1:${{ values.port }}/mcp, restarting on change
npm test             # Vitest: in-memory client, HTTP transport, configuration
npm run lint
npm run typecheck
npm run build        # compile to dist/
```

Explore the server with the MCP Inspector:

```sh
npm run build
npx @modelcontextprotocol/inspector node dist/index.js --stdio
```

## Configuration

Configuration comes from environment variables only; `.env.example` lists them.

| Variable | Default | Meaning |
| --- | --- | --- |
| `MCP_TRANSPORT` | `http` | `http` or `stdio`. The `--stdio` argument selects stdio as well |
| `HOST` | `127.0.0.1` | Address the HTTP transport binds to |
| `PORT` | `${{ values.port }}` | Port of the HTTP transport |
| `MCP_AUTH_TOKEN` | none | Bearer token clients must send, at least 32 characters. Required when `HOST` is not a loopback address |
| `MCP_ALLOWED_HOSTS` | loopback names | Comma-separated host names accepted in the `Host` header |

Keep the token in a secret manager and inject it at run time. It is never
written to the repository or the image.

## Connecting a client

**stdio**, for clients that start the server as a child process:

```json
{
  "mcpServers": {
    "${{ values.name }}": {
      "command": "node",
      "args": ["/path/to/${{ values.destination.repo }}/dist/index.js", "--stdio"]
    }
  }
}
```

**Streamable HTTP**, for a deployed server:

```json
{
  "mcpServers": {
    "${{ values.name }}": {
      "type": "http",
      "url": "https://<host>/mcp",
      "headers": { "Authorization": "Bearer <MCP_AUTH_TOKEN>" }
    }
  }
}
```

## Container

```sh
docker build -t ${{ values.name }} .
docker run --rm -p ${{ values.port }}:${{ values.port }} -e MCP_AUTH_TOKEN="$(openssl rand -base64 32)" ${{ values.name }}
curl http://127.0.0.1:${{ values.port }}/healthz
```

The image listens on `0.0.0.0`, so it does not start without `MCP_AUTH_TOKEN`.
Pushes to `main` publish `ghcr.io/${{ values.destination.owner }}/${{ values.destination.repo }}`
with a build provenance attestation:

```sh
gh attestation verify oci://ghcr.io/${{ values.destination.owner }}/${{ values.destination.repo }}:latest \
  --repo ${{ values.destination.owner }}/${{ values.destination.repo }}
```

## Adding a tool

Register it in `src/server.ts` and cover it in `test/server.test.ts`:

```ts
server.registerTool(
  'count_notes',
  {
    title: 'Count notes',
    description: 'Return the number of stored notes.',
    outputSchema: { count: z.number().int() },
    annotations: { readOnlyHint: true },
  },
  () => {
    const result = { count: store.list().length };
    return { content: [{ type: 'text', text: JSON.stringify(result) }], structuredContent: result };
  },
);
```

Guidelines:

- Describe each tool and argument for a model that has no other context.
- Validate every input with a Zod schema; return `isError: true` for failures
  the model can recover from, and throw for bugs.
- Set the annotations honestly: clients use `readOnlyHint` and
  `destructiveHint` to decide when to ask the user for confirmation.
- Write logs to stderr. On stdio, stdout carries the protocol.
