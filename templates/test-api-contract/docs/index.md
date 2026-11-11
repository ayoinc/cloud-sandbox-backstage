# API Contract Testing

Creates a repository that tests an API against its OpenAPI description with
[Schemathesis](https://schemathesis.readthedocs.io): it generates requests
from the description, sends them, and fails when the API answers with
something the description does not allow.

| In the repository                 | What it is                                                                                            |
| --------------------------------- | ----------------------------------------------------------------------------------------------------- |
| `openapi/openapi.yaml`            | The contract. Replace the sample with your API's                                                      |
| `test-target/server.js`           | A small API that honours the sample contract, so the first push passes                                |
| `schemathesis.toml`               | Which checks run and how many requests each operation gets                                            |
| `.github/workflows/contract.yaml` | Validates the description, then tests the sample API on every push and a deployed API on a manual run |

The description is also registered as an **API** in the catalog, so it shows
in the portal's API explorer with its operations and schemas.

## Form fields

| Field                  | Meaning                                                  |
| ---------------------- | -------------------------------------------------------- |
| Base URL               | Optional. The deployed API a manual run tests by default |
| Examples per operation | How many generated requests each operation gets          |
