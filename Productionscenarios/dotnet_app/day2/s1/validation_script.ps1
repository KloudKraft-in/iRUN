<#
.SYNOPSIS
  Validation & Harness Script for NET-D2-201 - "Website Returns 503" (Windows / IIS)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    build IIS site + pool and trigger password rotation fault
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    remove site, pool, certificate, account and files
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

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Gray
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
    param([string]$Uri, [int]$TimeoutSec = 5, [switch]$Insecure)
    try {
        if ($Insecure) {
            $prev = [System.Net.ServicePointManager]::ServerCertificateValidationCallback
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
        }
        $res = Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec $TimeoutSec -ErrorAction Stop
        return [int]$res.StatusCode
    } catch {
        if ($_.Exception.Response) { return [int]$_.Exception.Response.StatusCode }
        return 0
    } finally {
        if ($Insecure) { [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $prev }
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
$SiteDir  = 'C:\inetpub\wwwroot\RetailPortal'
$PoolName = 'RetailPortalPool'
$SiteName = 'RetailPortal'
$SvcUser  = 'AppPoolSvc'
$CertName = 'RetailPortal Lab'
$Evid     = Join-Path $Starter 'evidence'
$StateF   = Join-Path (Get-StateDir) 'D2-1.json'

function New-LabPassword { return ('Lab#' + [guid]::NewGuid().ToString('N').Substring(0, 12) + 'aA1!') }

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
    Get-ChildItem Cert:\LocalMachine\My -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -eq $CertName } | Remove-Item -Force -ErrorAction SilentlyContinue
    if (Get-LocalUser -Name $SvcUser -ErrorAction SilentlyContinue) { Remove-LocalUser -Name $SvcUser }
    Start-Sleep -Milliseconds 700
    if (Test-Path $SiteDir) {
        & icacls $SiteDir /reset /T /Q 2>$null | Out-Null
        Remove-Item $SiteDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    Remove-Item $StateF -ErrorAction SilentlyContinue
    if (-not $Quiet) { Write-Host 'D2-1 reset complete (site, pool, certificate, AppPoolSvc and files removed).' -ForegroundColor Green }
}

function Invoke-Start {
    Assert-Admin
    Write-Step 'Preparing NET-D2-201 ...'
    Import-Module WebAdministration -ErrorAction Stop
    Invoke-Reset -Quiet

    Write-Step 'Creating the site content with a locked-down ACL ...'
    New-Item -ItemType Directory -Path $SiteDir -Force | Out-Null
    Copy-Item (Join-Path $Starter 'site-content\*') $SiteDir -Recurse -Force

    Write-Step "Creating local service account '$SvcUser' ..."
    $pw1 = New-LabPassword
    New-LocalUser -Name $SvcUser -Password (ConvertTo-SecureString $pw1 -AsPlainText -Force) -PasswordNeverExpires `
        -UserMayNotChangePassword -Description 'Lab service account for RetailPortalPool' | Out-Null
    Add-LocalGroupMember -Group 'IIS_IUSRS' -Member $SvcUser

    & icacls $SiteDir /inheritance:r | Out-Null
    & icacls $SiteDir /grant 'SYSTEM:(OI)(CI)F' 'Administrators:(OI)(CI)F' "$($SvcUser):(OI)(CI)RX" 'IUSR:(OI)(CI)RX' /T /Q | Out-Null

    Write-Step 'Creating certificate, application pool and site (HTTP 8080 + HTTPS 8443) ...'
    $cert = New-SelfSignedCertificate -DnsName 'localhost' -CertStoreLocation 'Cert:\LocalMachine\My' -FriendlyName $CertName -NotAfter (Get-Date).AddYears(1)
    New-WebAppPool -Name $PoolName | Out-Null
    Set-ItemProperty "IIS:\AppPools\$PoolName" -Name managedRuntimeVersion -Value ''
    Set-ItemProperty "IIS:\AppPools\$PoolName" -Name processModel -Value @{ userName = $SvcUser; password = $pw1; identityType = 3 }
    New-Website -Name $SiteName -Port 8080 -PhysicalPath $SiteDir -ApplicationPool $PoolName -Force | Out-Null
    New-WebBinding -Name $SiteName -Protocol https -Port 8443 | Out-Null
    (Get-WebBinding -Name $SiteName -Protocol https).AddSslCertificate($cert.Thumbprint, 'My')

    Write-Step 'Baseline check: the site must work BEFORE the rotation ...'
    $up = Wait-Until { (Get-HttpStatus 'http://localhost:8080/' -TimeoutSec 20) -eq 200 } 40
    if (-not $up) { Write-Host 'Baseline site did not come up - check IIS configuration.' -ForegroundColor Red; exit 2 }
    Write-Info 'HTTP 8080 = 200 (healthy baseline)'

    Write-Step 'Identity & Security Ops "rotates" service-account password (without updating IIS) ...'
    Set-LocalUser -Name $SvcUser -Password (ConvertTo-SecureString (New-LabPassword) -AsPlainText -Force)
    Stop-WebAppPool -Name $PoolName
    Wait-Until { (Get-WebAppPoolState -Name $PoolName).Value -eq 'Stopped' } 25 | Out-Null
    Start-WebAppPool -Name $PoolName
    1..2 | ForEach-Object { try { Invoke-WebRequest -Uri 'http://localhost:8080/' -UseBasicParsing -TimeoutSec 20 | Out-Null } catch { }; Start-Sleep -Seconds 1 }

    @{ startedUtc = (Get-Date).ToUniversalTime().ToString('o') } | ConvertTo-Json | Set-Content $StateF

    Write-Host ""
    Write-Host "TICKET NET-D2-201  [P2: site is completely down]" -ForegroundColor Yellow
    Write-Host "  After scheduled password rotation, the website returns 'HTTP Error 503. The service is unavailable'."
    Write-Host ""
    Write-Host "NEXT: curl.exe -i http://localhost:8080/ then follow Participant_Guide_day2.md Ticket 1." -ForegroundColor Cyan
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating NET-D2-201: IIS 503 Identity Hardening " -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan

    Import-Module WebAdministration -ErrorAction SilentlyContinue

    $c1 = Get-HttpStatus 'http://localhost:8080/' -TimeoutSec 30
    $c2 = Get-HttpStatus 'https://localhost:8443/' -Insecure -TimeoutSec 30
    Add-Check 'HTTP  http://localhost:8080/  returns 200' ($c1 -eq 200) "got $c1"
    Add-Check 'HTTPS https://localhost:8443/ returns 200' ($c2 -eq 200) "got $c2"

    $state = (Get-WebAppPoolState -Name $PoolName -ErrorAction SilentlyContinue).Value
    Add-Check 'Application pool RetailPortalPool is Started' ($state -eq 'Started') "state: $state"

    $pool = Get-ItemProperty "IIS:\AppPools\$PoolName" -ErrorAction SilentlyContinue
    $idt  = "$($pool.processModel.identityType)"
    Add-Check 'Pool identity is ApplicationPoolIdentity (virtual account)' ($idt -match '^(ApplicationPoolIdentity|4)$') "identityType: $idt"

    $acl = (& icacls $SiteDir) -join "`n"
    Add-Check "icacls shows 'IIS AppPool\RetailPortalPool' on the site folder" ($acl -match 'IIS AppPool\\RetailPortalPool') 'grant it Read & Execute'

    $w3 = Get-CimInstance Win32_Process -Filter "Name='w3wp.exe'" | Where-Object { $_.CommandLine -match $PoolName } | Select-Object -First 1
    $owner = ''
    if ($w3) { try { $owner = (Get-Process -Id $w3.ProcessId -IncludeUserName).UserName } catch { } }
    Add-Check 'w3wp.exe for the pool runs as IIS APPPOOL\RetailPortalPool' ($owner -ieq 'IIS APPPOOL\RetailPortalPool') "owner: '$owner'"

    $rt = $null; $mx = $null; $iv = $null
    try { $rt = $pool.recycling.periodicRestart.time.TotalMinutes; $mx = $pool.failure.rapidFailProtectionMaxCrashes; $iv = $pool.failure.rapidFailProtectionInterval.TotalMinutes } catch { }
    Add-Check 'Recycling: regular time interval = 1440 minutes' ($rt -eq 1440) "value: $rt"
    Add-Check 'Rapid-Fail Protection: 5 failures within 5 minutes' (($mx -eq 5) -and ($iv -eq 5)) "maxCrashes=$mx interval(min)=$iv"

    Add-Check 'Evidence: was-events.txt mentions Event ID 5021' ((Test-Path (Join-Path $Evid 'was-events.txt')) -and ((Get-Content (Join-Path $Evid 'was-events.txt') -Raw) -match '5021'))
    Add-Check 'Evidence: acl.txt lists IIS AppPool\RetailPortalPool' ((Test-Path (Join-Path $Evid 'acl.txt')) -and ((Get-Content (Join-Path $Evid 'acl.txt') -Raw) -match 'RetailPortalPool'))
    $ps = Join-Path $Evid 'pool-state.txt'
    Add-Check 'Evidence: pool-state.txt shows Started and 200' ((Test-Path $ps) -and ((Get-Content $ps -Raw) -match 'Started') -and ((Get-Content $ps -Raw) -match '200'))

    Complete-Checks 'NET-D2-201'
}

switch ($Action) {
    'start' { Invoke-Start }
    'check' { Invoke-Check }
    'reset' { Invoke-Reset }
    default { Invoke-Check }
}
