<#
.SYNOPSIS
  Validation & Harness Script for NET-D2-202 - "Health Check Fails in Production" (Windows)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    restore starting code, build and run OrderService on :5000
  .\validation_script.ps1 restart  stop, rebuild your changes and run again
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    stop app and restore starting code
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
$LabDir  = $PSScriptRoot
$Starter = Join-Path $LabDir 'starter'
$AppDir  = Join-Path $Starter 'OrderService'
$Base    = Join-Path $Starter '_baseline'
$LogDir  = Join-Path $Starter 'logs'
$Exe     = Join-Path $AppDir 'bin\Debug\net10.0\OrderService.exe'
$Evid    = Join-Path $Starter 'evidence'
$StateF  = Join-Path (Get-StateDir) 'D2-2.json'
$Url     = 'http://localhost:5000'

function Stop-App {
    Get-Process -Name 'OrderService' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
}

function Restore-Baseline {
    Copy-Item (Join-Path $Base '*') $AppDir -Recurse -Force
    Remove-Item (Join-Path $AppDir 'publish') -Recurse -Force -ErrorAction SilentlyContinue
}

function Build-App {
    Write-Step 'dotnet build ...'
    $out = & dotnet build $AppDir -c Debug --nologo -v q 2>&1
    if ($LASTEXITCODE -ne 0) { $out | ForEach-Object { Write-Host $_ }; Write-Host 'BUILD FAILED - fix the compile error and run: .\validation_script.ps1 restart' -ForegroundColor Red; exit 2 }
}

function Start-App {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
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
    if (-not (Wait-Until { (Get-HttpStatus "$Url/health/live") -eq 200 } 30)) { Write-Host "App did not answer on $Url - see $LogDir\app.err.log" -ForegroundColor Red; exit 2 }
}

function Invoke-Start {
    Write-Step 'Preparing NET-D2-202 ...'
    if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) { Write-Host 'dotnet not found - install .NET SDK first.' -ForegroundColor Red; exit 2 }
    Stop-App; Restore-Baseline; Build-App; Start-App
    Write-Host ""
    Write-Host "TICKET NET-D2-202  [P3: staging / pre-release validation blocker]" -ForegroundColor Yellow
    Write-Host "  The release started cleanly - but /health/ready returns HTTP 500."
    Write-Host ""
    Write-Host "NEXT: curl.exe -i $Url/health/live ; curl.exe -i $Url/health/ready then follow Participant_Guide_day2.md Ticket 2." -ForegroundColor Cyan
}

function Invoke-Restart {
    Write-Step 'Restarting OrderService with your latest code ...'
    Stop-App; Build-App; Start-App
    Write-Host "Running again on $Url (Production mode)." -ForegroundColor Green
}

function Invoke-Reset {
    Stop-App
    Restore-Baseline
    Remove-Item (Join-Path $AppDir 'bin'), (Join-Path $AppDir 'obj'), $LogDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $StateF -ErrorAction SilentlyContinue
    Write-Host 'D2-2 reset complete (app stopped, starting code restored, publish folder removed).' -ForegroundColor Green
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating NET-D2-202: DI Scope & Kestrel Limits  " -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan

    Add-Check 'GET /health/live returns 200' ((Get-HttpStatus "$Url/health/live") -eq 200)
    $r = Get-HttpStatus "$Url/health/ready"
    Add-Check 'GET /health/ready returns 200 (DI graph complete)' ($r -eq 200) "got HTTP $r - did you run .\validation_script.ps1 restart?"
    $o = Get-HttpStatus "$Url/api/orders"
    Add-Check 'GET /api/orders returns 200' ($o -eq 200) "got HTTP $o"

    $tmp = Join-Path $env:TEMP 'd2-2-small.json'
    [IO.File]::WriteAllText($tmp, '{"customerId":"C-9","subtotal":600}')
    $small = & curl.exe -s -o NUL -w '%{http_code}' -X POST -H 'Content-Type: application/json' --data-binary "@$tmp" "$Url/api/orders"
    Add-Check 'A normal (small) POST /api/orders returns 200' ("$small" -eq '200') "got $small"

    $big = Join-Path $env:TEMP 'd2-2-big.json'
    [IO.File]::WriteAllText($big, '{"customerId":"C-9","subtotal":100,"notes":"' + ('A' * 2MB) + '"}')
    $code = & curl.exe -s -o NUL -w '%{http_code}' -X POST -H 'Content-Type: application/json' --data-binary "@$big" "$Url/api/orders"
    Add-Check 'A 2 MB POST /api/orders is rejected with 413 Payload Too Large' ("$code" -eq '413') "got $code - set Limits.MaxRequestBodySize = 1048576"
    Remove-Item $tmp, $big -ErrorAction SilentlyContinue

    $src = Get-Content (Join-Path $AppDir 'Program.cs') -Raw
    Add-Check 'Program.cs sets Protocols = Http1AndHttp2' ($src -match 'Http1AndHttp2') -Warn

    $pub = Join-Path $AppDir 'publish'
    $exe = Join-Path $pub 'OrderService.exe'
    $sz = 0; if (Test-Path $exe) { $sz = (Get-Item $exe).Length }
    Add-Check 'publish\OrderService.exe exists and is self-contained (> 20 MB)' ($sz -gt 20MB) "size: $([math]::Round($sz/1MB,1)) MB"

    $dev = Join-Path $Evid 'dev-validation.txt'
    Add-Check 'Evidence: dev-validation.txt shows startup validation error' ((Test-Path $dev) -and ((Get-Content $dev -Raw) -match 'IDiscountRule'))
    Add-Check 'Evidence: program.diff shows DI registration' ((Test-Path (Join-Path $Evid 'program.diff')) -and ((Get-Content (Join-Path $Evid 'program.diff') -Raw) -match 'IDiscountRule'))
    $req = Join-Path $Evid 'requests.txt'
    Add-Check 'Evidence: requests.txt shows 200 and 413' ((Test-Path $req) -and ((Get-Content $req -Raw) -match '200') -and ((Get-Content $req -Raw) -match '413'))
    Add-Check 'Evidence: publish-listing.txt present' ((Test-Path (Join-Path $Evid 'publish-listing.txt')) -and ((Get-Item (Join-Path $Evid 'publish-listing.txt')).Length -gt 20))

    Complete-Checks 'NET-D2-202'
}

switch ($Action) {
    'start'   { Invoke-Start }
    'restart' { Invoke-Restart }
    'check'   { Invoke-Check }
    'reset'   { Invoke-Reset }
    default   { Invoke-Check }
}
