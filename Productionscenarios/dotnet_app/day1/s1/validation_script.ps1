<#
.SYNOPSIS
  Validation & Harness Script for NET-D1-101 - "Orders API Port Conflict" (Windows)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    initialize incident (inject fault & start legacy daemon)
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    restore baseline state
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'check')

# --- Self-Contained Lab Helpers ---
function Assert-Admin {
    $p = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "This operation must be run from an ELEVATED PowerShell window (Run as Administrator)." -ForegroundColor Red
        exit 1
    }
}

function Get-StateDir {
    $dir = Join-Path $env:TEMP 'lab-state'
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    return $dir
}

function Write-Step {
    param([string]$Message)
    Write-Host "[STEP] $Message" -ForegroundColor Cyan
}

function Get-ListenerPid {
    param([int]$Port)
    $conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($conn) { return $conn.OwningProcess }
    return 0
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
$AppDir   = Join-Path $Starter 'OrdersApi'
$Daemon   = Join-Path $Starter 'legacy-sync-daemon.ps1'
$StateF   = Join-Path (Get-StateDir) 'D1-1.json'
$VarName  = 'Kestrel__Endpoints__Http__Url'
$BadValue = 'http://localhost:5055'
$Evidence = Join-Path $Starter 'evidence\evidence_D1_1.json'

function Invoke-Reset {
    param([switch]$Quiet)
    Assert-Admin
    Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -and $_.CommandLine -match 'legacy-sync-daemon\.ps1' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^(OrdersApi|dotnet)\.exe$' -and $_.CommandLine -match 'OrdersApi' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    foreach ($scope in 'Machine', 'User') { [Environment]::SetEnvironmentVariable($VarName, $null, $scope) }
    Remove-Item "Env:$VarName" -ErrorAction SilentlyContinue
    Remove-Item $StateF -ErrorAction SilentlyContinue
    if (-not $Quiet) { Write-Host "D1-1 reset complete. (Open shells keep stale env vars - close them or Remove-Item Env:$VarName.)" -ForegroundColor Green }
}

function Invoke-Start {
    Assert-Admin
    Write-Step 'Preparing NET-D1-101 ...'
    Invoke-Reset -Quiet

    if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) { Write-Host 'dotnet not found - install .NET SDK first.' -ForegroundColor Red; exit 2 }

    $hostExe = (Get-Process -Id $PID).Path
    Start-Process -FilePath $hostExe -WindowStyle Hidden `
        -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$Daemon`"", '-Port', '5055') | Out-Null
    if (-not (Wait-Until { (Get-ListenerPid 5055) -gt 0 } 15)) { Write-Host 'Legacy daemon failed to start.' -ForegroundColor Red; exit 2 }
    $daemonPid = Get-ListenerPid 5055

    [Environment]::SetEnvironmentVariable($VarName, $BadValue, 'Machine')

    Write-Step 'Building OrdersApi ...'
    Push-Location $AppDir
    try { & dotnet build -c Debug --nologo -v q | Out-Null; if ($LASTEXITCODE -ne 0) { throw 'dotnet build failed' } } finally { Pop-Location }

    @{ daemonPid = $daemonPid; startedUtc = (Get-Date).ToUniversalTime().ToString('o') } | ConvertTo-Json | Set-Content $StateF

    Write-Host ""
    Write-Host "TICKET NET-D1-101  [P2: app is completely down]" -ForegroundColor Yellow
    Write-Host "  The Orders API was reconfigured to listen on http://localhost:5060 (appsettings.json)"
    Write-Host "  but on deployment it crashes: 'Failed to bind ... address already in use'."
    Write-Host "  A legacy daemon on port 5055 must NOT be disturbed."
    Write-Host ""
    Write-Host "NEXT:" -ForegroundColor Cyan
    Write-Host "  1. Open a NEW elevated PowerShell or refresh this one."
    Write-Host "  2. cd starter\OrdersApi ; dotnet run --no-build"
    Write-Host "  3. Follow Participant_Guide_day1.md Ticket 1."
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating NET-D1-101: Orders API Port Conflict   " -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan

    if (-not (Test-Path $StateF)) {
        Write-Host "State file not found. If running standalone validation, starting incident checks directly..." -ForegroundColor Yellow
    }
    $st = if (Test-Path $StateF) { Get-Content $StateF -Raw | ConvertFrom-Json } else { $null }

    # 1. legacy daemon untouched
    $d = Get-ListenerPid 5055
    if ($st) {
        Add-Check 'Legacy daemon still serves port 5055 with the SAME PID (it was not killed)' ($d -eq [int]$st.daemonPid) "expected PID $($st.daemonPid), found $d"
    } else {
        Add-Check 'Legacy daemon still serves port 5055' ($d -gt 0) "daemon listener found on PID $d"
    }

    # 2. OrdersApi on 5060
    $o = Get-ListenerPid 5060
    Add-Check 'OrdersApi is listening on port 5060' ($o -gt 0) 'Start the API (dotnet run --no-build) and leave it running in another window while you run validation.'
    if ($o -gt 0) {
        $pname = (Get-Process -Id $o -ErrorAction SilentlyContinue).ProcessName
        Add-Check 'The listener on 5060 is OrdersApi (not something else)' ($pname -match 'OrdersApi|dotnet') "listener is '$pname'"
    }
    $code = Get-HttpStatus 'http://localhost:5060/health'
    Add-Check 'GET /health on 5060 returns 200' ($code -eq 200) "got HTTP $code"
    Add-Check '/health body reports Healthy' ((Get-HttpBody 'http://localhost:5060/health') -match 'Healthy')

    # 3. permanent fix vs workaround
    $mv = [Environment]::GetEnvironmentVariable($VarName, 'Machine')
    Add-Check 'Machine-scope override removed (permanent fix)' (-not $mv) "Machine variable $VarName is still '$mv'." -Warn

    # 4. evidence file
    $ok = $false; $why = "missing file $Evidence"
    if (Test-Path $Evidence) {
        try {
            $j = Get-Content $Evidence -Raw | ConvertFrom-Json
            $miss = @()
            if (-not $j.startupLogLine -or $j.startupLogLine -notmatch 'Now listening on' -or $j.startupLogLine -notmatch '5060') { $miss += 'startupLogLine' }
            if (-not $j.healthResponse -or [int]$j.healthResponse.statusCode -ne 200) { $miss += 'healthResponse.statusCode' }
            foreach ($k in 'sdkVersion', 'runtimeVersion', 'frameworkDescription', 'os') { if (-not $j.runtime.$k) { $miss += "runtime.$k" } }
            if ($j.runtime.deploymentModel -notmatch '^(framework-dependent|self-contained)$') { $miss += 'runtime.deploymentModel (must be framework-dependent or self-contained)' }
            foreach ($k in 'name', 'scope', 'value') { if (-not $j.overridingVariable.$k) { $miss += "overridingVariable.$k" } }
            if (-not $j.rootCause -or $j.rootCause.Length -lt 20) { $miss += 'rootCause (explain in a sentence)' }
            if ([int]$j.legacyDaemon.pid -le 0) { $miss += 'legacyDaemon.pid' }
            $ok = ($miss.Count -eq 0); $why = 'incomplete fields: ' + ($miss -join ', ')
        } catch { $why = 'not valid JSON' }
    }
    Add-Check 'evidence_D1_1.json is complete' $ok $why

    Complete-Checks 'NET-D1-101'
}

switch ($Action) {
    'start' { Invoke-Start }
    'check' { Invoke-Check }
    'reset' { Invoke-Reset }
    default { Invoke-Check }
}
