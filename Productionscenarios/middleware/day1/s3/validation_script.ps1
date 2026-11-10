<#
.SYNOPSIS
  Validation & Harness Script for MIA-D1-103 - "Kong Gateway Route & Security" (Windows)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    initialize incident
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    restore baseline state
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'check')

$LabDir   = $PSScriptRoot
$Starter  = Join-Path $LabDir 'starter'
$Evidence = Join-Path $Starter 'evidence\evidence_D1_3.md'
$StateF   = Join-Path $env:TEMP 'lab-state-D1-3.json'

$global:Checks = @()
function Add-Check {
    param([string]$Title, [bool]$Passed, [string]$Details = '', [switch]$Warn)
    $status = if ($Passed) { 'PASS' } elseif ($Warn) { 'WARN' } else { 'FAIL' }
    $global:Checks += [pscustomobject]@{ Title = $Title; Passed = $Passed; Status = $status; Details = $Details }
    $color = if ($Passed) { 'Green' } elseif ($Warn) { 'Yellow' } else { 'Red' }
    Write-Host "  [$status] $Title" -ForegroundColor $color
    if (-not $Passed -and $Details) { Write-Host "         $Details" -ForegroundColor Yellow }
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
        exit 0
    }
}

function Get-ListenerPid {
    param([int]$Port)
    try {
        $found = netstat -ano | findstr ":$Port" | findstr "LISTENING"
        if ($found) {
            $tokens = ($found -split '\s+') | Where-Object { $_ -ne '' }
            if ($tokens.Count -ge 5) { return [int]$tokens[-1] }
            return 9999
        }
    } catch {}
    return 0
}

function Invoke-Reset {
    $st = if (Test-Path $StateF) { Get-Content $StateF -Raw | ConvertFrom-Json } else { $null }
    if ($st) {
        if ($st.backendPid) { Stop-Process -Id $st.backendPid -Force -ErrorAction SilentlyContinue }
        if ($st.gatewayPid) { Stop-Process -Id $st.gatewayPid -Force -ErrorAction SilentlyContinue }
    }
    foreach ($p in @(8000, 8001, 8081)) {
        $pidOnPort = Get-ListenerPid $p
        if ($pidOnPort -gt 0) { Stop-Process -Id $pidOnPort -Force -ErrorAction SilentlyContinue }
    }
    Remove-Item $StateF -ErrorAction SilentlyContinue
    Write-Host "MIA-D1-103 reset complete." -ForegroundColor Green
}

function Invoke-Start {
    Invoke-Reset
    Write-Host "Staging Scenario MIA-D1-103: Kong Gateway..." -ForegroundColor Cyan

    $b = Start-Process python -ArgumentList (Join-Path $Starter "mock_services\inventory_backend.py"), "8081" -PassThru -WindowStyle Hidden
    $k = Start-Process python -ArgumentList (Join-Path $Starter "mock_services\kong_mock_gateway.py") -PassThru -WindowStyle Hidden
    Start-Sleep -Seconds 1
    @{ backendPid = $b.Id; gatewayPid = $k.Id } | ConvertTo-Json | Set-Content $StateF

    Write-Host "`nTICKET MIA-D1-103 [P3: Partner API 404 & Missing Rate Limit]" -ForegroundColor Yellow
    Write-Host "  Kong route path is mismatched (/v1/inventory vs /api/v1/inventory)."
    Write-Host "NEXT: Query http://localhost:8001/routes and follow Participant_Guide_day1.md Ticket 3."
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating MIA-D1-103: Kong Gateway Enforcement   " -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan

    # Check 1: Missing key returns 401
    $c401 = 0
    try {
        $res = Invoke-WebRequest -Uri "http://localhost:8000/api/v1/inventory" -Method GET -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        $c401 = [int]$res.StatusCode
    } catch {
        if ($_.Exception.Response) { $c401 = [int]$_.Exception.Response.StatusCode }
    }
    Add-Check 'Unauthenticated request rejected with HTTP 401 Unauthorized' ($c401 -eq 401) "Returned status $c401"

    # Check 2: Invalid key returns 403
    $c403 = 0
    try {
        $res = Invoke-WebRequest -Uri "http://localhost:8000/api/v1/inventory" -Headers @{ "apikey" = "bad_token" } -Method GET -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        $c403 = [int]$res.StatusCode
    } catch {
        if ($_.Exception.Response) { $c403 = [int]$_.Exception.Response.StatusCode }
    }
    Add-Check 'Request with invalid API key rejected with HTTP 403 Forbidden' ($c403 -eq 403) "Returned status $c403"

    # Check 3: Valid key returns 200
    $c200 = 0
    try {
        $res = Invoke-WebRequest -Uri "http://localhost:8000/api/v1/inventory" -Headers @{ "apikey" = "LogisticsSecretKey2026" } -Method GET -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        $c200 = [int]$res.StatusCode
    } catch {
        if ($_.Exception.Response) { $c200 = [int]$_.Exception.Response.StatusCode }
    }
    Add-Check 'Valid request with LogisticsSecretKey2026 returns HTTP 200 OK' ($c200 -eq 200) "Returned status $c200"

    # Check 4: Rate limit returns 429
    for ($i=1; $i -le 5; $i++) {
        try { Invoke-WebRequest -Uri "http://localhost:8000/api/v1/inventory" -Headers @{ "apikey" = "LogisticsSecretKey2026" } -Method GET -UseBasicParsing -ErrorAction SilentlyContinue } catch {}
    }
    $c429 = 0
    try {
        $res = Invoke-WebRequest -Uri "http://localhost:8000/api/v1/inventory" -Headers @{ "apikey" = "LogisticsSecretKey2026" } -Method GET -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        $c429 = [int]$res.StatusCode
    } catch {
        if ($_.Exception.Response) { $c429 = [int]$_.Exception.Response.StatusCode }
    }
    Add-Check 'Traffic flood triggers HTTP 429 Too Many Requests (Rate limit active)' ($c429 -eq 429) "Returned status $c429"

    # Check 5: Evidence
    $evidOk = $false
    if (Test-Path $Evidence) {
        $evText = Get-Content $Evidence -Raw
        $evidOk = (-not ($evText -match '<<FILL'))
    }
    Add-Check 'Incident evidence and error matrix recorded in evidence_D1_3.md' $evidOk "evidence_D1_3.md contains unfilled <<FILL>> fields"

    Complete-Checks 'MIA-D1-103'
}

switch ($Action) {
    'start' { Invoke-Start }
    'reset' { Invoke-Reset }
    'check' { Invoke-Check }
    'help'  { Get-Help $MyInvocation.MyCommand.Path -Detailed }
    default { Invoke-Check }
}
