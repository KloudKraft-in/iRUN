// InvoiceSync - background worker that synchronises invoices into the ERP ledger (NET-D1-103).
// It is a *Generic Host* application (Host.CreateApplicationBuilder), NOT a web host.
using InvoiceSync;

var builder = Host.CreateApplicationBuilder(new HostApplicationBuilderSettings
{
    Args = args,
    ContentRootPath = AppContext.BaseDirectory      // services start in System32 / "/" - never rely on the working directory
});

builder.Services.AddWindowsService(o => o.ServiceName = "InvoiceSyncService");   // active only under the Windows SCM
builder.Services.AddSystemd();                                                   // active only under systemd

builder.Services.AddOptions<ErpSettings>()
    .Bind(builder.Configuration.GetSection("Erp"))
    .ValidateDataAnnotations()
    .ValidateOnStart();                                                          // fail fast at startup, not at 3 a.m.

builder.Services.AddHostedService<SyncWorker>();

var host = builder.Build();
try
{
    await host.RunAsync();
    return 0;
}
catch (Exception ex)
{
    var root = ex is AggregateException ae ? ae.Flatten().InnerExceptions.First() : ex;
    var message = $"Unhandled exception: {root.GetType().Name}: {root.Message}";
    host.Services.GetRequiredService<ILoggerFactory>().CreateLogger("InvoiceSync").LogCritical(root, "{Message}", message);
    FileLog.Write("CRITICAL", message + $" (host environment was '{builder.Environment.EnvironmentName}')");
    return 1;
}
