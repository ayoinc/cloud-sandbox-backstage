using Microsoft.AspNetCore.Http.HttpResults;

namespace Api.Items;

internal static class ItemEndpoints
{
    public static IEndpointRouteBuilder MapItems(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/items").WithTags("Items");

        group.MapGet("/", async (IItemStore store, CancellationToken cancellationToken) =>
                TypedResults.Ok(new ItemList(await store.ListAsync(cancellationToken))))
            .WithName("ListItems");

        group.MapGet("/{id:guid}", async Task<Results<Ok<Item>, NotFound>> (Guid id, IItemStore store, CancellationToken cancellationToken) =>
                await store.GetAsync(id, cancellationToken) is { } item
                    ? TypedResults.Ok(item)
                    : TypedResults.NotFound())
            .WithName("GetItem");

        group.MapPost("/", async (CreateItemRequest request, IItemStore store, CancellationToken cancellationToken) =>
            {
                var item = await store.CreateAsync(request.Name.Trim(), cancellationToken);
                return TypedResults.CreatedAtRoute(item, "GetItem", new { id = item.Id });
            })
            .WithName("CreateItem")
            .ProducesValidationProblem();

        return routes;
    }
}
