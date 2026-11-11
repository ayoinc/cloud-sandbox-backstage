using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using Amazon.Lambda.APIGatewayEvents;

namespace Api;

// Handler of one route of the route table.
public delegate Task<APIGatewayProxyResponse> RouteHandler(APIGatewayProxyRequest request);

// Thrown by a handler to answer with a specific status and message.
public sealed class HttpException(int statusCode, string message) : Exception(message)
{
    public int StatusCode { get; } = statusCode;
}

// Helpers shared by every endpoint: responses, request parsing and routing
// of API Gateway proxy events.
public static class Router
{
    public static APIGatewayProxyResponse Json(int statusCode, JsonNode body)
    {
        return new APIGatewayProxyResponse
        {
            StatusCode = statusCode,
            Headers = new Dictionary<string, string> { ["Content-Type"] = "application/json" },
            Body = body.ToJsonString(),
        };
    }

    public static APIGatewayProxyResponse NoContent()
    {
        return new APIGatewayProxyResponse
        {
            StatusCode = 204,
            Headers = new Dictionary<string, string>(),
            Body = "",
        };
    }

    // The body {"message": ...} of an error response.
    public static JsonObject Message(string message)
    {
        return new JsonObject { ["message"] = message };
    }

    // The value of a parameter of the path template, "" when it is absent.
    public static string PathParameter(APIGatewayProxyRequest request, string name)
    {
        if (request.PathParameters is { } parameters && parameters.TryGetValue(name, out var value))
        {
            return value ?? "";
        }

        return "";
    }

    // The request body as an object. Anything else is a client error.
    public static JsonObject ParseObject(APIGatewayProxyRequest request)
    {
        try
        {
            var body = request.Body ?? "";
            var json = request.IsBase64Encoded ? Encoding.UTF8.GetString(Convert.FromBase64String(body)) : body;
            if (JsonNode.Parse(json) is JsonObject value)
            {
                return value;
            }
        }
        catch (Exception error) when (error is JsonException or FormatException)
        {
            // Neither JSON nor base64 is answered like any other body that is not an object.
        }

        throw new HttpException(400, "The request body must be a JSON object");
    }

    // Stub of an endpoint that is routed but has no implementation yet.
    public static Task<APIGatewayProxyResponse> NotImplemented(APIGatewayProxyRequest request)
    {
        var message = $"{request.HttpMethod} {request.Resource} is not implemented";
        return Task.FromResult(Json(501, Message(message)));
    }

    // Calls the handler registered for "<METHOD> <resource path>". An unexpected
    // exception is passed to logError and answered with 500.
    public static async Task<APIGatewayProxyResponse> RouteAsync(
        IReadOnlyDictionary<string, RouteHandler> routes,
        APIGatewayProxyRequest request,
        Action<string> logError)
    {
        if (!routes.TryGetValue($"{request.HttpMethod} {request.Resource}", out var handler))
        {
            return Json(404, Message("Not found"));
        }

        try
        {
            return await handler(request);
        }
        catch (HttpException error)
        {
            return Json(error.StatusCode, Message(error.Message));
        }
        catch (Exception error)
        {
            logError(error.ToString());
            return Json(500, Message("Internal server error"));
        }
    }
}
