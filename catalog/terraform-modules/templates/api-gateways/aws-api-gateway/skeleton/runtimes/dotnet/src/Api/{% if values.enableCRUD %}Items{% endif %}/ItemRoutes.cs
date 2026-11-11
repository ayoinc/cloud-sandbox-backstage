using System.Globalization;
using System.Text.Json.Nodes;
using Amazon.Lambda.APIGatewayEvents;

namespace Api.Items;

// Handlers of the /items endpoints on top of an item store.
public sealed class ItemRoutes(IItemStore store)
{
    public static Dictionary<string, RouteHandler> Create(IItemStore itemStore)
    {
        var routes = new ItemRoutes(itemStore);
        return new Dictionary<string, RouteHandler>
        {
            ["GET /items"] = routes.ListAsync,
            ["POST /items"] = routes.CreateAsync,
            ["GET /items/{id}"] = routes.GetAsync,
            ["PUT /items/{id}"] = routes.UpdateAsync,
            ["DELETE /items/{id}"] = routes.DeleteAsync,
        };
    }

    private async Task<APIGatewayProxyResponse> ListAsync(APIGatewayProxyRequest request)
    {
        var items = new JsonArray();
        foreach (var item in await store.ListAsync())
        {
            items.Add(item);
        }

        return Router.Json(200, new JsonObject { ["items"] = items });
    }

    private async Task<APIGatewayProxyResponse> CreateAsync(APIGatewayProxyRequest request)
    {
        var item = Router.ParseObject(request);
        var now = Timestamp();
        item["id"] = Guid.NewGuid().ToString();
        item["createdAt"] = now;
        item["updatedAt"] = now;
        await store.PutAsync(item);
        return Router.Json(201, item);
    }

    private async Task<APIGatewayProxyResponse> GetAsync(APIGatewayProxyRequest request)
    {
        var item = await store.GetAsync(Id(request)) ?? throw NotFound();
        return Router.Json(200, item);
    }

    private async Task<APIGatewayProxyResponse> UpdateAsync(APIGatewayProxyRequest request)
    {
        var item = Router.ParseObject(request);
        var existing = await store.GetAsync(Id(request)) ?? throw NotFound();
        item["id"] = existing["id"]?.DeepClone();
        item["createdAt"] = existing["createdAt"]?.DeepClone();
        item["updatedAt"] = Timestamp();
        await store.PutAsync(item);
        return Router.Json(200, item);
    }

    private async Task<APIGatewayProxyResponse> DeleteAsync(APIGatewayProxyRequest request)
    {
        if (!await store.DeleteAsync(Id(request)))
        {
            throw NotFound();
        }

        return Router.NoContent();
    }

    private static string Id(APIGatewayProxyRequest request)
    {
        return Router.PathParameter(request, "id");
    }

    private static HttpException NotFound()
    {
        return new HttpException(404, "Item not found");
    }

    // The current time in ISO-8601, UTC, with milliseconds.
    private static string Timestamp()
    {
        return DateTime.UtcNow.ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'", CultureInfo.InvariantCulture);
    }
}
