# AI Agent Service (Python)

Creates a repository with an LLM agent exposed as a FastAPI service. The model
provider is chosen when the repository is created: the Anthropic API, the
OpenAI API or Amazon Bedrock.

## What you get

| Path                        | Content                                                                           |
| --------------------------- | --------------------------------------------------------------------------------- |
| `src/agent/loop.py`         | The agent loop: model turn, tool calls, repeat, with a step limit                 |
| `src/agent/tools.py`        | A tool registry with schema validation and time limits, and two sample tools      |
| `src/agent/schemas.py`      | The structured answer the model must produce, and the API models                  |
| `src/agent/llm/`            | Provider-neutral types and one adapter for the chosen provider                    |
| `src/agent/main.py`         | `POST /v1/chat` and the streaming `POST /v1/chat/stream` (server-sent events)     |
| `src/agent/telemetry.py`    | OpenTelemetry traces following the generative AI semantic conventions             |
| `evals/`                    | A dataset of expected behaviour, scoring, and a runner with a pass-rate threshold |
| `tests/`                    | Tests that run against a scripted model: no network and no credentials            |
| `pyproject.toml`, `uv.lock` | Dependencies managed with uv and locked                                           |
| `.github/workflows/`        | CI (lint, types, tests, image, provenance) and an on-demand eval run              |

## Parameters

| Parameter      | Meaning                                                                                                                                     |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| Provider       | `anthropic`, `openai` or `bedrock`. Only the SDK of the chosen provider is installed                                                        |
| Model          | Default model id; `AGENT_MODEL` overrides it at run time. For Bedrock, give a model or inference profile id that is enabled in your account |
| AWS Region     | Bedrock only: region of the runtime endpoint                                                                                                |
| Python Version | Version used in CI and in the image                                                                                                         |

## Credentials

The template never asks for an API key and the generated code never contains
one. The provider SDK reads `ANTHROPIC_API_KEY` or `OPENAI_API_KEY` from the
environment; Amazon Bedrock uses the IAM role of the workload. The eval
workflow reads the key from a GitHub environment secret, or for Bedrock
assumes a role through OIDC.

## Design choices

- **One provider, behind an interface.** The loop, tools, API and tests use
  the types in `src/agent/llm/base.py`. Only `provider.py` imports an SDK, so
  changing provider later means replacing one module.
- **Structured output through a tool.** The answer schema is the input schema
  of a `final_answer` tool and is validated with pydantic. An invalid answer
  goes back to the model to be corrected.
- **Bounded runs.** Step limit, per-tool time limit, request time limit and
  request size limits are all enforced.
- **No prompt content in telemetry.** Spans carry model, token usage and tool
  names only.

## After creation

1. `uv sync`, copy `.env.example` to `.env`, add the credential, and start the
   service with the command in the README.
2. Replace the sample tools and the `AgentAnswer` fields with your own.
3. Add eval cases for the behaviour you need, and run the **Evals** workflow
   before changing the prompt or the model.
