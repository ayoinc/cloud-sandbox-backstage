# ${{ values.name }}

${{ values.description or "Contract tests for an API." }}

| | |
| --- | --- |
| Contract | `openapi/openapi.yaml`, also shown in the API explorer |
| Tool | [Schemathesis](https://schemathesis.readthedocs.io) |
| Runs | Every push, and on demand against a deployed API |

## What a failure means

| Check | The API |
| --- | --- |
| Not a server error | Answered 5xx |
| Status code conformance | Answered with a status the description does not list |
| Content type conformance | Answered with a content type the description does not list |
| Response schema conformance | Answered with a body that does not match its schema |
| Response headers conformance | Left out a header the description promises |
| Negative data rejection | Accepted a request the description says is invalid |
| Positive data acceptance | Refused a request the description says is valid |

Each failure in the log comes with a `curl` command that reproduces it.

## Changing the contract

Change `openapi/openapi.yaml` in the same pull request as the API change it
describes, so the description and the API never disagree on `main`.
