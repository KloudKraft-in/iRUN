<#
.SYNOPSIS
  NET-D1-103 harness - "Staging Invoice-Sync Service Runs as 'Production' and Stops"   (Windows Service)
.DESCRIPTION
  .\lab.ps1 start   publish + register the Windows Service with a wrong environment variable
  .\lab.ps1 check   validate your fix and your evidence
  .\lab.ps1 reset   remove the service, files and logs
  Run from an ELEVATED PowerShell.
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'help')

. (Join-Path (Split-Path -Parent $PSScriptRoot) 'common\lab-common.ps1')

$LabDir  = $PSScriptRoot
$Src     = Join-Path $LabDir 'InvoiceSync'
$SvcDir  = Join-Path $LabDir 'service'
$LogDir  = Join-Path $LabDir 'Logs'
$LogFile = Join-Path $LogDir 'invoice_sync.log'
$SvcName = 'InvoiceSyncService'
$RegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$SvcName"
$Evid    = Join-Path $LabDir 'evidence\evidence_D1_3.md'
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
    if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) { Write-Host 'dotnet not found - run the setup script first.' -ForegroundColor Red; exit 2 }

    Write-Step 'Publishing InvoiceSync ...'
    & dotnet publish $Src -c Release -o $SvcDir --nologo -v q | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host 'dotnet publish failed' -ForegroundColor Red; exit 2 }
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

    Write-Step 'Registering the Windows Service ...'
    New-Service -Name $SvcName -BinaryPathName (Join-Path $SvcDir 'InvoiceSync.exe') `
        -DisplayName 'Invoice Sync Service (Staging)' -StartupType Manual | Out-Null
    # the deployment script's mistake: it set the ASP.NET Core variable name on a worker service
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
    Write-Host "NEXT: Get-Service $SvcName   then Event Viewer, then follow 02_Participant_Guide.md section D1-3." -ForegroundColor Cyan
}

function Invoke-Check {
    if (-not (Test-Path $StateF)) { Write-Host 'Lab not started. Run: .\lab.ps1 start' -ForegroundColor Yellow; exit 3 }

    $svc = Get-Service -Name $SvcName -ErrorAction SilentlyContinue
    Add-Check 'Service InvoiceSyncService is Running' ($svc -and $svc.Status -eq 'Running') "status: $(if ($svc) { $svc.Status } else { 'service missing' })"
    Start-Sleep -Seconds 4
    $svc = Get-Service -Name $SvcName -ErrorAction SilentlyContinue
    Add-Check 'It is still Running 4 seconds later (not crash-looping)' ($svc -and $svc.Status -eq 'Running')

    $envVals = @()
    try { $envVals = @((Get-ItemProperty -Path $RegPath -Name Environment -ErrorAction Stop).Environment) } catch { }
    Add-Check 'Service environment (registry) contains DOTNET_ENVIRONMENT=Staging' ($envVals -contains 'DOTNET_ENVIRONMENT=Staging') ("Environment value is: " + ($envVals -join '; '))

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
    Add-Check 'Application log still holds the original OptionsValidationException (you can quote it)' $hist 'not found - if you cleared the log, copy the entry from your notes' -Warn

    Add-Check 'evidence_D1_3.md completed (no <<FILL left)' (Test-Filled $Evid)

    Complete-Checks 'NET-D1-103'
}

switch ($Action) {
    'start' { Invoke-Start }
    'check' { Invoke-Check }
    'reset' { Invoke-Reset }
    default { Write-Host 'Usage: .\lab.ps1 start | check | reset' }
}
