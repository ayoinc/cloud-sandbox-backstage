# ${{ values.name }}

${{ values.description or "Contract tests for an API." }}

Tests an API against its OpenAPI description with
[Schemathesis](https://schemathesis.readthedocs.io). Requests are generated
from `openapi/openapi.yaml`; a run fails when the API answers with a status,
content type, header or body the description does not allow, accepts input it
should refuse, or returns a server error.

## Run it

```bash
node test-target/server.js &
uvx schemathesis==4.33.2 run openapi/openapi.yaml --url http://127.0.0.1:3000
```

Against a deployed API:

```bash
uvx schemathesis==4.33.2 run openapi/openapi.yaml \
  --url https://api.staging.example.org \
  --header "Authorization: Bearer $API_TOKEN"
```

## Make it yours

1. Replace `openapi/openapi.yaml` with your API's description. The portal's
   API explorer shows it after the next catalog refresh.
2. Delete `test-target/` once a deployed API is being tested, and set the
   `BASE_URL` repository variable (and the `API_TOKEN` secret if the API needs
   one).
3. Tune `schemathesis.toml`: checks, and how many requests each operation gets.

## In GitHub Actions

| When | What is tested |
| --- | --- |
| Every push to `main` | The bundled sample API, which proves the suite works |
| A manual run | The address typed in, else the `BASE_URL` variable, else the sample API |

The JUnit report is kept as the `contract-report` artifact.
