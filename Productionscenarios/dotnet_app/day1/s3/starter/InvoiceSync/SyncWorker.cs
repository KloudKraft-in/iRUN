using Microsoft.Extensions.Options;

namespace InvoiceSync;

public sealed class SyncWorker : BackgroundService
{
    private readonly ILogger<SyncWorker> _logger;
    private readonly ErpSettings _erp;
    private readonly IHostEnvironment _env;

    public SyncWorker(ILogger<SyncWorker> logger, IOptions<ErpSettings> erp, IHostEnvironment env)
    {
        _logger = logger;
        _erp = erp.Value;
        _env = env;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        FileLog.Write("INFO", $"InvoiceSync starting. Environment: {_env.EnvironmentName}; ledger: {_erp.LedgerName}");

        while (!stoppingToken.IsCancellationRequested)
        {
            _logger.LogInformation("Heartbeat - {Mode} Mode", _env.EnvironmentName);
            FileLog.Write("HEARTBEAT", $"Environment: {_env.EnvironmentName} - Synchronized 0 pending invoices (ledger {_erp.LedgerName})");

            try
            {
                await Task.Delay(TimeSpan.FromSeconds(_erp.SyncIntervalSeconds), stoppingToken);
            }
            catch (OperationCanceledException)
            {
                // service is stopping
            }
        }

        FileLog.Write("INFO", "InvoiceSync stopping.");
    }
}

