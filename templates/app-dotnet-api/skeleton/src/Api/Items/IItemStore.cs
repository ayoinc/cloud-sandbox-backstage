namespace Api.Items;

/// <summary>
/// What the endpoints need from a repository. Implement it on a database to
/// replace the in-memory store.
/// </summary>
public interface IItemStore
{
    Task<IReadOnlyList<Item>> ListAsync(CancellationToken cancellationToken);

    Task<Item?> GetAsync(Guid id, CancellationToken cancellationToken);

    Task<Item> CreateAsync(string name, CancellationToken cancellationToken);
}
