<#
.SYNOPSIS
  Validation & Harness Script for MIA-D2-202 - "JWT Audience & SSL Repair" (Windows)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    initialize incident
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    restore baseline state
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'check')

$LabDir   = $PSScriptRoot
$Starter  = Join-Path $LabDir 'starter'
$Config   = Join-Path $Starter 'gateway_auth_config.json'
$Certs    = Join-Path $Starter 'certs\cert_metadata.json'
$Evidence = Join-Path $Starter 'evidence\evidence_D2_2.md'

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
    $p8443 = Get-ListenerPid 8443
    if ($p8443 -gt 0) { Stop-Process -Id $p8443 -Force -ErrorAction SilentlyContinue }
    Write-Host "MIA-D2-202 reset complete." -ForegroundColor Green
}

function Invoke-Start {
    Invoke-Reset
    Write-Host "Staging Scenario MIA-D2-202: JWT & SSL Repair..." -ForegroundColor Cyan

    Push-Location $Starter
    try {
        python generate_certs.py
        '{"allowed_audiences": ["mobile-app-v2"], "clock_skew": 0}' | Out-File -FilePath "gateway_auth_config.json" -Encoding ascii
    } finally { Pop-Location }

    Start-Process python -ArgumentList (Join-Path $Starter "mock_services\auth_gateway.py"), "8443" -WindowStyle Hidden
    Start-Sleep -Seconds 1

    Write-Host "`nTICKET MIA-D2-202 [P2: Mobile Login 401 & SSL Outage]" -ForegroundColor Yellow
    Write-Host "  JWT audience mismatch and expired SSL certificate active on port 8443."
    Write-Host "NEXT: Inspect starter/client_simulator.py and follow Participant_Guide_day2.md Ticket 2."
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating MIA-D2-202: JWT & SSL Handshake Repair  " -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan

    # Check 1: Allowed audience
    $cfg = Get-Content $Config -Raw -ErrorAction SilentlyContinue
    $audOk = ($cfg -match 'retail-web-client')
    Add-Check 'Gateway configured to accept retail-web-client audience' $audOk "Missing retail-web-client in allowed_audiences"

    # Check 2: SSL certificate valid
    $certOk = $false
    if (Test-Path $Certs) {
        $certJson = Get-Content $Certs -Raw | ConvertFrom-Json
        $certOk = ($certJson.active.status -eq 'VALID')
    }
    Add-Check 'Renewed SSL certificate bundle active and valid' $certOk "Active certificate still has status EXPIRED"

    # Check 3: Authenticated request returns 200 OK
    $tokenOutput = python (Join-Path $Starter "client_simulator.py")
    $token = ($tokenOutput -split "`r?`n")[2].Trim()
    $status = 0
    try {
        $res = Invoke-WebRequest -Uri "http://localhost:8443" -Headers @{ "Authorization" = "Bearer $token" } -Method GET -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        $status = [int]$res.StatusCode
    } catch {
        if ($_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }
    }
    Add-Check 'Mobile client authenticated successfully with HTTP 200 OK' ($status -eq 200) "HTTP status: $status (expected 200)"

    # Check 4: Evidence
    $evidOk = $false
    if (Test-Path $Evidence) {
        $evText = Get-Content $Evidence -Raw
        $evidOk = (-not ($evText -match '<<FILL'))
    }
    Add-Check 'Incident evidence recorded in evidence_D2_2.md' $evidOk "evidence_D2_2.md contains unfilled <<FILL>> fields"

    Complete-Checks 'MIA-D2-202'
}

switch ($Action) {
    'start' { Invoke-Start }
    'reset' { Invoke-Reset }
    'check' { Invoke-Check }
    'help'  { Get-Help $MyInvocation.MyCommand.Path -Detailed }
    default { Invoke-Check }
}
