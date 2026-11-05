# legacy-sync-daemon.ps1 - stand-in for the legacy integration daemon that owns TCP 5055.
# Started by validation script / harness. It must keep running: the legacy team depends on it.
param([int]$Port = 5055)

$listener = $null
try {
    # dual-stack socket: holds 127.0.0.1 AND ::1 like a real service bound to "any"
    $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::IPv6Any, $Port)
    $listener.Server.DualMode = $true
    $listener.Start()
} catch {
    $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $Port)
    $listener.Start()
}

$body  = 'LEGACY-SYNC-DAEMON OK'
$resp  = "HTTP/1.1 200 OK`r`nContent-Type: text/plain`r`nContent-Length: $($body.Length)`r`nConnection: close`r`n`r`n$body"
$bytes = [Text.Encoding]::ASCII.GetBytes($resp)

while ($true) {
    $client = $listener.AcceptTcpClient()
    try {
        $stream = $client.GetStream()
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush()
    } catch { } finally { $client.Close() }
}

