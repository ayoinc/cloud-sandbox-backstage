using Amazon.Lambda.TestUtilities;
using Xunit;

namespace Api.Tests;

public class RoutesTests
{
    private readonly Function _function = new();

    [Fact]
    public void EveryRouteKeyIsAMethodAndAPath()
    {
        foreach (var key in Routes.Create().Keys)
        {
            Assert.Matches(@"^(GET|POST|PUT|DELETE) /\S*$", key);
        }
    }

    [Fact]
    public async Task HealthReportsTheService()
    {
        var response = await _function.FunctionHandler(Http.Request("GET", "/health"), new TestLambdaContext());

        Assert.Equal(200, response.StatusCode);
        var body = Http.Body(response);
        Assert.Equal("ok", Http.Text(body, "status"));
        Assert.NotEmpty(Http.Text(body, "service"));
        Assert.NotEmpty(Http.Text(body, "version"));
    }

    [Fact]
    public async Task EndpointsWithoutAnImplementationAnswer501()
    {
        RouteHandler stub = Router.NotImplemented;
        foreach (var (key, handler) in Routes.Create())
        {
            if (!handler.Equals(stub))
            {
                continue;
            }

            var parts = key.Split(' ', 2);
            var response = await _function.FunctionHandler(Http.Request(parts[0], parts[1]), new TestLambdaContext());

            Assert.Equal(501, response.StatusCode);
            Assert.Equal($"{key} is not implemented", Http.Text(Http.Body(response), "message"));
        }
    }

    [Fact]
    public async Task ARouteThatIsNotInTheTableAnswers404()
    {
        var response = await _function.FunctionHandler(Http.Request("GET", "/missing"), new TestLambdaContext());

        Assert.Equal(404, response.StatusCode);
    }
}
