<#
.SYNOPSIS
  NET-D1-102 harness - "Site Shows 502.5 After Switching to Out-of-Process"   (Windows / IIS)
.DESCRIPTION
  .\lab.ps1 start   publish the portal to IIS and inject the faulty web.config
  .\lab.ps1 check   validate your fix and your evidence
  .\lab.ps1 reset   remove the IIS site / pool / files
  Run from an ELEVATED PowerShell.
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'help')

. (Join-Path (Split-Path -Parent $PSScriptRoot) 'common\lab-common.ps1')

$LabDir   = $PSScriptRoot
$Src      = Join-Path $LabDir 'CustomerPortal'
$SiteDir  = 'C:\inetpub\wwwroot\CustomerPortal'
$PoolName = 'RetailCustomerPortalPool'
$SiteName = 'RetailCustomerPortal'
$Evid     = Join-Path $LabDir 'evidence'
$StateF   = Join-Path (Get-StateDir) 'D1-2.json'

function Get-BrokenWebConfig {
@'
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <location path="." inheritInChildApplications="false">
    <system.webServer>
      <handlers>
        <add name="aspNetCore" path="*" verb="*" modules="AspNetCoreModuleV2" resourceType="Unspecified" />
      </handlers>
      <aspNetCore processPath="dotnet"
                  arguments=".\CustomerPortalMisspelled.dll"
                  stdoutLogEnabled="false"
                  stdoutLogFile=".\logs\stdout"
                  hostingModel="OutOfProcess" />
    </system.webServer>
  </location>
</configuration>
'@
}

function Invoke-Reset {
    param([switch]$Quiet)
    Assert-Admin
    Import-Module WebAdministration -ErrorAction SilentlyContinue
    if (Get-Command Get-Website -ErrorAction SilentlyContinue) {
        if (Get-Website -Name $SiteName -ErrorAction SilentlyContinue) { Remove-Website -Name $SiteName }
        if (Test-Path "IIS:\AppPools\$PoolName") {
            try { Stop-WebAppPool -Name $PoolName -ErrorAction SilentlyContinue } catch { }
            Remove-WebAppPool -Name $PoolName
        }
    }
    Start-Sleep -Milliseconds 700
    if (Test-Path $SiteDir) { Remove-Item $SiteDir -Recurse -Force -ErrorAction SilentlyContinue }
    Remove-Item $StateF -ErrorAction SilentlyContinue
    if (-not $Quiet) { Write-Host 'D1-2 reset complete (IIS site, pool and files removed).' -ForegroundColor Green }
}

function Invoke-Start {
    Assert-Admin
    Write-Step 'Preparing NET-D1-102 ...'
    Import-Module WebAdministration -ErrorAction Stop
    if (-not (Test-Path "$env:ProgramFiles\IIS\Asp.Net Core Module\V2\aspnetcorev2.dll")) {
        Write-Host 'ASP.NET Core Module v2 not found. Install the .NET 10 Hosting Bundle AFTER enabling IIS (see setup script).' -ForegroundColor Red; exit 2
    }
    Invoke-Reset -Quiet

    Write-Step 'Publishing CustomerPortal to IIS folder ...'
    & dotnet publish $Src -c Release -o $SiteDir --nologo -v q | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host 'dotnet publish failed' -ForegroundColor Red; exit 2 }
    New-Item -ItemType Directory -Path (Join-Path $SiteDir 'logs') -Force | Out-Null

    Write-Step 'Creating IIS application pool and site ...'
    New-WebAppPool -Name $PoolName | Out-Null
    Set-ItemProperty "IIS:\AppPools\$PoolName" -Name managedRuntimeVersion -Value ''     # "No Managed Code" - .NET (Core) is not CLR v4
    New-Website -Name $SiteName -Port 8080 -PhysicalPath $SiteDir -ApplicationPool $PoolName -Force | Out-Null

    # pool identity needs: read on the app, modify on logs (ANCM writes the stdout file as the pool identity)
    $acct = "IIS AppPool\$($PoolName)"
    & icacls $SiteDir /grant "$($acct):(OI)(CI)RX" /T /Q | Out-Null
    & icacls (Join-Path $SiteDir 'logs') /grant "$($acct):(OI)(CI)M" /Q | Out-Null

    # the regression: someone switched to Out-of-Process and broke the arguments
    Set-Content -Path (Join-Path $SiteDir 'web.config') -Value (Get-BrokenWebConfig) -Encoding UTF8
    Copy-Item (Join-Path $SiteDir 'web.config') (Join-Path (Get-BackupDir 'Day1') 'CustomerPortal.web.config.faulty') -Force

    @{ startedUtc = (Get-Date).ToUniversalTime().ToString('o') } | ConvertTo-Json | Set-Content $StateF

    # prime one failing request so the event log already contains the evidence
    try { Invoke-WebRequest -Uri 'http://localhost:8080/' -UseBasicParsing -TimeoutSec 20 | Out-Null } catch { }

    Write-Host ""
    Write-Host "TICKET NET-D1-102  [P2: customers see the outage]" -ForegroundColor Yellow
    Write-Host "  Retail Customer Portal was switched from In-Process to Out-of-Process hosting."
    Write-Host "  Every request now returns 'HTTP Error 502.5 - ANCM Out-Of-Process Startup Failure'."
    Write-Host "  iisreset did not help."
    Write-Host ""
    Write-Host "NEXT: http://localhost:8080/   then Event Viewer, then follow 02_Participant_Guide.md section D1-2." -ForegroundColor Cyan
}

function Invoke-Check {
    if (-not (Test-Path $StateF)) { Write-Host 'Lab not started. Run: .\lab.ps1 start' -ForegroundColor Yellow; exit 3 }
    Import-Module WebAdministration -ErrorAction SilentlyContinue

    $code = Get-HttpStatus 'http://localhost:8080/' -TimeoutSec 30
    Add-Check 'http://localhost:8080/ returns 200' ($code -eq 200) "got HTTP $code"

    $wc = Join-Path $SiteDir 'web.config'
    $hm = ''; $argv = ''
    try {
        [xml]$x = Get-Content $wc -Raw
        $node = $x.SelectSingleNode('//aspNetCore')
        $hm = $node.GetAttribute('hostingModel'); $argv = $node.GetAttribute('arguments')
    } catch { }
    Add-Check 'web.config keeps hostingModel="OutOfProcess" (you fixed the bug, you did not dodge it)' ($hm -ieq 'OutOfProcess') "hostingModel is '$hm'"
    $dll = Join-Path $SiteDir (($argv -replace '^\.\\', '') -replace '^\./', '')
    Add-Check 'web.config "arguments" points at a DLL that exists' ($argv -and (Test-Path $dll)) "arguments='$argv' -> $dll"

    $who = Get-HttpBody 'http://localhost:8080/whoami'
    Add-Check 'Requests are answered by dotnet.exe (Kestrel) - proof of Out-of-Process' ($who -match '"processName"\s*:\s*"dotnet"') ($who)

    $w3 = Get-CimInstance Win32_Process -Filter "Name='w3wp.exe'" | Where-Object { $_.CommandLine -match [regex]::Escape($PoolName) }
    $linked = $false
    foreach ($w in @($w3)) {
        if (Get-CimInstance Win32_Process -Filter "Name='dotnet.exe' AND ParentProcessId=$($w.ProcessId)") { $linked = $true }
    }
    Add-Check 'Process tree shows w3wp.exe -> dotnet.exe for this pool' $linked 'no dotnet.exe child of this pool''s w3wp.exe found'

    Add-Check 'Evidence: eventlog-export.txt present and non-empty' ((Test-Path (Join-Path $Evid 'eventlog-export.txt')) -and ((Get-Item (Join-Path $Evid 'eventlog-export.txt')).Length -gt 50))
    Add-Check 'Evidence: web.config copy present' (Test-Path (Join-Path $Evid 'web.config'))
    Add-Check 'Evidence: process-comparison.md completed (no <<FILL left)' (Test-Filled (Join-Path $Evid 'process-comparison.md'))

    Complete-Checks 'NET-D1-102'
}

switch ($Action) {
    'start' { Invoke-Start }
    'check' { Invoke-Check }
    'reset' { Invoke-Reset }
    default { Write-Host 'Usage: .\lab.ps1 start | check | reset' }
}
