// OrdersApi - Retail Orders API (NET-D1-101)
// Intentionally tiny: the lesson is about HOW it is hosted and configured, not about orders.
using System.Runtime.InteropServices;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => Results.Ok(new
{
    service = "OrdersApi",
    ticket = "NET-D1-101",
    utc = DateTimeOffset.UtcNow
}));

// Liveness endpoint used by the load balancer and by `lab check`.
app.MapGet("/health", () => Results.Ok(new { status = "Healthy" }));

// Runtime identification helper (use it to fill in evidence_D1_1.json).
app.MapGet("/runtime", () =>
{
    var runtimeDir = RuntimeEnvironment.GetRuntimeDirectory();
    var selfContained = runtimeDir.StartsWith(AppContext.BaseDirectory, StringComparison.OrdinalIgnoreCase);
    return Results.Ok(new
    {
        frameworkDescription = RuntimeInformation.FrameworkDescription,   // e.g. ".NET 10.0.x"
        clrVersion = Environment.Version.ToString(),
        runtimeDirectory = runtimeDir,
        deploymentModel = selfContained ? "self-contained" : "framework-dependent",
        os = RuntimeInformation.OSDescription,
        architecture = RuntimeInformation.ProcessArchitecture.ToString(),
        processId = Environment.ProcessId
    });
});

app.Run();
