<#
.SYNOPSIS
  Validation & Harness Script for MIA-D1-102 - "Nginx 502 Upstream Repair" (Windows)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    initialize incident
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    restore baseline state
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'check')

$LabDir   = $PSScriptRoot
$Starter  = Join-Path $LabDir 'starter'
$Conf     = Join-Path $Starter 'conf.d\retail_promo.conf'
$ConfBak  = Join-Path $Starter 'conf.d\retail_promo.conf.bak'
$Evidence = Join-Path $Starter 'evidence\evidence_D1_2.md'
$StateF   = Join-Path $env:TEMP 'lab-state-D1-2.json'

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
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect('127.0.0.1', $Port)
        $tcp.Close()
        return 9999
    } catch {}
    return 0
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

function Invoke-Reset {
    $st = if (Test-Path $StateF) { Get-Content $StateF -Raw | ConvertFrom-Json } else { $null }
    if ($st -and $st.backendPid) {
        Stop-Process -Id $st.backendPid -Force -ErrorAction SilentlyContinue
    }
    $p8080 = Get-ListenerPid 8080
    if ($p8080 -gt 0) { Stop-Process -Id $p8080 -Force -ErrorAction SilentlyContinue }
    Remove-Item $StateF -ErrorAction SilentlyContinue
    Write-Host "MIA-D1-102 reset complete." -ForegroundColor Green
}

function Invoke-Start {
    Invoke-Reset
    Write-Host "Staging Scenario MIA-D1-102: Nginx 502 Bad Gateway..." -ForegroundColor Cyan

    # Ensure broken config points to 9090
    (Get-Content $Conf) -replace '127.0.0.1:8080', '127.0.0.1:9090' | Set-Content $Conf
    Remove-Item $ConfBak -ErrorAction SilentlyContinue

    # Start promo backend on 8080
    $p = Start-Process python -ArgumentList (Join-Path $Starter "mock_services\promo_backend.py"), "8080" -PassThru -WindowStyle Hidden
    Start-Sleep -Seconds 1
    @{ backendPid = $p.Id } | ConvertTo-Json | Set-Content $StateF

    Write-Host "`nTICKET MIA-D1-102 [P2: Customer 502 Outage]" -ForegroundColor Yellow
    Write-Host "  Nginx proxying /promo to dead port 9090. Upstream is on 8080."
    Write-Host "NEXT: Inspect starter/logs/error.log and follow Participant_Guide_day1.md Ticket 2."
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating MIA-D1-102: Nginx 502 Upstream Repair   " -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan

    # Check 1: Promo backend is alive on 8080
    $b8080 = Get-ListenerPid 8080
    Add-Check 'Promo backend microservice is listening on port 8080' ($b8080 -gt 0) "No process listening on 8080"

    # Check 2: retail_promo.conf targets 8080
    $confText = Get-Content $Conf -Raw -ErrorAction SilentlyContinue
    $portOk = ($confText -match 'proxy_pass http://127.0.0.1:8080')
    Add-Check 'Nginx virtual host configured to proxy_pass http://127.0.0.1:8080' $portOk "proxy_pass does not target 127.0.0.1:8080"

    # Check 3: Essential client IP forwarding headers
    $hdrsOk = ($confText -match 'X-Forwarded-For' -and $confText -match 'X-Real-IP')
    Add-Check 'Client IP forwarding headers (X-Real-IP, X-Forwarded-For) present' $hdrsOk "Missing reverse proxy headers"

    # Check 4: Endpoint returns 200 OK
    $status = 0
    try {
        $res = Invoke-WebRequest -Uri "http://127.0.0.1:8080/promo" -Method GET -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        $status = [int]$res.StatusCode
    } catch {
        if ($_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }
    }
    Add-Check 'Promotional endpoint returns HTTP 200 OK' ($status -eq 200) "HTTP status: $status"

    # Check 5: Evidence file filled
    $evidOk = $false
    if (Test-Path $Evidence) {
        $evText = Get-Content $Evidence -Raw
        $evidOk = (-not ($evText -match '<<FILL'))
    }
    Add-Check 'Incident evidence recorded in evidence_D1_2.md' $evidOk "evidence_D1_2.md contains unfilled <<FILL>> fields"

    Complete-Checks 'MIA-D1-102'
}

switch ($Action) {
    'start' { Invoke-Start }
    'reset' { Invoke-Reset }
    'check' { Invoke-Check }
    'help'  { Get-Help $MyInvocation.MyCommand.Path -Detailed }
    default { Invoke-Check }
}
