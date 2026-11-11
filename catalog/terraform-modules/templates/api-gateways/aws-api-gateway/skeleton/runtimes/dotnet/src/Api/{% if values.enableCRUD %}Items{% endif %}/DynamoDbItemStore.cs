using System.Text.Json.Nodes;
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.DocumentModel;
using Amazon.DynamoDBv2.Model;

namespace Api.Items;

// Items in the DynamoDB table named by ITEMS_TABLE. The client is created on
// first use, so building the route table needs no AWS configuration.
public sealed class DynamoDbItemStore : IItemStore
{
    private readonly string _tableName = Environment.GetEnvironmentVariable("ITEMS_TABLE") ?? "";
    private readonly Lazy<AmazonDynamoDBClient> _client = new(() => new AmazonDynamoDBClient());

    public async Task<IReadOnlyList<JsonObject>> ListAsync()
    {
        var response = await _client.Value.ScanAsync(new ScanRequest { TableName = _tableName, Limit = 100 });
        var items = new List<JsonObject>();
        if (response.Items is { } found)
        {
            items.AddRange(found.Select(ToJson));
        }

        return items;
    }

    public async Task<JsonObject?> GetAsync(string id)
    {
        var response = await _client.Value.GetItemAsync(new GetItemRequest { TableName = _tableName, Key = Key(id) });
        return response.Item is { Count: > 0 } item ? ToJson(item) : null;
    }

    public async Task PutAsync(JsonObject item)
    {
        var attributes = Document.FromJson(item.ToJsonString()).ToAttributeMap();
        await _client.Value.PutItemAsync(new PutItemRequest { TableName = _tableName, Item = attributes });
    }

    public async Task<bool> DeleteAsync(string id)
    {
        var request = new DeleteItemRequest
        {
            TableName = _tableName,
            Key = Key(id),
            ReturnValues = ReturnValue.ALL_OLD,
        };
        var response = await _client.Value.DeleteItemAsync(request);
        return response.Attributes is { Count: > 0 };
    }

    private static Dictionary<string, AttributeValue> Key(string id)
    {
        return new Dictionary<string, AttributeValue> { ["id"] = new AttributeValue { S = id } };
    }

    private static JsonObject ToJson(Dictionary<string, AttributeValue> attributes)
    {
        return JsonNode.Parse(Document.FromAttributeMap(attributes).ToJson())!.AsObject();
    }
}
