namespace InvoiceSync;

/// <summary>Tiny append-only log so both platforms leave the same evidence: ..\Logs\invoice_sync.log</summary>
internal static class FileLog
{
    private static readonly object Gate = new();

    public static string LogPath { get; } =
        Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "Logs", "invoice_sync.log"));

    public static void Write(string level, string message)
    {
        try
        {
            lock (Gate)
            {
                Directory.CreateDirectory(Path.GetDirectoryName(LogPath)!);
                File.AppendAllText(LogPath, $"{DateTimeOffset.Now:yyyy-MM-dd HH:mm:ss zzz} [{level}] {message}{Environment.NewLine}");
            }
        }
        catch
        {
            // logging must never be the reason the service dies
        }
    }
}

