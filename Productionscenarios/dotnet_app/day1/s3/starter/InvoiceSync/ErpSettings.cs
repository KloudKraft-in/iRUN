using System.ComponentModel.DataAnnotations;

namespace InvoiceSync;

/// <summary>
/// ERP connection settings. appsettings.json (the Production baseline) deliberately ships an EMPTY
/// ConnectionString: production secrets are injected by the vault at go-live, never committed.
/// If the host believes it is in "Production" without those secrets, startup validation must stop it.
/// </summary>
public sealed class ErpSettings
{
    [Required(AllowEmptyStrings = false, ErrorMessage = "ConnectionString for Production ERP is required and must not be empty!")]
    public string? ConnectionString { get; set; }

    [Required]
    public string? LedgerName { get; set; }

    [Range(5, 3600)]
    public int SyncIntervalSeconds { get; set; } = 30;
}

