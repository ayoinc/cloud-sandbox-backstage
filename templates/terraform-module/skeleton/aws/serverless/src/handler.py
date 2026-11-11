"""Built-in function deployed when no deployment package or image is supplied.

It answers HTTP API requests with a small JSON document, acknowledges SQS
batches message by message and logs scheduled invocations.
"""

import json
import logging
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def _handle_sqs(event):
    failures = []
    for record in event["Records"]:
        try:
            logger.info("Processing message %s", record["messageId"])
        except Exception:  # report the message so SQS redelivers only this one
            logger.exception("Message %s failed", record.get("messageId"))
            failures.append({"itemIdentifier": record.get("messageId")})
    return {"batchItemFailures": failures}


def main(event, context):
    event = event or {}

    records = event.get("Records") or []
    if records and records[0].get("eventSource") == "aws:sqs":
        return _handle_sqs(event)

    if event.get("source") == "aws.events":
        logger.info("Scheduled invocation at %s", event.get("time"))
        return {"status": "ok"}

    body = {
        "status": "ok",
        "project": os.environ.get("PROJECT"),
        "environment": os.environ.get("ENVIRONMENT"),
        "path": event.get("rawPath", "/"),
    }
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }
