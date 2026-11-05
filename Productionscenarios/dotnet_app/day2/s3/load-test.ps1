<#
.SYNOPSIS
  Synthetic checkout traffic for NET-D2-203. Sends concurrent POST /api/payments requests.
.EXAMPLE
  .\load-test.ps1 -Requests 500 -Concurrency 50
.NOTES
  Capped at 500 requests / 100 workers so the VM cannot freeze. Works on Windows PowerShell 5.1 and PowerShell 7.
  Exit code 0 = zero failures, 1 = at least one failure.   -AsJson prints one JSON line (used by `lab.ps1 check`).
#>
param(
    [int]$Requests = 500,
    [int]$Concurrency = 50,
    [string]$BaseUrl = 'http://localhost:5100',
    [switch]$AsJson
)

if ($Requests -gt 500)     { Write-Warning 'Requests capped at 500 (VM safety).'; $Requests = 500 }
if ($Concurrency -gt 100)  { Write-Warning 'Concurrency capped at 100 (VM safety).'; $Concurrency = 100 }
if ($Concurrency -lt 1)    { $Concurrency = 1 }
$url = $BaseUrl.TrimEnd('/') + '/api/payments'

$worker = {
    param($Url, $Body)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $status = 0; $err = ''
    try {
        $r = Invoke-WebRequest -Uri $Url -Method Post -Body $Body -ContentType 'application/json' -UseBasicParsing -TimeoutSec 60
        $status = [int]$r.StatusCode
    } catch {
        $err = $_.Exception.Message
        if ($_.Exception.Response) { try { $status = [int]$_.Exception.Response.StatusCode } catch { $status = 0 } }
    }
    [pscustomobject]@{ Status = $status; Ms = [int]$sw.ElapsedMilliseconds; Error = $err }
}

if (-not $AsJson) { Write-Host "Sending $Requests POST requests to $url with $Concurrency concurrent workers ..." -ForegroundColor Cyan }
$clock = [System.Diagnostics.Stopwatch]::StartNew()
$pool = [runspacefactory]::CreateRunspacePool(1, $Concurrency)
$pool.Open()
$rnd = New-Object System.Random 7
$jobs = New-Object System.Collections.ArrayList
for ($i = 1; $i -le $Requests; $i++) {
    $body = '{"orderId":' + $rnd.Next(1, 201) + ',"amount":' + (10 + $rnd.Next(0, 90)) + '.50}'
    $ps = [powershell]::Create()
    $ps.RunspacePool = $pool
    [void]$ps.AddScript($worker).AddArgument($url).AddArgument($body)
    [void]$jobs.Add([pscustomobject]@{ Ps = $ps; Handle = $ps.BeginInvoke() })
}
$results = @()
foreach ($j in $jobs) { $results += $j.Ps.EndInvoke($j.Handle); $j.Ps.Dispose() }
$pool.Close(); $pool.Dispose()
$clock.Stop()

$ok     = @($results | Where-Object { $_.Status -eq 200 }).Count
$failed = $Requests - $ok
$ms     = @($results | ForEach-Object { $_.Ms } | Sort-Object)
$avg    = if ($ms.Count) { [math]::Round(($ms | Measure-Object -Average).Average) } else { 0 }
$p95    = if ($ms.Count) { $ms[[math]::Max(0, [int][math]::Ceiling($ms.Count * 0.95) - 1)] } else { 0 }
$max    = if ($ms.Count) { $ms[-1] } else { 0 }

if ($AsJson) {
    @{ requests = $Requests; success = $ok; failed = $failed; avgMs = $avg; p95Ms = $p95; maxMs = $max } | ConvertTo-Json -Compress
} else {
    $byStatus = ($results | Group-Object Status | Sort-Object Name | ForEach-Object { "HTTP $($_.Name): $($_.Count)" }) -join '   '
    Write-Host ''
    Write-Host ("Requests: {0}   Concurrency: {1}   Elapsed: {2:N1} s" -f $Requests, $Concurrency, $clock.Elapsed.TotalSeconds)
    Write-Host ("Success (HTTP 200): {0}" -f $ok)
    Write-Host ("Failed: {0}   ({1})" -f $failed, $byStatus)
    Write-Host ("Latency ms: avg {0}   p95 {1}   max {2}" -f $avg, $p95, $max)
    $firstErr = $results | Where-Object { $_.Error } | Select-Object -First 1
    if ($firstErr) { Write-Host ("First error: " + $firstErr.Error) -ForegroundColor DarkYellow }
    if ($failed -eq 0) { Write-Host 'RESULT: PASS (0 failures)' -ForegroundColor Green } else { Write-Host "RESULT: FAIL ($failed failures - check logs\app.err.log for 'Timeout expired')" -ForegroundColor Red }
}
if ($failed -eq 0) { exit 0 } else { exit 1 }
