using System.ComponentModel.DataAnnotations;

namespace Api.Items;

public sealed record Item(Guid Id, string Name, DateTimeOffset CreatedAt);

public sealed record ItemList(IReadOnlyList<Item> Items);

public sealed record CreateItemRequest(
    [property: Required]
    [property: StringLength(200, MinimumLength = 1)]
    string Name);
