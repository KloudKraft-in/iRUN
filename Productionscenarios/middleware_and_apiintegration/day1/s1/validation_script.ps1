<#
.SYNOPSIS
  Validation & Harness Script for MIA-D1-101 - "Tomcat Port Collision" (Windows)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    initialize incident (inject fault & start legacy daemon)
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    restore baseline state
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'check')

$LabDir   = $PSScriptRoot
$Starter  = Join-Path $LabDir 'starter'
$Conf     = Join-Path $Starter 'conf\server.xml'
$ConfBak  = Join-Path $Starter 'conf\server.xml.bak'
$Evidence = Join-Path $Starter 'evidence\evidence_D1_1.json'
$StateF   = Join-Path $env:TEMP 'lab-state-D1-1.json'

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

function Wait-Until {
    param([scriptblock]$Condition, [int]$TimeoutSeconds = 10)
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
    if ($st -and $st.daemonPid) {
        Stop-Process -Id $st.daemonPid -Force -ErrorAction SilentlyContinue
    }
    $p8082 = Get-ListenerPid 8082
    if ($p8082 -gt 0) { Stop-Process -Id $p8082 -Force -ErrorAction SilentlyContinue }
    $p8080 = Get-ListenerPid 8080
    if ($p8080 -gt 0) { Stop-Process -Id $p8080 -Force -ErrorAction SilentlyContinue }
    Remove-Item $StateF -ErrorAction SilentlyContinue
    Write-Host "MIA-D1-101 reset complete." -ForegroundColor Green
}

function Invoke-Start {
    Invoke-Reset
    Write-Host "Staging Scenario MIA-D1-101: Tomcat Port Collision..." -ForegroundColor Cyan

    # Ensure broken server.xml
    $xml = Get-Content $Conf -Raw
    $xml = $xml -replace 'port="8080"', 'port="8082"'
    [System.IO.File]::WriteAllText($Conf, $xml)
    Remove-Item $ConfBak -ErrorAction SilentlyContinue

    # Start conflicting daemon on 8082
    $daemonScript = Join-Path $Starter "legacy-sync-daemon.ps1"
    $hostExe = (Get-Process -Id $PID).Path
    $daemon = Start-Process -FilePath $hostExe -WindowStyle Hidden `
        -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$daemonScript`"", '-Port', '8082') -PassThru
    
    Start-Sleep -Seconds 1
    @{ daemonPid = $daemon.Id; startedUtc = (Get-Date).ToUniversalTime().ToString('o') } | ConvertTo-Json | Set-Content $StateF

    Write-Host "`nTICKET MIA-D1-101 [P2: Retail Catalog Down]" -ForegroundColor Yellow
    Write-Host "  Tomcat connector changed to port 8082, colliding with existing daemon."
    Write-Host "NEXT STEPS:" -ForegroundColor Cyan
    Write-Host "  1. Inspect starter/logs/catalina.out for BindException."
    Write-Host "  2. Follow Participant_Guide_day1.md Ticket 1."
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating MIA-D1-101: Tomcat Port Collision       " -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan

    # Check 1: Confirmed legacy daemon still occupies 8082 (untouched)
    $st = if (Test-Path $StateF) { Get-Content $StateF -Raw | ConvertFrom-Json } else { $null }
    $dRunning = $false
    if ($st -and $st.daemonPid) {
        $p = Get-Process -Id $st.daemonPid -ErrorAction SilentlyContinue
        if ($p) { $dRunning = $true }
    }
    if (-not $dRunning) { $dRunning = ((Get-ListenerPid 8082) -gt 0) }
    Add-Check 'Legacy daemon still occupies port 8082 (it was not killed)' $dRunning "Legacy daemon process not detected"

    # Check 2: server.xml port set to 8080
    $xml = Get-Content $Conf -Raw -ErrorAction SilentlyContinue
    $portOk = ($xml -match 'port="8080"')
    Add-Check 'server.xml HTTP Connector configured to port 8080' $portOk "Connector port is not 8080"

    # Check 3: Backup file exists
    $bakOk = Test-Path $ConfBak
    Add-Check 'Production backup file server.xml.bak exists' $bakOk "server.xml.bak missing"

    # Check 4: Catalog endpoint responds 200 OK on 8080
    $status8080 = 0
    try {
        $res = Invoke-WebRequest -Uri "http://localhost:8080/catalog" -Method GET -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        $status8080 = [int]$res.StatusCode
    } catch {
        if ($_.Exception.Response) { $status8080 = [int]$_.Exception.Response.StatusCode }
    }
    Add-Check 'Catalog service responds HTTP 200 OK on port 8080' ($status8080 -eq 200) "HTTP status: $status8080 (expected 200)"

    # Check 5: Evidence file filled
    $evidOk = $false
    if (Test-Path $Evidence) {
        $evContent = Get-Content $Evidence -Raw
        $evidOk = (-not ($evContent -match '<<FILL'))
    }
    Add-Check 'Incident evidence recorded in evidence_D1_1.json' $evidOk "evidence_D1_1.json contains unfilled <<FILL>> fields"

    Complete-Checks 'MIA-D1-101'
}

switch ($Action) {
    'start' { Invoke-Start }
    'reset' { Invoke-Reset }
    'check' { Invoke-Check }
    'help'  { Get-Help $MyInvocation.MyCommand.Path -Detailed }
    default { Invoke-Check }
}
