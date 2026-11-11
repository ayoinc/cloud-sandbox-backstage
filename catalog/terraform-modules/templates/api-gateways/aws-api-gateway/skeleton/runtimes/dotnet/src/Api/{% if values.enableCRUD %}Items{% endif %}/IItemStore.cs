using System.Text.Json.Nodes;

namespace Api.Items;

// Storage of the items. An item is a JSON object with a string attribute "id".
public interface IItemStore
{
    // One page of at most 100 items.
    Task<IReadOnlyList<JsonObject>> ListAsync();

    Task<JsonObject?> GetAsync(string id);

    Task PutAsync(JsonObject item);

    // True when an item with this id existed.
    Task<bool> DeleteAsync(string id);
}
