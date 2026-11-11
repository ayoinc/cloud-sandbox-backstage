// HTTP service with root, health, readiness and metrics endpoints.

var builder = WebApplication.CreateBuilder(args);

// PORT is set in the container image; without it ASP.NET Core uses its own
// defaults (launch settings, ASPNETCORE_URLS).
if (Environment.GetEnvironmentVariable("PORT") is { } port)
{
    builder.WebHost.UseUrls($"http://0.0.0.0:{port}");
}

var app = builder.Build();

long requests = 0;
app.Use(async (context, next) =>
{
    Interlocked.Increment(ref requests);
    await next(context);
});

app.MapGet("/", () => Results.Json(new
{
    service = ServiceName,
    environment = Environment.GetEnvironmentVariable("ENVIRONMENT") ?? "local",
}));
app.MapGet("/health", () => Results.Json(new { status = "healthy" }));
app.MapGet("/ready", () => Results.Json(new { status = "ready" }));

// Prometheus text exposition format
app.MapGet("/metrics", () => Results.Text(
    "# HELP http_requests_total Requests handled by the service.\n" +
    "# TYPE http_requests_total counter\n" +
    $"http_requests_total {Interlocked.Read(ref requests)}\n",
    "text/plain; version=0.0.4"));

app.MapFallback(() => Results.Json(new { error = "Not Found" }, statusCode: StatusCodes.Status404NotFound));

app.Run();

// Public so that the test project can start the application.
public partial class Program
{
    public const string ServiceName = "${{ values.name }}";
}
