using System.Reflection;
using Api;
using Api.Items;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.Extensions.Options;

var builder = WebApplication.CreateBuilder(args);

// One JSON object per log line outside development, where the readable
// console format stays.
if (!builder.Environment.IsDevelopment())
{
    builder.Logging.ClearProviders();
    builder.Logging.AddJsonConsole(options =>
    {
        options.IncludeScopes = true;
        options.UseUtcTimestamp = true;
        options.TimestampFormat = "yyyy-MM-ddTHH:mm:ss.fffZ";
    });
}

builder.Services.Configure<ServiceOptions>(builder.Configuration.GetSection(ServiceOptions.SectionName));
var service = builder.Configuration.GetSection(ServiceOptions.SectionName).Get<ServiceOptions>() ?? new ServiceOptions();

builder.Services.AddOpenApi(options =>
    options.AddDocumentTransformer((document, _, _) =>
    {
        document.Info.Title = service.Name;
        document.Info.Description = service.Description;
        return Task.CompletedTask;
    }));

// Errors are answered as RFC 9457 problem details, never with a stack trace.
builder.Services.AddProblemDetails();
// Validates request bodies from their data annotations before the handler runs.
builder.Services.AddValidation();
builder.Services.AddHealthChecks();

builder.Services.AddSingleton(TimeProvider.System);
builder.Services.AddSingleton<IItemStore, InMemoryItemStore>();

var app = builder.Build();

app.UseExceptionHandler();
app.UseStatusCodePages();

// The OpenAPI document is served at /openapi/v1.json.
app.MapOpenApi();

var version = Assembly.GetExecutingAssembly().GetCustomAttribute<AssemblyInformationalVersionAttribute>()?.InformationalVersion ?? "unknown";

app.MapGet("/health", (IOptions<ServiceOptions> options, IHostEnvironment environment) =>
        TypedResults.Ok(new HealthResponse("ok", options.Value.Name, version, environment.EnvironmentName)))
    .WithName("GetHealth")
    .WithTags("Health");

// Liveness runs no check: the process answers. Readiness runs the checks
// tagged "ready"; register the ones for your dependencies with that tag.
app.MapHealthChecks("/health/live", new HealthCheckOptions { Predicate = _ => false });
app.MapHealthChecks("/health/ready", new HealthCheckOptions { Predicate = check => check.Tags.Contains("ready") });

app.MapItems();

app.Run();

internal sealed record HealthResponse(string Status, string Service, string Version, string Environment);
