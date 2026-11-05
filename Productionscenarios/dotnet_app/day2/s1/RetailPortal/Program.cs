// RetailPortal - Ubuntu analogue of the IIS "RetailPortal" site (NET-D2-201).
// Endpoints/certificates come from appsettings.json (Kestrel section).
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => Results.Content("<h1>Retail Portal</h1><p>Status: <strong>OK</strong></p>", "text/html"));

// Which operating-system identity is this process running as? (the Linux equivalent of "w3wp.exe runs as IIS APPPOOL\RetailPortalPool")
app.MapGet("/whoami", () => Results.Ok(new
{
    user = Environment.UserName,
    processId = Environment.ProcessId,
    utc = DateTimeOffset.UtcNow
}));

app.Run();
