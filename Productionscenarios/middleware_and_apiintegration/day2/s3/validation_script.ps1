<#
.SYNOPSIS
  Validation & Harness Script for MIA-D2-203 - "Timeout Chain & RCA" (Windows)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    initialize incident
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    restore baseline state
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'check')

$LabDir   = $PSScriptRoot
$Starter  = Join-Path $LabDir 'starter'
$KongConf = Join-Path $Starter 'conf\kong_service.json'
$NgxConf  = Join-Path $Starter 'conf\checkout_nginx.conf'
$Evidence = Join-Path $Starter 'evidence\evidence_D2_3.md'

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
    $p8085 = Get-ListenerPid 8085
    if ($p8085 -gt 0) { Stop-Process -Id $p8085 -Force -ErrorAction SilentlyContinue }
    Write-Host "MIA-D2-203 reset complete." -ForegroundColor Green
}

function Invoke-Start {
    Invoke-Reset
    Write-Host "Staging Scenario MIA-D2-203: Distributed Timeout Inversion..." -ForegroundColor Cyan

    Start-Process python -ArgumentList (Join-Path $Starter "mock_services\slow_checkout_backend.py"), "8085" -WindowStyle Hidden
    Start-Sleep -Seconds 1

    Write-Host "`nTICKET MIA-D2-203 [P2: Intermittent 504 on Checkout & Ghost Orders]" -ForegroundColor Yellow
    Write-Host "  Kong read_timeout=3s while backend takes 5.2s. Outer timeout is too low!"
    Write-Host "NEXT: Inspect starter/logs/multi_hop_trace.log and follow Participant_Guide_day2.md Ticket 3."
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating MIA-D2-203: Distributed Timeout Chain   " -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan

    # Check 1: Kong timeout >= 12000
    $kOk = $false
    $kTimeout = 0
    if (Test-Path $KongConf) {
        $kongJson = Get-Content $KongConf -Raw | ConvertFrom-Json
        $kTimeout = [int]$kongJson.read_timeout
        $kOk = ($kTimeout -ge 12000)
    }
    Add-Check 'Kong Gateway read_timeout aligned to >= 12000ms' $kOk "Kong read_timeout is $kTimeout ms (expected >= 12000)"

    # Check 2: Nginx timeout >= 12s
    $nText = Get-Content $NgxConf -Raw -ErrorAction SilentlyContinue
    $nOk = ($nText -match 'proxy_read_timeout 12s')
    Add-Check 'Nginx proxy_read_timeout aligned to 12s' $nOk "Nginx proxy_read_timeout is not 12s"

    # Check 3: Evidence
    $evidOk = $false
    if (Test-Path $Evidence) {
        $evText = Get-Content $Evidence -Raw
        $evidOk = (-not ($evText -match '<<FILL'))
    }
    Add-Check 'Incident Escalation and RCA evidence recorded in evidence_D2_3.md' $evidOk "evidence_D2_3.md contains unfilled <<FILL>> fields"

    Complete-Checks 'MIA-D2-203'
}

switch ($Action) {
    'start' { Invoke-Start }
    'reset' { Invoke-Reset }
    'check' { Invoke-Check }
    'help'  { Get-Help $MyInvocation.MyCommand.Path -Detailed }
    default { Invoke-Check }
}
