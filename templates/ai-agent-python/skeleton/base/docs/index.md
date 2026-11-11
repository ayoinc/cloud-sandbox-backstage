# ${{ values.name }}

${{ values.description }}

## Overview

`${{ values.name }}` is an LLM agent exposed as an HTTP service. A request is answered by a
loop in which the model may call tools; the result is a structured answer that
the service validates before returning it.

| | |
| --- | --- |
| Provider | `${{ values.provider }}` |
| Default model | `${{ values.model }}` |
| Image | `ghcr.io/${{ values.destination.owner }}/${{ values.destination.repo }}` |
| Port | `8000` |

## How a request is processed

1. `POST /v1/chat` (or `/v1/chat/stream`) receives a message and optional history.
2. The agent sends the conversation, the system prompt and the tool schemas to
   the model.
3. If the model asks for tools, each call is validated, run with a time limit,
   and its result, or its error, is sent back to the model.
4. Steps 2 and 3 repeat until the model calls `final_answer`. Its arguments
   are validated as `AgentAnswer`. An invalid answer is returned to the model
   as an error to correct.
5. The run stops with an error after `AGENT_MAX_STEPS` model turns, so a
   confused model cannot loop without bound.

## API

| Endpoint | Purpose |
| --- | --- |
| `POST /v1/chat` | Run the agent; returns `answer`, `tool_invocations`, `usage`, `steps`, `model` |
| `POST /v1/chat/stream` | The same run as server-sent events |
| `GET /v1/info` | Provider, model, tool names and step limit |
| `GET /healthz` | Liveness: the process is up |
| `GET /readyz` | Readiness: provider credentials are present |
| `GET /docs` | OpenAPI documentation |

### Stream events

| Event | Data |
| --- | --- |
| `text_delta` | `text`: a fragment of the model's commentary |
| `tool_started` | `name`, `arguments` |
| `tool_finished` | `name`, `result`, `is_error` |
| `completed` | `response`: the body of `POST /v1/chat` |
| `error` | `message` |

The stream always ends with `completed` or `error`.

### Errors of `POST /v1/chat`

| Status | Meaning |
| --- | --- |
| 401 | `AGENT_API_TOKEN` is set and the bearer token is missing or wrong |
| 422 | The request is invalid, or the agent reached the step limit without an answer |
| 502 | The call to the model provider failed |
| 504 | The run exceeded `AGENT_REQUEST_TIMEOUT_SECONDS` |

## Structured output

The answer schema is offered to the model as the input schema of the
`final_answer` tool, marked strict where the provider supports schema
enforcement, and the arguments are validated with pydantic in every case.
This works the same way on every provider and keeps the schema in one place:
`AgentAnswer` in `src/agent/schemas.py`.

## Observability

Tracing follows the OpenTelemetry semantic conventions for generative AI and
is exported over OTLP/HTTP when `OTEL_EXPORTER_OTLP_ENDPOINT` is set.

| Span | Attributes |
| --- | --- |
| HTTP server span | From the FastAPI instrumentation |
| `invoke_agent` | `gen_ai.provider.name`, `gen_ai.request.model`, total `gen_ai.usage.*`, `agent.steps` |
| `chat <model>` | One per model turn: `gen_ai.usage.input_tokens`, `gen_ai.usage.output_tokens`, `gen_ai.response.finish_reasons` |
| `execute_tool <name>` | One per tool call: `gen_ai.tool.name`; status is error when the tool failed |

Prompts, answers and tool arguments are **not** recorded in spans or logs:
they often contain personal data. Token usage is returned in every response
for cost attribution.

## Security

- Credentials come from the environment only; see the README.
- Tools are the agent's reach into your systems. Give each the narrowest
  access that works, validate arguments with a schema, and treat tool results
  as untrusted input to the model: a document or web page fetched by a tool
  can contain instructions (prompt injection).
- Requests are limited in size (8,000 characters per message, 40 history
  entries), in model turns and in time.
- The sample calculator parses expressions instead of evaluating code.

## Evals

`evals/dataset.jsonl` holds the expected behaviour of the agent and
`python -m evals.run` measures the pass rate against the real model. Run it
before changing the system prompt, the tools or the model, and add a case for
every behaviour you care about and every failure you fix.
