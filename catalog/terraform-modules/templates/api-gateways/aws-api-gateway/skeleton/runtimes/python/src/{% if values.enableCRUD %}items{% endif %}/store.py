"""Items in the DynamoDB table named by ITEMS_TABLE."""

import json
import os
from decimal import Decimal


def _to_dynamo(item):
    """DynamoDB stores numbers as Decimal and rejects float."""
    return json.loads(json.dumps(item), parse_float=Decimal)


def _from_dynamo(value):
    """Turn the Decimals DynamoDB returns back into int or float."""
    if isinstance(value, Decimal):
        return int(value) if value == value.to_integral_value() else float(value)
    if isinstance(value, dict):
        return {key: _from_dynamo(item) for key, item in value.items()}
    if isinstance(value, list | set):
        return [_from_dynamo(item) for item in value]
    return value


class DynamoStore:
    def __init__(self, table_name=None):
        self._table_name = table_name
        self._table = None

    def _get_table(self):
        if self._table is None:
            # boto3 is part of the Lambda runtime. It is imported on first use
            # so that the unit tests, which use an in-memory store, run
            # without it.
            import boto3

            name = self._table_name or os.environ["ITEMS_TABLE"]
            self._table = boto3.resource("dynamodb").Table(name)
        return self._table

    def list(self):
        """One page of at most 100 items."""
        response = self._get_table().scan(Limit=100)
        return [_from_dynamo(item) for item in response.get("Items", [])]

    def get(self, item_id):
        item = self._get_table().get_item(Key={"id": item_id}).get("Item")
        return _from_dynamo(item) if item else None

    def put(self, item):
        self._get_table().put_item(Item=_to_dynamo(item))

    def delete(self, item_id):
        """True when an item with this id existed."""
        response = self._get_table().delete_item(
            Key={"id": item_id}, ReturnValues="ALL_OLD"
        )
        return "Attributes" in response
