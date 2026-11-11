# ${{ values.name }}

${{ values.description }}

An LLM agent service in Python. It answers a request by calling a model on
{% if values.provider == 'anthropic' %}the **Anthropic API**{% elif values.provider == 'openai' %}the **OpenAI API**{% else %}**Amazon Bedrock**{% endif %}, letting the model use tools, and returning a validated,
structured answer over a FastAPI endpoint, either at once or as a stream of
events.

| | |
| --- | --- |
| Provider | `${{ values.provider }}` |
| Default model | `${{ values.model }}` (override with `AGENT_MODEL`) |
| API | `POST /v1/chat`, `POST /v1/chat/stream`, `GET /v1/info`, `GET /healthz`, `GET /readyz` |
| Tooling | [uv](https://docs.astral.sh/uv/), Ruff, mypy (strict), pytest |

## Quick start

```sh
uv sync                      # create .venv from uv.lock
cp .env.example .env         # then fill in the credentials
uv run --env-file .env uvicorn --factory agent.main:app --reload
```

```sh
curl -s localhost:8000/v1/chat \
  -H 'Content-Type: application/json' \
  -d '{"message": "What is 17.5% of 2,480, and what time is it in Tokyo?"}'
```

```json
{
  "answer": {
    "answer": "17.5% of 2,480 is 434. It is 09:41 on 12 November in Tokyo.",
    "confidence": "high",
    "follow_up_questions": []
  },
  "tool_invocations": [
    { "name": "calculate", "arguments": { "expression": "2480 * 0.175" }, "result": "434.0", "is_error": false },
    { "name": "get_current_time", "arguments": { "timezone": "Asia/Tokyo" }, "result": "2026-11-12T09:41:07+09:00", "is_error": false }
  ],
  "usage": { "input_tokens": 1830, "output_tokens": 214 },
  "steps": 2,
  "model": "${{ values.model }}"
}
```

The streaming endpoint sends the same run as server-sent events:

```sh
curl -sN localhost:8000/v1/chat/stream \
  -H 'Content-Type: application/json' \
  -d '{"message": "What is 6 times 7?"}'
```

```text
event: tool_started
data: {"type":"tool_started","name":"calculate","arguments":{"expression":"6 * 7"}}

event: tool_finished
data: {"type":"tool_finished","name":"calculate","result":"42","is_error":false}

event: completed
data: {"type":"completed","response":{"answer":{"answer":"6 times 7 is 42.", ...}}}
```

## Credentials

No credential is stored in this repository, in the image or in the
configuration class. They are read from the environment at run time.
{% if values.provider == 'anthropic' %}
- `ANTHROPIC_API_KEY`: read by the Anthropic SDK. Locally it lives in `.env`
  (ignored by Git); deployed, inject it from your secret manager.
{%- elif values.provider == 'openai' %}
- `OPENAI_API_KEY`: read by the OpenAI SDK. Locally it lives in `.env`
  (ignored by Git); deployed, inject it from your secret manager.
{%- else %}
- Amazon Bedrock uses the default AWS credential chain. Deployed, give the
  workload an IAM role (IRSA, EKS Pod Identity, ECS task role) that allows
  `bedrock:InvokeModelWithResponseStream` on the model; locally, use
  `aws sso login` and `AWS_PROFILE`. Do not create access keys for it.
- `AWS_REGION` selects the Bedrock endpoint (default `${{ values.aws_region }}`).
{%- endif %}
- `AGENT_API_TOKEN`: optional bearer token that callers of this service must
  present. Without it the API is open, which is only acceptable behind an
  authenticating gateway.

## Configuration

| Variable | Default | Meaning |
| --- | --- | --- |
| `AGENT_MODEL` | `${{ values.model }}` | Model id sent to the provider |
| `AGENT_MAX_STEPS` | `8` | Model turns allowed for one request |
| `AGENT_MAX_OUTPUT_TOKENS` | `2048` | Output token limit of one model turn |
| `AGENT_REQUEST_TIMEOUT_SECONDS` | `120` | Time limit of one request |
| `AGENT_TOOL_TIMEOUT_SECONDS` | `20` | Time limit of one tool call |
| `AGENT_API_TOKEN` | unset | Bearer token required from callers |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | unset | OTLP/HTTP endpoint; setting it turns tracing on |

## Layout

| Path | Content |
| --- | --- |
| `src/agent/main.py` | FastAPI application: endpoints, authentication, server-sent events |
| `src/agent/loop.py` | The agent loop and the system prompt |
| `src/agent/tools.py` | Tool registry and the sample tools |
| `src/agent/schemas.py` | `AgentAnswer` (the structured output) and the API models |
| `src/agent/llm/base.py` | Provider-neutral message and tool types |
| `src/agent/llm/provider.py` | The only module that imports the provider SDK |
| `src/agent/telemetry.py` | OpenTelemetry set-up |
| `evals/` | Eval dataset, scoring and runner |
| `tests/` | Tests with a scripted model; no network, no credentials |

## Adding a tool

```python
class OrderStatusArgs(BaseModel):
    model_config = ConfigDict(extra="forbid")

    order_id: str = Field(description="Order number, for example A-10293")


@registry.tool(
    "get_order_status",
    "Look up the delivery status of an order. Use it whenever the user asks about an order.",
    OrderStatusArgs,
)
async def get_order_status(args: OrderStatusArgs) -> str:
    return await orders.status(args.order_id)
```

Register it in `default_registry()` in `src/agent/tools.py`. Arguments are
validated before the function runs; an exception is returned to the model as a
tool error. Write the description for the model: say what the tool does and
when to use it. Then add a case to `evals/dataset.jsonl` that requires it.

## Changing the structured output

Edit `AgentAnswer` in `src/agent/schemas.py`. The model receives its JSON
Schema as the `final_answer` tool and the service validates what comes back;
an answer that does not validate is returned to the model to be corrected.
Keep every field required and described.

## Quality checks

```sh
uv run ruff check . && uv run ruff format --check .
uv run mypy
uv run pytest            # fails below 85% coverage
```

## Evals

Tests show that the code works; evals show that the *model* behaves, and tell
you whether a prompt change or a model upgrade made things better or worse.

```sh
uv run --env-file .env python -m evals.run --report evals/reports/latest.json
```

Each line of `evals/dataset.jsonl` is a case: an input and what to expect
(tools called, arguments, text in the answer, confidence, step budget). The
runner prints a result per case and exits non-zero below `--min-pass-rate`
(default 0.8). The **Evals** workflow runs the same command on demand
{%- if values.provider == 'bedrock' %}; it assumes
the role in the `AWS_ROLE_ARN` variable of the `evals` environment through
OIDC, with no stored keys.
{%- else %}; it
reads the API key from a secret of the `evals` environment.
{%- endif %}

## Container

```sh
docker build -t ${{ values.name }} .
docker run --rm -p 8000:8000 --env-file .env ${{ values.name }}
```

The image runs as a non-root user. Pushes to `main` publish
`ghcr.io/${{ values.destination.owner }}/${{ values.destination.repo }}` with a build provenance
attestation.
