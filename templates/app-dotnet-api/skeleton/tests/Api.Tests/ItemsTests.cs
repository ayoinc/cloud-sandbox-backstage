using System.Net;
using System.Net.Http.Json;
using Api.Items;
using Microsoft.AspNetCore.Mvc.Testing;

namespace Api.Tests;

public sealed class ItemsTests(WebApplicationFactory<Program> factory) : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client = factory.CreateClient();

    private static CancellationToken Cancellation => TestContext.Current.CancellationToken;

    [Fact]
    public async Task Item_can_be_created_read_and_listed()
    {
        var created = await _client.PostAsJsonAsync("/api/items", new { name = "  first  " }, Cancellation);

        Assert.Equal(HttpStatusCode.Created, created.StatusCode);
        var item = await created.Content.ReadFromJsonAsync<Item>(Cancellation);
        Assert.NotNull(item);
        Assert.Equal("first", item.Name);
        Assert.EndsWith($"/api/items/{item.Id}", created.Headers.Location?.ToString());

        var fetched = await _client.GetFromJsonAsync<Item>($"/api/items/{item.Id}", Cancellation);
        Assert.Equal(item, fetched);

        var list = await _client.GetFromJsonAsync<ItemList>("/api/items", Cancellation);
        Assert.NotNull(list);
        Assert.Contains(item, list.Items);
    }

    [Theory]
    [InlineData("{}")]
    [InlineData("""{"name":""}""")]
    [InlineData("""{"name":"   "}""")]
    public async Task Invalid_input_is_rejected_with_validation_problem(string json)
    {
        using var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");

        var response = await _client.PostAsync("/api/items", content, Cancellation);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Equal("application/problem+json", response.Content.Headers.ContentType?.MediaType);
    }

    [Fact]
    public async Task Name_longer_than_200_characters_is_rejected()
    {
        var response = await _client.PostAsJsonAsync("/api/items", new { name = new string('a', 201) }, Cancellation);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Theory]
    [InlineData("/api/items/0198c1de-0000-7000-8000-000000000000")]
    [InlineData("/api/items/not-a-guid")]
    public async Task Unknown_item_is_not_found(string path)
    {
        var response = await _client.GetAsync(path, Cancellation);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}
