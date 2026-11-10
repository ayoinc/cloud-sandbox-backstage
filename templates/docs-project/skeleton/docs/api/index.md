# API Reference

Reference documentation for the ${{ values.name }} API. The OpenAPI description in [`openapi.yaml`](openapi.yaml) is the source of truth; keep this page and the specification in step when the API changes.

## Base URL

| Environment | URL |
| --- | --- |
| Production | `https://api.example.com/v1` |
| Staging | `https://staging.api.example.com/v1` |

## Authentication

Requests are authenticated with a bearer token:

```bash
curl -H "Authorization: Bearer $TOKEN" https://api.example.com/v1/health
```

## Endpoints

| Method | Path | Description |
| --- | --- | --- |
| `GET` | `/health` | Report whether the service is ready to serve requests |

### GET /health

Returns `200 OK` when the service is healthy.

```json
{
  "status": "ok"
}
```

## Errors

Errors use standard HTTP status codes and a JSON body:

```json
{
  "code": "not_found",
  "message": "The requested resource does not exist"
}
```

| Status | Meaning |
| --- | --- |
| `400` | The request is malformed |
| `401` | The bearer token is missing or invalid |
| `404` | The resource does not exist |
| `500` | The service failed to process the request |
