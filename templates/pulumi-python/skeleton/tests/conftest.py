"""Replaces the Pulumi engine with mocks before any program code is imported.

Resources are echoed back instead of created, so the tests need neither
credentials nor a Pulumi backend.
"""

import asyncio
from typing import Any

import pulumi

# What the mocked engine answers when the program calls a provider function.
CALLS: dict[str, dict[str, Any]] = {
    "gcp:storage/getProjectServiceAccount:getProjectServiceAccount": {
        "member": "serviceAccount:service-123456789012@gs-project-accounts.iam.gserviceaccount.com",
    },
}


class Mocks(pulumi.runtime.Mocks):
    """An in-memory engine: every resource gets an ID and keeps its inputs."""

    def new_resource(self, args: pulumi.runtime.MockResourceArgs) -> tuple[str, dict[str, Any]]:
        state = {
            **args.inputs,
            "name": args.inputs.get("name", args.name),
            "arn": f"arn:aws:mock:::{args.name}",
            "bucket": args.inputs.get("bucket", args.name),
        }
        return f"{args.name}-id", state

    def call(
        self, args: pulumi.runtime.MockCallArgs
    ) -> tuple[dict[Any, Any], list[tuple[str, str]] | None]:
        return CALLS.get(args.token, {}), []


# Pulumi schedules its work on the event loop of the main thread; Python no
# longer creates one implicitly.
asyncio.set_event_loop(asyncio.new_event_loop())

pulumi.runtime.set_mocks(Mocks(), project="test-project", stack="test", preview=False)
pulumi.runtime.set_all_config({"gcp:region": "${{ values.region }}"})
