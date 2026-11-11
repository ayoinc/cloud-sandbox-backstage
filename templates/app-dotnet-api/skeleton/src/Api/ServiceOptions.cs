namespace Api;

/// <summary>Identity of the service, bound to the "Service" configuration section.</summary>
public sealed class ServiceOptions
{
    public const string SectionName = "Service";

    public string Name { get; init; } = "api";

    public string Description { get; init; } = "";
}
