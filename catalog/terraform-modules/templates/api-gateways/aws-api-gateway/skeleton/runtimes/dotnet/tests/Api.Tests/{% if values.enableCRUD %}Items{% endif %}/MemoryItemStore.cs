using System.Text.Json.Nodes;
using Api.Items;

namespace Api.Tests.Items;

// The item store kept in memory, in insertion order. Items are copied on the
// way in and out, like a store that serialises them.
internal sealed class MemoryItemStore : IItemStore
{
    private readonly List<JsonObject> _items = [];

    public Task<IReadOnlyList<JsonObject>> ListAsync()
    {
        IReadOnlyList<JsonObject> items = _items.Select(Copy).ToList();
        return Task.FromResult(items);
    }

    public Task<JsonObject?> GetAsync(string id)
    {
        var index = IndexOf(id);
        return Task.FromResult(index < 0 ? null : Copy(_items[index]));
    }

    public Task PutAsync(JsonObject item)
    {
        var index = IndexOf(Http.Text(item, "id"));
        if (index < 0)
        {
            _items.Add(Copy(item));
        }
        else
        {
            _items[index] = Copy(item);
        }

        return Task.CompletedTask;
    }

    public Task<bool> DeleteAsync(string id)
    {
        var index = IndexOf(id);
        if (index < 0)
        {
            return Task.FromResult(false);
        }

        _items.RemoveAt(index);
        return Task.FromResult(true);
    }

    private int IndexOf(string id)
    {
        return _items.FindIndex(item => Http.Text(item, "id") == id);
    }

    private static JsonObject Copy(JsonObject item)
    {
        return item.DeepClone().AsObject();
    }
}
