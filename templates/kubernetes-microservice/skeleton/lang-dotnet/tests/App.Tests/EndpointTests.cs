using System.Net;
using System.Net.Http.Json;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

namespace App.Tests;

public class EndpointTests(WebApplicationFactory<Program> factory) : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task RootReturnsTheServiceNameAndEnvironment()
    {
        var body = await _client.GetFromJsonAsync<Dictionary<string, string>>("/");

        Assert.NotNull(body);
        Assert.Equal(Program.ServiceName, body["service"]);
        Assert.Equal(Environment.GetEnvironmentVariable("ENVIRONMENT") ?? "local", body["environment"]);
    }

    [Theory]
    [InlineData("/health", "healthy")]
    [InlineData("/ready", "ready")]
    public async Task ProbeEndpointsReportTheirStatus(string path, string status)
    {
        var body = await _client.GetFromJsonAsync<Dictionary<string, string>>(path);

        Assert.NotNull(body);
        Assert.Equal(status, body["status"]);
    }

    [Fact]
    public async Task MetricsCountsRequestsInThePrometheusTextFormat()
    {
        var body = await _client.GetStringAsync("/metrics");

        Assert.Matches(new Regex(@"^http_requests_total \d+$", RegexOptions.Multiline), body);
    }

    [Fact]
    public async Task UnknownPathsReturn404()
    {
        var response = await _client.GetAsync("/missing");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}
