// CustomerPortal - Retail Customer Portal (NET-D1-102)
// The page and /whoami tell you WHICH PROCESS answered - that is how you prove
// In-Process (w3wp) vs Out-of-Process (dotnet behind a proxy).
using System.Diagnostics;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () =>
{
    var p = Process.GetCurrentProcess();
    var html = $"""
        <!doctype html>
        <html><head><title>Retail Customer Portal</title></head>
        <body style="font-family:sans-serif">
          <h1>Retail Customer Portal</h1>
          <p>Status: <strong>OK</strong></p>
          <p>Answered by process <code>{p.ProcessName}</code> (PID {p.Id}).</p>
        </body></html>
        """;
    return Results.Content(html, "text/html");
});

app.MapGet("/whoami", () =>
{
    var p = Process.GetCurrentProcess();
    return Results.Ok(new
    {
        processName = p.ProcessName,      // "w3wp" when In-Process, "dotnet" when Out-of-Process / Kestrel
        processId = p.Id,
        workingSetMB = Math.Round(p.WorkingSet64 / 1024d / 1024d, 1),
        machine = Environment.MachineName,
        utc = DateTimeOffset.UtcNow
    });
});

app.Run();
