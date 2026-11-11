using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;

namespace Api.Tests;

public sealed class HealthTests(WebApplicationFactory<Program> factory) : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client = factory.CreateClient();

    private static CancellationToken Cancellation => TestContext.Current.CancellationToken;

    [Fact]
    public async Task Health_reports_the_service()
    {
        var body = await _client.GetFromJsonAsync<JsonElement>("/health", Cancellation);

        Assert.Equal("ok", body.GetProperty("status").GetString());
        Assert.False(string.IsNullOrEmpty(body.GetProperty("service").GetString()));
        Assert.False(string.IsNullOrEmpty(body.GetProperty("environment").GetString()));
    }

    [Theory]
    [InlineData("/health/live")]
    [InlineData("/health/ready")]
    public async Task Probes_answer_healthy(string path)
    {
        var response = await _client.GetAsync(path, Cancellation);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("Healthy", await response.Content.ReadAsStringAsync(Cancellation));
    }

    [Fact]
    public async Task OpenApi_document_describes_the_endpoints()
    {
        var document = await _client.GetFromJsonAsync<JsonElement>("/openapi/v1.json", Cancellation);

        var paths = document.GetProperty("paths");
        Assert.True(paths.TryGetProperty("/health", out _));
        Assert.True(paths.TryGetProperty("/api/items", out _));
        Assert.True(paths.TryGetProperty("/api/items/{id}", out _));
    }

    [Fact]
    public async Task Unknown_routes_answer_problem_details()
    {
        var response = await _client.GetAsync("/nowhere", Cancellation);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        Assert.Equal("application/problem+json", response.Content.Headers.ContentType?.MediaType);
    }
}
