using System.Text.Json.Nodes;
using Amazon.Lambda.APIGatewayEvents;

namespace Api.Tests;

// API Gateway proxy events and response bodies for the tests.
internal static class Http
{
    public static APIGatewayProxyRequest Request(string method, string resource, string? id = null, string? body = null)
    {
        var request = new APIGatewayProxyRequest { HttpMethod = method, Resource = resource };
        if (id is not null)
        {
            request.PathParameters = new Dictionary<string, string> { ["id"] = id };
        }

        if (body is not null)
        {
            request.Body = body;
        }

        return request;
    }

    public static JsonNode Body(APIGatewayProxyResponse response)
    {
        return JsonNode.Parse(response.Body ?? "") ?? throw new InvalidOperationException("The body is null");
    }

    // The string attribute of a JSON object, "" when it is absent.
    public static string Text(JsonNode node, string name)
    {
        return node[name]?.GetValue<string>() ?? "";
    }
}
