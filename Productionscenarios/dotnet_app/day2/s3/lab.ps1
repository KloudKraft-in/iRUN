<#
.SYNOPSIS
  NET-D2-203 harness - "Intermittent Timeouts Under Load: Connection Pool Exhausted"   (Windows, SQL Server LocalDB)
.DESCRIPTION
  .\lab.ps1 start     restore the starting code, (re)create + seed RetailPerformanceDb, run PaymentApi on :5100
  .\lab.ps1 restart   stop, rebuild YOUR changes, run again (use this after every code edit)
  .\lab.ps1 check     validate your fix and your evidence
  .\lab.ps1 reset     stop the app, restore starting code, re-seed the database, delete dumps
  PaymentApi runs as a plain Kestrel process under YOUR interactive account (LocalDB is per-user) - not under IIS.
#>
param([Parameter(Position = 0)][ValidateSet('start', 'restart', 'check', 'reset', 'help')][string]$Action = 'help')

. (Join-Path (Split-Path -Parent $PSScriptRoot) 'common\lab-common.ps1')

$LabDir  = $PSScriptRoot
$AppDir  = Join-Path $LabDir 'PaymentApi'
$Base    = Join-Path $LabDir '_baseline'
$LogDir  = Join-Path $LabDir 'logs'
$DumpDir = Join-Path $LabDir 'Dumps'
$Exe     = Join-Path $AppDir 'bin\Debug\net10.0\PaymentApi.exe'
$Evid    = Join-Path $LabDir 'evidence'
$StateF  = Join-Path (Get-StateDir) 'D2-3.json'
$Url     = 'http://localhost:5100'

function Stop-App {
    Get-Process -Name 'PaymentApi' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 800
}
function Restore-Baseline { Copy-Item (Join-Path $Base '*') $AppDir -Recurse -Force }

function Build-App {
    Write-Step 'dotnet build ...'
    $out = & dotnet build $AppDir -c Debug --nologo -v q 2>&1
    if ($LASTEXITCODE -ne 0) { $out | ForEach-Object { Write-Host $_ }; Write-Host 'BUILD FAILED - fix the compile error and run: .\lab.ps1 restart' -ForegroundColor Red; exit 2 }
}

function Initialize-Database {
    Write-Step 'Starting LocalDB and (re)creating RetailPerformanceDb ...'
    if (Get-Command SqlLocalDB.exe -ErrorAction SilentlyContinue) { & SqlLocalDB.exe start MSSQLLocalDB | Out-Null }
    Push-Location $AppDir
    try { & $Exe --init-db; if ($LASTEXITCODE -ne 0) { throw "init-db exited with $LASTEXITCODE" } } finally { Pop-Location }
}

function Start-App {
    New-Item -ItemType Directory -Path $LogDir, $DumpDir -Force | Out-Null
    $saved = @{}
    foreach ($k in 'DOTNET_ENVIRONMENT', 'ASPNETCORE_ENVIRONMENT', 'ASPNETCORE_URLS') { $saved[$k] = [Environment]::GetEnvironmentVariable($k, 'Process') }
    $env:DOTNET_ENVIRONMENT = 'Production'; $env:ASPNETCORE_ENVIRONMENT = 'Production'; $env:ASPNETCORE_URLS = $Url
    try {
        $p = Start-Process -FilePath $Exe -WorkingDirectory $AppDir -WindowStyle Hidden -PassThru `
            -RedirectStandardOutput (Join-Path $LogDir 'app.out.log') -RedirectStandardError (Join-Path $LogDir 'app.err.log')
    } finally {
        foreach ($k in $saved.Keys) { [Environment]::SetEnvironmentVariable($k, $saved[$k], 'Process') }
    }
    @{ pid = $p.Id; startedUtc = (Get-Date).ToUniversalTime().ToString('o') } | ConvertTo-Json | Set-Content $StateF
    if (-not (Wait-Until { (Get-HttpStatus "$Url/health") -eq 200 } 40)) { Write-Host "PaymentApi did not answer on $Url - see $LogDir\app.err.log" -ForegroundColor Red; exit 2 }
}

function Invoke-Start {
    Write-Step 'Preparing NET-D2-203 ...'
    if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) { Write-Host 'dotnet not found - run the setup script first.' -ForegroundColor Red; exit 2 }
    Stop-App; Restore-Baseline; Build-App; Initialize-Database; Start-App
    Write-Host ""
    Write-Host "TICKET NET-D2-203  [P2: errors come and go under peak load]" -ForegroundColor Yellow
    Write-Host "  At midday peaks, checkout intermittently fails: 'Timeout expired ... all pooled connections were in use and max pool size was reached'."
    Write-Host "  CPU and memory look normal, but latency and thread count spike. Pool: Max Pool Size=100."
    Write-Host "  PaymentApi PID: $((Get-Process PaymentApi).Id)   URL: $Url   Logs: $LogDir"
    Write-Host ""
    Write-Host "NEXT: open a 2nd and 3rd PowerShell; follow 02_Participant_Guide.md section D2-3." -ForegroundColor Cyan
}

function Invoke-Restart {
    Write-Step 'Restarting PaymentApi with your latest code ...'
    Stop-App; Build-App; Start-App
    Write-Host "Running again on $Url with a fresh, empty connection pool." -ForegroundColor Green
}

function Invoke-Reset {
    Stop-App
    Restore-Baseline
    Remove-Item $DumpDir, $LogDir -Recurse -Force -ErrorAction SilentlyContinue
    try { Build-App; Initialize-Database } catch { Write-Host "Could not re-seed the database: $($_.Exception.Message) (run start to rebuild it)" -ForegroundColor Yellow }
    Remove-Item $StateF -ErrorAction SilentlyContinue
    Write-Host 'D2-3 reset complete (app stopped, code restored, database re-seeded, dumps deleted).' -ForegroundColor Green
}

function Invoke-Check {
    if (-not (Test-Path $StateF)) { Write-Host 'Lab not started. Run: .\lab.ps1 start' -ForegroundColor Yellow; exit 3 }

    Add-Check 'PaymentApi answers on /health' ((Get-HttpStatus "$Url/health") -eq 200) 'start it with .\lab.ps1 restart'

    Write-Info 'Running a 150-request / 25-worker probe (a leaking build fails this) ...'
    $probe = $null
    try { $probe = (& (Join-Path $LabDir 'load-test.ps1') -Requests 150 -Concurrency 25 -AsJson | Select-Object -Last 1) | ConvertFrom-Json } catch { }
    $failed = if ($probe) { [int]$probe.failed } else { -1 }
    Add-Check 'Probe load: 150 requests, 0 failures (no connection leak)' ($failed -eq 0) "failed: $failed - did you run .\lab.ps1 restart after the fix?"

    $body = Get-HttpBody "$Url/api/orders/summary" -TimeoutSec 90
    $qc = -1; if ($body -match '"queryCount"\s*:\s*(\d+)') { $qc = [int]$Matches[1] }
    Add-Check 'EF Core N+1 removed: /api/orders/summary runs <= 3 SQL queries' (($qc -ge 1) -and ($qc -le 3)) "queryCount = $qc (the starting code runs about 401)"

    $dap = Get-Content (Join-Path $AppDir 'Services\DapperPaymentRepository.cs') -Raw
    Add-Check 'DapperPaymentRepository disposes its SqlConnection (using)' ($dap -match '\busing\s+(var\s+)?\w*\s*=?\s*(new\s+SqlConnection|connection)' -or $dap -match 'using\s+var\s+\w+\s*=\s*new\s+SqlConnection|await\s+using') 'wrap the connection in a using statement'

    foreach ($f in 'load-test-before.txt', 'counters-before.csv', 'counters-after.csv', 'dapper.diff', 'orderquery.diff', 'load-test-after.txt') {
        Add-Check "Evidence: $f present and non-empty" ((Test-Path (Join-Path $Evid $f)) -and ((Get-Item (Join-Path $Evid $f)).Length -gt 20))
    }
    $lb = Join-Path $Evid 'load-test-before.txt'
    Add-Check 'Evidence: load-test-before.txt really shows failures (the leak)' ((Test-Path $lb) -and ((Get-Content $lb -Raw) -match 'Failed:\s*[1-9]'))
    $la = Join-Path $Evid 'load-test-after.txt'
    Add-Check 'Evidence: load-test-after.txt shows "Failed: 0"' ((Test-Path $la) -and ((Get-Content $la -Raw) -match 'Failed:\s*0\b'))
    $dump = @(Get-ChildItem $DumpDir -Filter *.dmp -ErrorAction SilentlyContinue).Count
    Add-Check 'A process dump was captured with dotnet-dump (Dumps\*.dmp)' ($dump -gt 0) 'dotnet-dump collect -n PaymentApi -o .\Dumps\leak.dmp' -Warn

    Complete-Checks 'NET-D2-203'
}

switch ($Action) {
    'start'   { Invoke-Start }
    'restart' { Invoke-Restart }
    'check'   { Invoke-Check }
    'reset'   { Invoke-Reset }
    default   { Write-Host 'Usage: .\lab.ps1 start | restart | check | reset' }
}
