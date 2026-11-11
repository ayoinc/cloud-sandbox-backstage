using System.Collections.Concurrent;

namespace Api.Items;

/// <summary>
/// Keeps items in process memory: they are lost on restart and not shared
/// between replicas.
/// </summary>
internal sealed class InMemoryItemStore(TimeProvider timeProvider) : IItemStore
{
    private readonly ConcurrentDictionary<Guid, Item> _items = new();

    public Task<IReadOnlyList<Item>> ListAsync(CancellationToken cancellationToken)
    {
        IReadOnlyList<Item> items = [.. _items.Values.OrderBy(item => item.CreatedAt).ThenBy(item => item.Id)];
        return Task.FromResult(items);
    }

    public Task<Item?> GetAsync(Guid id, CancellationToken cancellationToken) =>
        Task.FromResult(_items.GetValueOrDefault(id));

    public Task<Item> CreateAsync(string name, CancellationToken cancellationToken)
    {
        var item = new Item(Guid.CreateVersion7(), name, timeProvider.GetUtcNow());
        _items[item.Id] = item;
        return Task.FromResult(item);
    }
}
