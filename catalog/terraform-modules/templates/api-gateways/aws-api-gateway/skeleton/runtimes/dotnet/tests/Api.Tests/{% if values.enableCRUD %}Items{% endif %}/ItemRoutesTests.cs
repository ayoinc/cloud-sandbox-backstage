using System.Globalization;
using System.Text.Json.Nodes;
using Amazon.Lambda.APIGatewayEvents;
using Api.Items;
using Xunit;

namespace Api.Tests.Items;

public class ItemRoutesTests
{
    private readonly Dictionary<string, RouteHandler> _routes = ItemRoutes.Create(new MemoryItemStore());

    private Task<APIGatewayProxyResponse> Call(string method, string resource, string? id = null, string? body = null)
    {
        return Router.RouteAsync(_routes, Http.Request(method, resource, id, body), _ => { });
    }

    private async Task<JsonNode> Create(string body)
    {
        return Http.Body(await Call("POST", "/items", body: body));
    }

    [Fact]
    public async Task PostStoresTheBodyWithAnIdAndTimestamps()
    {
        var response = await Call("POST", "/items", body: "{\"name\":\"first\"}");

        Assert.Equal(201, response.StatusCode);
        var item = Http.Body(response);
        Assert.Equal("first", Http.Text(item, "name"));
        Assert.Matches("^[0-9a-f-]{36}$", Http.Text(item, "id"));
        Assert.Equal(Http.Text(item, "createdAt"), Http.Text(item, "updatedAt"));
        var createdAt = Http.Text(item, "createdAt");
        Assert.True(DateTimeOffset.TryParse(createdAt, CultureInfo.InvariantCulture, DateTimeStyles.None, out _));
    }

    [Theory]
    [InlineData(null)]
    [InlineData("not json")]
    [InlineData("[\"not\",\"an\",\"object\"]")]
    public async Task PostRejectsABodyThatIsNotAJsonObject(string? body)
    {
        var response = await Call("POST", "/items", body: body);

        Assert.Equal(400, response.StatusCode);
        Assert.Equal("The request body must be a JSON object", Http.Text(Http.Body(response), "message"));
    }

    [Fact]
    public async Task GetItemsListsWhatWasStored()
    {
        var first = await Create("{\"name\":\"first\"}");
        var second = await Create("{\"name\":\"second\"}");

        var response = await Call("GET", "/items");

        Assert.Equal(200, response.StatusCode);
        var expected = new JsonObject { ["items"] = new JsonArray(first.DeepClone(), second.DeepClone()) };
        Assert.True(JsonNode.DeepEquals(expected, Http.Body(response)));
    }

    [Fact]
    public async Task GetItemReturnsTheItemOr404()
    {
        var item = await Create("{\"name\":\"first\"}");

        var found = await Call("GET", "/items/{id}", Http.Text(item, "id"));
        Assert.Equal(200, found.StatusCode);
        Assert.True(JsonNode.DeepEquals(item, Http.Body(found)));

        var missing = await Call("GET", "/items/{id}", "unknown");
        Assert.Equal(404, missing.StatusCode);
        Assert.Equal("Item not found", Http.Text(Http.Body(missing), "message"));
    }

    [Fact]
    public async Task PutReplacesTheAttributesAndKeepsIdAndCreatedAt()
    {
        var item = await Create("{\"name\":\"first\",\"colour\":\"red\"}");
        var id = Http.Text(item, "id");

        var body = "{\"name\":\"renamed\",\"id\":\"ignored\",\"createdAt\":\"ignored\"}";
        var response = await Call("PUT", "/items/{id}", id, body);

        Assert.Equal(200, response.StatusCode);
        var updated = Http.Body(response);
        Assert.Equal("renamed", Http.Text(updated, "name"));
        Assert.Null(updated["colour"]);
        Assert.Equal(id, Http.Text(updated, "id"));
        Assert.Equal(Http.Text(item, "createdAt"), Http.Text(updated, "createdAt"));
        Assert.NotEmpty(Http.Text(updated, "updatedAt"));

        var stored = await Call("GET", "/items/{id}", id);
        Assert.True(JsonNode.DeepEquals(updated, Http.Body(stored)));
    }

    [Fact]
    public async Task PutAnswers404ForAnUnknownItemAnd400ForABodyThatIsNotAnObject()
    {
        var missing = await Call("PUT", "/items/{id}", "unknown", "{\"name\":\"x\"}");
        Assert.Equal(404, missing.StatusCode);
        Assert.Equal("Item not found", Http.Text(Http.Body(missing), "message"));

        var item = await Create("{\"name\":\"first\"}");
        var invalid = await Call("PUT", "/items/{id}", Http.Text(item, "id"), "[1]");
        Assert.Equal(400, invalid.StatusCode);
    }

    [Fact]
    public async Task DeleteRemovesTheItemOrAnswers404()
    {
        var item = await Create("{\"name\":\"first\"}");
        var id = Http.Text(item, "id");

        var deleted = await Call("DELETE", "/items/{id}", id);
        Assert.Equal(204, deleted.StatusCode);
        Assert.Empty(deleted.Body);

        var again = await Call("DELETE", "/items/{id}", id);
        Assert.Equal(404, again.StatusCode);

        var gone = await Call("GET", "/items/{id}", id);
        Assert.Equal(404, gone.StatusCode);
    }
}
