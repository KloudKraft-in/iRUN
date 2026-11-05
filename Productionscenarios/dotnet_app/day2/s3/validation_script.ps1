<#
.SYNOPSIS
  Validation & Harness Script for NET-D2-203 - "Connection Pool Exhausted" (Windows, LocalDB)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    restore baseline, reseed DB and run PaymentApi on :5100
  .\validation_script.ps1 restart  stop, rebuild your changes, run again
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    stop app, restore starting code, re-seed DB
#>
param([Parameter(Position = 0)][ValidateSet('start', 'restart', 'check', 'reset', 'help')][string]$Action = 'check')

# --- Self-Contained Lab Helpers ---
function Get-StateDir {
    $dir = Join-Path $env:TEMP 'lab-state'
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    return $dir
}

function Write-Step {
    param([string]$Message)
    Write-Host "[STEP] $Message" -ForegroundColor Cyan
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Gray
}

function Wait-Until {
    param([scriptblock]$Condition, [int]$TimeoutSeconds = 15)
    $elapsed = 0
    while ($elapsed -lt $TimeoutSeconds) {
        if (& $Condition) { return $true }
        Start-Sleep -Seconds 1
        $elapsed++
    }
    return $false
}

$global:Checks = @()
function Add-Check {
    param([string]$Title, [bool]$Passed, [string]$Details = '', [switch]$Warn)
    $status = if ($Passed) { 'PASS' } elseif ($Warn) { 'WARN' } else { 'FAIL' }
    $global:Checks += [pscustomobject]@{ Title = $Title; Passed = $Passed; Status = $status; Details = $Details }
    $color = if ($Passed) { 'Green' } elseif ($Warn) { 'Yellow' } else { 'Red' }
    Write-Host "  [$status] $Title" -ForegroundColor $color
    if (-not $Passed -and $Details) { Write-Host "         $Details" -ForegroundColor Yellow }
}

function Get-HttpStatus {
    param([string]$Uri, [int]$TimeoutSec = 5)
    try {
        $res = Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec $TimeoutSec -ErrorAction Stop
        return [int]$res.StatusCode
    } catch {
        if ($_.Exception.Response) { return [int]$_.Exception.Response.StatusCode }
        return 0
    }
}

function Get-HttpBody {
    param([string]$Uri, [int]$TimeoutSec = 5)
    try {
        $res = Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec $TimeoutSec -ErrorAction Stop
        return $res.Content
    } catch {
        if ($_.Exception.Response) {
            $stream = $_.Exception.Response.GetResponseStream()
            if ($stream) {
                $reader = New-Object System.IO.StreamReader($stream)
                return $reader.ReadToEnd()
            }
        }
        return ''
    }
}

function Complete-Checks {
    param([string]$ScenarioName)
    $failed = @($global:Checks | Where-Object { $_.Status -eq 'FAIL' })
    $passed = @($global:Checks | Where-Object { $_.Status -eq 'PASS' })
    $total  = $global:Checks.Count
    Write-Host "`n===================================================" -ForegroundColor Cyan
    Write-Host " Validation Results for ${ScenarioName}: $($passed.Count)/$total passed" -ForegroundColor $(if ($failed.Count -eq 0) { 'Green' } else { 'Yellow' })
    Write-Host "===================================================" -ForegroundColor Cyan
    if ($failed.Count -gt 0) {
        Write-Host " [FAIL] Some validation checks failed. Please review guidelines." -ForegroundColor Red
        exit 1
    } else {
        Write-Host " [PASS] $ScenarioName Validation Succeeded!" -ForegroundColor Green
    }
}

# --- Scenario Paths ---
$LabDir   = $PSScriptRoot
$Starter  = Join-Path $LabDir 'starter'
$AppDir   = Join-Path $Starter 'PaymentApi'
$Base     = Join-Path $Starter '_baseline'
$LogDir   = Join-Path $Starter 'logs'
$DumpDir  = Join-Path $Starter 'Dumps'
$Exe      = Join-Path $AppDir 'bin\Debug\net10.0\PaymentApi.exe'
$Evid     = Join-Path $Starter 'evidence'
$LoadTest = Join-Path $Starter 'load-test.ps1'
$StateF   = Join-Path (Get-StateDir) 'D2-3.json'
$Url      = 'http://localhost:5100'

function Stop-App {
    Get-Process -Name 'PaymentApi' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 800
}

function Restore-Baseline { Copy-Item (Join-Path $Base '*') $AppDir -Recurse -Force }

function Build-App {
    Write-Step 'dotnet build ...'
    $out = & dotnet build $AppDir -c Debug --nologo -v q 2>&1
    if ($LASTEXITCODE -ne 0) { $out | ForEach-Object { Write-Host $_ }; Write-Host 'BUILD FAILED - fix the compile error and run: .\validation_script.ps1 restart' -ForegroundColor Red; exit 2 }
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
    if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) { Write-Host 'dotnet not found - install .NET SDK first.' -ForegroundColor Red; exit 2 }
    Stop-App; Restore-Baseline; Build-App; Initialize-Database; Start-App
    Write-Host ""
    Write-Host "TICKET NET-D2-203  [P2: errors come and go under peak load]" -ForegroundColor Yellow
    Write-Host "  At midday peaks, checkout intermittently fails: 'Timeout expired ... Max pool size (100) was reached'."
    Write-Host "  PaymentApi URL: $Url"
    Write-Host ""
    Write-Host "NEXT: follow Participant_Guide_day2.md Ticket 3." -ForegroundColor Cyan
}

function Invoke-Restart {
    Write-Step 'Restarting PaymentApi with your latest code ...'
    Stop-App; Build-App; Start-App
    Write-Host "Running again on $Url with a fresh connection pool." -ForegroundColor Green
}

function Invoke-Reset {
    Stop-App
    Restore-Baseline
    Remove-Item $DumpDir, $LogDir -Recurse -Force -ErrorAction SilentlyContinue
    try { Build-App; Initialize-Database } catch { Write-Host "Could not re-seed database: $($_.Exception.Message)" -ForegroundColor Yellow }
    Remove-Item $StateF -ErrorAction SilentlyContinue
    Write-Host 'D2-3 reset complete.' -ForegroundColor Green
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating NET-D2-203: Connection Pool Leak & N+1 " -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan

    Add-Check 'PaymentApi answers on /health' ((Get-HttpStatus "$Url/health") -eq 200)

    Write-Info 'Running a 150-request / 25-worker probe (a leaking build fails this) ...'
    $probe = $null
    try { $probe = (& $LoadTest -Requests 150 -Concurrency 25 -AsJson | Select-Object -Last 1) | ConvertFrom-Json } catch { }
    $failed = if ($probe) { [int]$probe.failed } else { -1 }
    Add-Check 'Probe load: 150 requests, 0 failures (no connection leak)' ($failed -eq 0) "failed: $failed"

    $body = Get-HttpBody "$Url/api/orders/summary" -TimeoutSec 90
    $qc = -1; if ($body -match '"queryCount"\s*:\s*(\d+)') { $qc = [int]$Matches[1] }
    Add-Check 'EF Core N+1 removed: /api/orders/summary runs <= 3 SQL queries' (($qc -ge 1) -and ($qc -le 3)) "queryCount = $qc"

    $dap = Get-Content (Join-Path $AppDir 'Services\DapperPaymentRepository.cs') -Raw
    Add-Check 'DapperPaymentRepository disposes SqlConnection (using)' ($dap -match '\busing\s+(var\s+)?\w*\s*=?\s*(new\s+SqlConnection|connection)' -or $dap -match 'using\s+var\s+\w+\s*=\s*new\s+SqlConnection|await\s+using')

    foreach ($f in 'load-test-before.txt', 'counters-before.csv', 'counters-after.csv', 'dapper.diff', 'orderquery.diff', 'load-test-after.txt') {
        Add-Check "Evidence: $f present and non-empty" ((Test-Path (Join-Path $Evid $f)) -and ((Get-Item (Join-Path $Evid $f)).Length -gt 20))
    }
    $lb = Join-Path $Evid 'load-test-before.txt'
    Add-Check 'Evidence: load-test-before.txt shows failures' ((Test-Path $lb) -and ((Get-Content $lb -Raw) -match 'Failed:\s*[1-9]'))
    $la = Join-Path $Evid 'load-test-after.txt'
    Add-Check 'Evidence: load-test-after.txt shows "Failed: 0"' ((Test-Path $la) -and ((Get-Content $la -Raw) -match 'Failed:\s*0\b'))

    Complete-Checks 'NET-D2-203'
}

switch ($Action) {
    'start'   { Invoke-Start }
    'restart' { Invoke-Restart }
    'check'   { Invoke-Check }
    'reset'   { Invoke-Reset }
    default   { Invoke-Check }
}
