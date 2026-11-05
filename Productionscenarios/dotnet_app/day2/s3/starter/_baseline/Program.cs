// PaymentApi - checkout payments + order summaries (NET-D2-203)
using Microsoft.EntityFrameworkCore;
using PaymentApi.Data;
using PaymentApi.Services;

var builder = WebApplication.CreateBuilder(args);

var connectionString = builder.Configuration.GetConnectionString("RetailPerformanceDb")
    ?? throw new InvalidOperationException("Connection string 'RetailPerformanceDb' is missing.");

builder.Services.AddDbContext<RetailDbContext>(o =>
    o.UseSqlServer(connectionString).AddInterceptors(new QueryCountingInterceptor()));
builder.Services.AddScoped<IPaymentRepository, DapperPaymentRepository>();
builder.Services.AddScoped<OrderQueryService>();

var app = builder.Build();

if (args.Any(a => a.StartsWith("--init-db", StringComparison.OrdinalIgnoreCase)))
{
    using var scope = app.Services.CreateScope();
    await DbSeeder.ResetAsync(scope.ServiceProvider.GetRequiredService<RetailDbContext>());
    Console.WriteLine("RetailPerformanceDb dropped, re-created and seeded (50 customers, 200 orders).");
    return;
}

app.MapGet("/health", () => Results.Ok(new { status = "Healthy" }));

app.MapPost("/api/payments", async (PaymentRequest request, IPaymentRepository repository, ILogger<Program> log) =>
{
    try
    {
        var id = await repository.ProcessPaymentAsync(request.OrderId, request.Amount);
        return Results.Ok(new { paymentId = id });
    }
    catch (InvalidOperationException ex) when (ex.Message.Contains("Timeout expired", StringComparison.OrdinalIgnoreCase))
    {
        log.LogError(ex, "Connection pool exhausted while processing payment for order {OrderId}", request.OrderId);
        return Results.Problem(title: "Database connection timeout", detail: ex.Message, statusCode: 503);
    }
});

app.MapGet("/api/orders/summary", async (OrderQueryService service) => Results.Ok(await service.GetOrderSummariesAsync()));

app.Run();

public sealed record PaymentRequest(int OrderId, decimal Amount);

