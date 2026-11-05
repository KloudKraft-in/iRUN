<#
.SYNOPSIS
  Validation & Harness Script for NET-D1-103 - "Staging Invoice-Sync Service" (Windows Service)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    publish + register Windows Service with wrong environment variable
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    remove service, files and logs
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

function Get-BackupDir {
    param([string]$Sub = '')
    $dir = Join-Path (Get-StateDir) "backup\$Sub"
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

$global:Checks = @()
function Add-Check {
    param([string]$Title, [bool]$Passed, [string]$Details = '', [switch]$Warn)
    $status = if ($Passed) { 'PASS' } elseif ($Warn) { 'WARN' } else { 'FAIL' }
    $global:Checks += [pscustomobject]@{ Title = $Title; Passed = $Passed; Status = $status; Details = $Details }
    $color = if ($Passed) { 'Green' } elseif ($Warn) { 'Yellow' } else { 'Red' }
    Write-Host "  [$status] $Title" -ForegroundColor $color
    if (-not $Passed -and $Details) { Write-Host "         $Details" -ForegroundColor Yellow }
}

function Test-Filled {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $false }
    $content = Get-Content $Path -Raw
    return ($content.Length -gt 0 -and $content -notmatch '<<FILL')
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
$Src     = Join-Path $Starter 'InvoiceSync'
$SvcDir  = Join-Path $Starter 'service'
$LogDir  = Join-Path $Starter 'Logs'
$LogFile = Join-Path $LogDir 'invoice_sync.log'
$SvcName = 'InvoiceSyncService'
$RegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$SvcName"
$Evid    = Join-Path $Starter 'evidence\evidence_D1_3.md'
$StateF  = Join-Path (Get-StateDir) 'D1-3.json'

function Invoke-Reset {
    param([switch]$Quiet)
    Assert-Admin
    $svc = Get-Service -Name $SvcName -ErrorAction SilentlyContinue
    if ($svc) {
        if ($svc.Status -ne 'Stopped') { Stop-Service -Name $SvcName -Force -ErrorAction SilentlyContinue }
        & sc.exe delete $SvcName | Out-Null
        Start-Sleep -Seconds 1
    }
    Get-Process -Name 'InvoiceSync' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    foreach ($p in @($SvcDir, $LogDir)) { if (Test-Path $p) { Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue } }
    Remove-Item $StateF -ErrorAction SilentlyContinue
    if (-not $Quiet) { Write-Host 'D1-3 reset complete (service, binaries and logs removed).' -ForegroundColor Green }
}

function Invoke-Start {
    Assert-Admin
    Write-Step 'Preparing NET-D1-103 ...'
    Invoke-Reset -Quiet
    if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) { Write-Host 'dotnet not found - install .NET SDK first.' -ForegroundColor Red; exit 2 }

    Write-Step 'Publishing InvoiceSync ...'
    & dotnet publish $Src -c Release -o $SvcDir --nologo -v q | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host 'dotnet publish failed' -ForegroundColor Red; exit 2 }
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

    Write-Step 'Registering the Windows Service ...'
    New-Service -Name $SvcName -BinaryPathName (Join-Path $SvcDir 'InvoiceSync.exe') `
        -DisplayName 'Invoice Sync Service (Staging)' -StartupType Manual | Out-Null
    New-ItemProperty -Path $RegPath -Name Environment -PropertyType MultiString -Value @('ASPNETCORE_ENVIRONMENT=Staging') -Force | Out-Null
    & reg.exe export "HKLM\SYSTEM\CurrentControlSet\Services\$SvcName" (Join-Path (Get-BackupDir 'Day1') 'InvoiceSyncService.faulty.reg') /y | Out-Null

    @{ startedUtc = (Get-Date).ToUniversalTime().ToString('o') } | ConvertTo-Json | Set-Content $StateF

    Write-Step 'Starting the service (this is expected to fail) ...'
    try { Start-Service -Name $SvcName -ErrorAction Stop } catch { Write-Info ("Start-Service said: " + $_.Exception.Message) }
    Start-Sleep -Seconds 3

    Write-Host ""
    Write-Host "TICKET NET-D1-103  [P3: before go-live, no live impact]" -ForegroundColor Yellow
    Write-Host "  The deployment script set ASPNETCORE_ENVIRONMENT=Staging on the InvoiceSyncService definition."
    Write-Host "  The service still stops within seconds of starting (Service Control Manager: terminated unexpectedly)."
    Write-Host ""
    Write-Host "NEXT: Get-Service $SvcName then follow Participant_Guide_day1.md Ticket 3." -ForegroundColor Cyan
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating NET-D1-103: Staging Generic Host Config" -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan

    $svc = Get-Service -Name $SvcName -ErrorAction SilentlyContinue
    Add-Check 'Service InvoiceSyncService is Running' ($svc -and $svc.Status -eq 'Running') "status: $(if ($svc) { $svc.Status } else { 'service missing' })"
    Start-Sleep -Seconds 4
    $svc = Get-Service -Name $SvcName -ErrorAction SilentlyContinue
    Add-Check 'It is still Running 4 seconds later (not crash-looping)' ($svc -and $svc.Status -eq 'Running')

    $envVals = @()
    try { $envVals = @((Get-ItemProperty -Path $RegPath -Name Environment -ErrorAction Stop).Environment) } catch { }
    Add-Check 'Service environment contains DOTNET_ENVIRONMENT=Staging' ($envVals -contains 'DOTNET_ENVIRONMENT=Staging') ("Environment value is: " + ($envVals -join '; '))

    $fresh = $false; $last = ''
    if (Test-Path $LogFile) {
        $last = (Get-Content $LogFile -Tail 1)
        $fresh = ($last -match 'Environment: Staging') -and (((Get-Date) - (Get-Item $LogFile).LastWriteTime).TotalSeconds -lt 120)
    }
    Add-Check 'invoice_sync.log shows a recent "Environment: Staging" heartbeat' $fresh "last log line: $last"

    $hist = $false
    try {
        $ev = Get-WinEvent -FilterHashtable @{ LogName = 'Application'; ProviderName = $SvcName } -MaxEvents 30 -ErrorAction Stop
        $hist = [bool]($ev | Where-Object { $_.Message -match 'OptionsValidationException' })
    } catch { }
    Add-Check 'Application log recorded original OptionsValidationException' $hist 'not found in recent log' -Warn

    Add-Check 'Evidence: evidence_D1_3.md completed (no <<FILL left)' (Test-Filled $Evid)

    Complete-Checks 'NET-D1-103'
}

switch ($Action) {
    'start' { Invoke-Start }
    'check' { Invoke-Check }
    'reset' { Invoke-Reset }
    default { Invoke-Check }
}
