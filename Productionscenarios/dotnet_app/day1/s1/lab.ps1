<#
.SYNOPSIS
  NET-D1-101 harness - "Orders API Ignores Its New Port and Won't Start"   (Windows)
.DESCRIPTION
  .\lab.ps1 start   inject the fault (legacy daemon on 5055 + hidden machine-level override)
  .\lab.ps1 check   validate your fix and your evidence
  .\lab.ps1 reset   restore the pristine baseline
  Run from an ELEVATED PowerShell.  This file is the harness - the exercise is to find the
  cause with the tools in the guide, not by reading this script.
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'help')

. (Join-Path (Split-Path -Parent $PSScriptRoot) 'common\lab-common.ps1')

$LabDir   = $PSScriptRoot
$AppDir   = Join-Path $LabDir 'OrdersApi'
$Daemon   = Join-Path $LabDir 'legacy-sync-daemon.ps1'
$StateF   = Join-Path (Get-StateDir) 'D1-1.json'
$VarName  = 'Kestrel__Endpoints__Http__Url'
$BadValue = 'http://localhost:5055'
$Evidence = Join-Path $LabDir 'evidence\evidence_D1_1.json'

function Invoke-Reset {
    param([switch]$Quiet)
    Assert-Admin
    # legacy daemon (found by command line so reset works even if the state file is gone)
    Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -and $_.CommandLine -match 'legacy-sync-daemon\.ps1' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    # any OrdersApi still running from this lab
    Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^(OrdersApi|dotnet)\.exe$' -and $_.CommandLine -match 'OrdersApi' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    # the override at every scope
    foreach ($scope in 'Machine', 'User') { [Environment]::SetEnvironmentVariable($VarName, $null, $scope) }
    Remove-Item "Env:$VarName" -ErrorAction SilentlyContinue
    Remove-Item $StateF -ErrorAction SilentlyContinue
    if (-not $Quiet) { Write-Host "D1-1 reset complete. (Open shells keep stale env vars - close them or Remove-Item Env:$VarName.)" -ForegroundColor Green }
}

function Invoke-Start {
    Assert-Admin
    Write-Step 'Preparing NET-D1-101 ...'
    Invoke-Reset -Quiet

    if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) { Write-Host 'dotnet not found - run the setup script first.' -ForegroundColor Red; exit 2 }

    # 1. the legacy integration daemon that owns port 5055
    $hostExe = (Get-Process -Id $PID).Path
    Start-Process -FilePath $hostExe -WindowStyle Hidden `
        -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$Daemon`"", '-Port', '5055') | Out-Null
    if (-not (Wait-Until { (Get-ListenerPid 5055) -gt 0 } 15)) { Write-Host 'Legacy daemon failed to start.' -ForegroundColor Red; exit 2 }
    $daemonPid = Get-ListenerPid 5055

    # 2. the "hidden" machine-level override left behind by an earlier project
    [Environment]::SetEnvironmentVariable($VarName, $BadValue, 'Machine')

    # 3. build once so `dotnet run --no-build` is quick
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
    Write-Host "  1. Open a NEW elevated PowerShell, or refresh this one:  . C:\Labs\common\Refresh-Env.ps1"
    Write-Host "     (a shell that was already open does not see Machine-scope changes - that is part of the lesson)"
    Write-Host "  2. cd $AppDir ; dotnet run --no-build"
    Write-Host "  3. Follow 02_Participant_Guide.md, section D1-1."
}

function Invoke-Check {
    if (-not (Test-Path $StateF)) { Write-Host 'Lab not started. Run: .\lab.ps1 start' -ForegroundColor Yellow; exit 3 }
    $st = Get-Content $StateF -Raw | ConvertFrom-Json

    # 1. legacy daemon untouched
    $d = Get-ListenerPid 5055
    Add-Check 'Legacy daemon still serves port 5055 with the SAME PID (it was not killed)' ($d -eq [int]$st.daemonPid) "expected PID $($st.daemonPid), found $d"

    # 2. OrdersApi on 5060
    $o = Get-ListenerPid 5060
    Add-Check 'OrdersApi is listening on port 5060' ($o -gt 0) 'Start the API (dotnet run --no-build) and leave it running in another window while you run check.'
    if ($o -gt 0) {
        $pname = (Get-Process -Id $o -ErrorAction SilentlyContinue).ProcessName
        Add-Check 'The listener on 5060 is OrdersApi (not something else)' ($pname -match 'OrdersApi|dotnet') "listener is '$pname'"
    }
    $code = Get-HttpStatus 'http://localhost:5060/health'
    Add-Check 'GET /health on 5060 returns 200' ($code -eq 200) "got HTTP $code"
    Add-Check '/health body reports Healthy' ((Get-HttpBody 'http://localhost:5060/health') -match 'Healthy')

    # 3. permanent fix vs workaround (informational)
    $mv = [Environment]::GetEnvironmentVariable($VarName, 'Machine')
    Add-Check 'Machine-scope override removed (permanent fix)' (-not $mv) "Machine variable $VarName is still '$mv'. A launch-time override works today but breaks the next deploy." -Warn

    # 4. evidence file
    $ok = $false; $why = "missing file $Evidence"
    if (Test-Path $Evidence) {
        try {
            $j = Get-Content $Evidence -Raw | ConvertFrom-Json
            $miss = @()
            if (-not $j.startupLogLine -or $j.startupLogLine -notmatch 'Now listening on' -or $j.startupLogLine -notmatch '5060') { $miss += 'startupLogLine' }
            if (-not $j.healthResponse -or [int]$j.healthResponse.statusCode -ne 200) { $miss += 'healthResponse.statusCode' }
            foreach ($k in 'sdkVersion', 'runtimeVersion', 'frameworkDescription', 'os') { if (-not $j.runtime.$k) { $miss += "runtime.$k" } }
            if ($j.runtime.deploymentModel -notmatch '^(framework-dependent|self-contained)$') { $miss += 'runtime.deploymentModel (must be exactly framework-dependent or self-contained)' }
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
    default { Write-Host 'Usage: .\lab.ps1 start | check | reset' }
}
