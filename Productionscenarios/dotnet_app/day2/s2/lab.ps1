<#
.SYNOPSIS
  NET-D2-202 harness - "Release Passes Startup but Health Check Fails in Production"   (Windows)
.DESCRIPTION
  .\lab.ps1 start     restore the starting code, build, and run OrderService in PRODUCTION mode on :5000
  .\lab.ps1 restart   stop, rebuild YOUR changes, run again (use this after every code edit)
  .\lab.ps1 check     validate your fix, your publish folder and your evidence
  .\lab.ps1 reset     stop the app and restore the starting code (also removes .\OrderService\publish)
  No admin rights needed.
#>
param([Parameter(Position = 0)][ValidateSet('start', 'restart', 'check', 'reset', 'help')][string]$Action = 'help')

. (Join-Path (Split-Path -Parent $PSScriptRoot) 'common\lab-common.ps1')

$LabDir  = $PSScriptRoot
$AppDir  = Join-Path $LabDir 'OrderService'
$Base    = Join-Path $LabDir '_baseline'
$LogDir  = Join-Path $LabDir 'logs'
$Exe     = Join-Path $AppDir 'bin\Debug\net10.0\OrderService.exe'
$Evid    = Join-Path $LabDir 'evidence'
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
    if ($LASTEXITCODE -ne 0) { $out | ForEach-Object { Write-Host $_ }; Write-Host 'BUILD FAILED - fix the compile error and run: .\lab.ps1 restart' -ForegroundColor Red; exit 2 }
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
    if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) { Write-Host 'dotnet not found - run the setup script first.' -ForegroundColor Red; exit 2 }
    Stop-App; Restore-Baseline; Build-App; Start-App
    Write-Host ""
    Write-Host "TICKET NET-D2-202  [P3: staging / pre-release validation blocker]" -ForegroundColor Yellow
    Write-Host "  The release started cleanly and the pipeline reported success - but the load balancer marks the node unhealthy:"
    Write-Host "  /health/ready returns HTTP 500 and /api/orders throws InvalidOperationException."
    Write-Host "  Logs: $LogDir\app.out.log and app.err.log"
    Write-Host ""
    Write-Host "NEXT: curl.exe -i $Url/health/live ; curl.exe -i $Url/health/ready   then follow 02_Participant_Guide.md section D2-2." -ForegroundColor Cyan
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
    if (-not (Test-Path $StateF)) { Write-Host 'Lab not started. Run: .\lab.ps1 start' -ForegroundColor Yellow; exit 3 }

    Add-Check 'GET /health/live returns 200' ((Get-HttpStatus "$Url/health/live") -eq 200)
    $r = Get-HttpStatus "$Url/health/ready"
    Add-Check 'GET /health/ready returns 200 (DI graph is complete)' ($r -eq 200) "got HTTP $r - did you run .\lab.ps1 restart after editing Program.cs?"
    $o = Get-HttpStatus "$Url/api/orders"
    Add-Check 'GET /api/orders returns 200' ($o -eq 200) "got HTTP $o"

    $tmp = Join-Path $env:TEMP 'd2-2-small.json'
    [IO.File]::WriteAllText($tmp, '{"customerId":"C-9","subtotal":600}')
    $small = & curl.exe -s -o NUL -w '%{http_code}' -X POST -H 'Content-Type: application/json' --data-binary "@$tmp" "$Url/api/orders"
    Add-Check 'A normal (small) POST /api/orders still returns 200' ("$small" -eq '200') "got $small - the limit must not be set too low"

    $big = Join-Path $env:TEMP 'd2-2-big.json'
    [IO.File]::WriteAllText($big, '{"customerId":"C-9","subtotal":100,"notes":"' + ('A' * 2MB) + '"}')
    $code = & curl.exe -s -o NUL -w '%{http_code}' -X POST -H 'Content-Type: application/json' --data-binary "@$big" "$Url/api/orders"
    Add-Check 'A 2 MB POST /api/orders is rejected with 413 Payload Too Large' ("$code" -eq '413') "got $code - set Limits.MaxRequestBodySize = 1048576"
    Remove-Item $tmp, $big -ErrorAction SilentlyContinue

    $src = Get-Content (Join-Path $AppDir 'Program.cs') -Raw
    Add-Check 'Program.cs sets Protocols = Http1AndHttp2 on endpoint defaults' ($src -match 'Http1AndHttp2') 'ConfigureEndpointDefaults(listen => listen.Protocols = HttpProtocols.Http1AndHttp2)' -Warn

    $pub = Join-Path $AppDir 'publish'
    $exe = Join-Path $pub 'OrderService.exe'
    $sz = 0; if (Test-Path $exe) { $sz = (Get-Item $exe).Length }
    Add-Check 'publish\OrderService.exe exists and is large enough to be self-contained (> 20 MB)' ($sz -gt 20MB) "size: $([math]::Round($sz/1MB,1)) MB"
    Add-Check 'It is a single-file build (no separate OrderService.dll next to it)' ((Test-Path $exe) -and -not (Test-Path (Join-Path $pub 'OrderService.dll')))

    $dev = Join-Path $Evid 'dev-validation.txt'
    Add-Check 'Evidence: dev-validation.txt shows the startup validation error for IDiscountRule' ((Test-Path $dev) -and ((Get-Content $dev -Raw) -match 'IDiscountRule') -and ((Get-Content $dev -Raw) -match 'Error while validating|not able to be constructed'))
    Add-Check 'Evidence: program.diff is present and shows the registration' ((Test-Path (Join-Path $Evid 'program.diff')) -and ((Get-Content (Join-Path $Evid 'program.diff') -Raw) -match 'IDiscountRule'))
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
    default   { Write-Host 'Usage: .\lab.ps1 start | restart | check | reset' }
}
