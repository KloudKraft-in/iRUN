# legacy-sync-daemon.ps1 - stand-in for the legacy integration daemon that owns TCP 8082.
# Started by validation script / harness. It must keep running: the legacy team depends on it.
param([int]$Port = 8082)

$listener = $null
try {
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
    try {
        $client = $listener.AcceptTcpClient()
        $stream = $client.GetStream()
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush()
        $client.Close()
    } catch { }
}

