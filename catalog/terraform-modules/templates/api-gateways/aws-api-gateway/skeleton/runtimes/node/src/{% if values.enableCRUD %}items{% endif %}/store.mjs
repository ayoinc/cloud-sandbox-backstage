// Items in the DynamoDB table named by ITEMS_TABLE. The AWS SDK ships with
// the Lambda runtime; it is loaded on first use so that the unit tests, which
// use an in-memory store, run without it.

let sdk;

async function loadSdk() {
  if (!sdk) {
    const { DynamoDBClient } = await import('@aws-sdk/client-dynamodb');
    const lib = await import('@aws-sdk/lib-dynamodb');
    sdk = {
      lib,
      client: lib.DynamoDBDocumentClient.from(new DynamoDBClient({})),
    };
  }
  return sdk;
}

export function createStore(tableName = process.env.ITEMS_TABLE) {
  const send = async (command, input) => {
    const { client, lib } = await loadSdk();
    return client.send(new lib[command]({ TableName: tableName, ...input }));
  };

  return {
    // One page of at most 100 items.
    async list() {
      const { Items } = await send('ScanCommand', { Limit: 100 });
      return Items ?? [];
    },

    async get(id) {
      const { Item } = await send('GetCommand', { Key: { id } });
      return Item ?? null;
    },

    async put(item) {
      await send('PutCommand', { Item: item });
    },

    // True when an item with this id existed.
    async delete(id) {
      const { Attributes } = await send('DeleteCommand', {
        Key: { id },
        ReturnValues: 'ALL_OLD',
      });
      return Boolean(Attributes);
    },
  };
}
