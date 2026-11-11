using System.Text;
using System.Text.Json.Nodes;
using Amazon.Lambda.APIGatewayEvents;
using Xunit;

namespace Api.Tests;

public class RouterTests
{
    private readonly List<string> _logged = [];

    private Task<APIGatewayProxyResponse> Route(RouteHandler handler)
    {
        var routes = new Dictionary<string, RouteHandler> { ["GET /things"] = handler };
        return Router.RouteAsync(routes, Http.Request("GET", "/things"), _logged.Add);
    }

    [Fact]
    public async Task CallsTheHandlerRegisteredForTheMethodAndResource()
    {
        var response = await Route(_ => Task.FromResult(Router.Json(200, new JsonObject { ["ok"] = true })));

        Assert.Equal(200, response.StatusCode);
        Assert.Equal("application/json", response.Headers["Content-Type"]);
        Assert.True(Http.Body(response)["ok"]?.GetValue<bool>());
    }

    [Fact]
    public async Task Answers404ForARouteThatIsNotRegistered()
    {
        var routes = new Dictionary<string, RouteHandler>();

        var response = await Router.RouteAsync(routes, Http.Request("GET", "/missing"), _logged.Add);

        Assert.Equal(404, response.StatusCode);
        Assert.Equal("Not found", Http.Text(Http.Body(response), "message"));
    }

    [Fact]
    public async Task TurnsAnHttpExceptionIntoItsStatusAndMessage()
    {
        var response = await Route(_ => throw new HttpException(409, "Conflict"));

        Assert.Equal(409, response.StatusCode);
        Assert.Equal("Conflict", Http.Text(Http.Body(response), "message"));
        Assert.Empty(_logged);
    }

    [Fact]
    public async Task Answers500AndLogsWhenAHandlerFailsUnexpectedly()
    {
        var response = await Route(_ => throw new InvalidOperationException("boom"));

        Assert.Equal(500, response.StatusCode);
        Assert.Equal("Internal server error", Http.Text(Http.Body(response), "message"));
        Assert.Contains("boom", Assert.Single(_logged));
    }

    [Fact]
    public async Task AStubbedEndpointAnswers501WithItsMethodAndPath()
    {
        var routes = new Dictionary<string, RouteHandler> { ["POST /reports/{id}"] = Router.NotImplemented };

        var response = await Router.RouteAsync(routes, Http.Request("POST", "/reports/{id}"), _logged.Add);

        Assert.Equal(501, response.StatusCode);
        Assert.Equal("POST /reports/{id} is not implemented", Http.Text(Http.Body(response), "message"));
    }

    [Fact]
    public void ParseObjectReadsPlainAndBase64Bodies()
    {
        var plain = Router.ParseObject(Http.Request("POST", "/x", body: "{\"a\":1}"));
        Assert.Equal(1, plain["a"]?.GetValue<int>());

        var encoded = Http.Request("POST", "/x", body: Convert.ToBase64String(Encoding.UTF8.GetBytes("{\"b\":2}")));
        encoded.IsBase64Encoded = true;
        Assert.Equal(2, Router.ParseObject(encoded)["b"]?.GetValue<int>());
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("not json")]
    [InlineData("[1]")]
    [InlineData("\"text\"")]
    [InlineData("3")]
    [InlineData("null")]
    public void ParseObjectRejectsAnythingThatIsNotAJsonObject(string? body)
    {
        var error = Assert.Throws<HttpException>(() => Router.ParseObject(Http.Request("POST", "/x", body: body)));

        Assert.Equal(400, error.StatusCode);
        Assert.Equal("The request body must be a JSON object", error.Message);
    }

    [Fact]
    public void ParseObjectRejectsABodyThatIsNotBase64()
    {
        var request = Http.Request("POST", "/x", body: "{}");
        request.IsBase64Encoded = true;

        var error = Assert.Throws<HttpException>(() => Router.ParseObject(request));

        Assert.Equal(400, error.StatusCode);
    }
}
