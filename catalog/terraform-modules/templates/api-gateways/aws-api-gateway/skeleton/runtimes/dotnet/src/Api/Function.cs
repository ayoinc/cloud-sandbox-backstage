using Amazon.Lambda.APIGatewayEvents;
using Amazon.Lambda.Core;
using Amazon.Lambda.Serialization.SystemTextJson;

[assembly: LambdaSerializer(typeof(DefaultLambdaJsonSerializer))]

namespace Api;

// Entry point of the Lambda function (handler "Api::Api.Function::FunctionHandler").
public sealed class Function
{
    private readonly Dictionary<string, RouteHandler> _routes = Routes.Create();

    public Task<APIGatewayProxyResponse> FunctionHandler(APIGatewayProxyRequest request, ILambdaContext context)
    {
        return Router.RouteAsync(_routes, request, message => context.Logger.LogError(message));
    }
}
