<#
.SYNOPSIS
  Validation & Harness Script for MIA-D2-201 - "RabbitMQ DLQ Flood" (Windows)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    initialize incident
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    restore baseline state
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'check')

$LabDir   = $PSScriptRoot
$Starter  = Join-Path $LabDir 'starter'
$DlqF     = Join-Path $Starter 'orders_dlq.json'
$QueueF   = Join-Path $Starter 'orders_queue.json'
$DbF      = Join-Path $Starter 'processed_orders.json'
$Evidence = Join-Path $Starter 'evidence\evidence_D2_1.json'

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
    Remove-Item $DbF -ErrorAction SilentlyContinue
    Remove-Item $QueueF -ErrorAction SilentlyContinue
    Remove-Item $DlqF -ErrorAction SilentlyContinue
    Write-Host "MIA-D2-201 reset complete." -ForegroundColor Green
}

function Invoke-Start {
    Invoke-Reset
    Write-Host "Staging Scenario MIA-D2-201: RabbitMQ DLQ Flood..." -ForegroundColor Cyan
    Push-Location $Starter
    try { python seed_day2_dlq.py } finally { Pop-Location }

    Write-Host "`nTICKET MIA-D2-201 [P2: Orders Stalled in DLQ]" -ForegroundColor Yellow
    Write-Host "  60 messages pre-populated into DLQ (50 valid orders, 10 poison pills)."
    Write-Host "NEXT: Inspect starter/orders_dlq.json and follow Participant_Guide_day2.md Ticket 1."
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating MIA-D2-201: Message Broker DLQ Recovery " -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan

    $pCount = 0
    $dCount = 0
    $qCount = -1

    if (Test-Path $DbF) { $pCount = (Get-Content $DbF | ConvertFrom-Json).Count }
    if (Test-Path $DlqF) { $dCount = (Get-Content $DlqF | ConvertFrom-Json).Count }
    if (Test-Path $QueueF) { $qCount = (Get-Content $QueueF | ConvertFrom-Json).Count }

    # Check 1: 50 processed orders
    Add-Check 'Exactly 50 legitimate customer orders processed into database' ($pCount -eq 50) "Processed count: $pCount (expected 50)"

    # Check 2: 10 quarantined poison pills
    Add-Check 'Exactly 10 malformed poison pills permanently quarantined in DLQ' ($dCount -eq 10) "DLQ count: $dCount (expected 10)"

    # Check 3: Primary queue drained
    Add-Check 'Primary orders.queue completely drained (0 pending)' ($qCount -eq 0) "Queue count: $qCount (expected 0)"

    # Check 4: Evidence
    $evidOk = $false
    if (Test-Path $Evidence) {
        $evText = Get-Content $Evidence -Raw
        $evidOk = (-not ($evText -match '<<FILL'))
    }
    Add-Check 'Incident evidence and root cause recorded in evidence_D2_1.json' $evidOk "evidence_D2_1.json contains unfilled <<FILL>> fields"

    Complete-Checks 'MIA-D2-201'
}

switch ($Action) {
    'start' { Invoke-Start }
    'reset' { Invoke-Reset }
    'check' { Invoke-Check }
    'help'  { Get-Help $MyInvocation.MyCommand.Path -Detailed }
    default { Invoke-Check }
}
