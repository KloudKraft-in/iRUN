// OrderService - Retail Order Service (NET-D2-202)
using System.Text.Json;
using Microsoft.AspNetCore.Server.Kestrel.Core;
using Retail.Core;
using Retail.Services;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddScoped<OrderProcessor>();

var app = builder.Build();

app.MapGet("/health/live", () => Results.Text("Healthy"));

app.MapGet("/health/ready", (IServiceProvider services) =>
{
    using var scope = services.CreateScope();
    scope.ServiceProvider.GetRequiredService<OrderProcessor>();
    return Results.Text("Ready");
});

app.MapGet("/api/orders", (OrderProcessor processor) =>
    Results.Ok(new[]
    {
        processor.Price("C-1001", 320m),
        processor.Price("C-1002", 780m),
        processor.Price("C-1003", 1450m)
    }));

app.MapPost("/api/orders", async (HttpRequest request, OrderProcessor processor) =>
{
    using var reader = new StreamReader(request.Body);
    var body = await reader.ReadToEndAsync();

    using var doc = JsonDocument.Parse(body);
    var customerId = doc.RootElement.TryGetProperty("customerId", out var c) ? c.GetString() ?? "unknown" : "unknown";
    var subtotal = doc.RootElement.TryGetProperty("subtotal", out var s) && s.TryGetDecimal(out var d) ? d : 0m;
    return Results.Ok(processor.Price(customerId, subtotal));
});

app.Run();

