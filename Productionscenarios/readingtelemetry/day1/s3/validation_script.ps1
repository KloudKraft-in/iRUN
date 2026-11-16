<#
.SYNOPSIS
  Validation & Harness Script for TEL-D1-103 - "Six Alerts at Shift Start, One Real Problem" (Windows)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    initialize incident (inject fault / start scenario)
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    restore baseline state
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'check')

$LabDir   = $PSScriptRoot
$Starter  = Join-Path $LabDir 'starter'
$Evidence = Join-Path $Starter 'evidence\evidence_D1_3.json'

function Invoke-Reset {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Resetting Scenario TEL-D1-103..." -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "Baseline state restored."
}

function Invoke-Start {
    Invoke-Reset
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host " Initializing Incident: TEL-D1-103" -ForegroundColor Yellow
    Write-Host " Six Alerts at Shift Start, One Real Problem" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host "Observed Failure: Six simultaneous alerts fire in Alertmanager (CheckoutSlow, PaymentTimeout, ProfileQueryDegraded, OrderHistory504, DiskIOWaitHigh, DatabaseQueueSaturation), creating cognitive overload."
    Write-Host ""
    Write-Host "Your Mission: Follow guidelines in starter\README_START_HERE.txt"
    Write-Host "Fill evidence template in: starter\evidence\evidence_D1_3.json"
    Write-Host "Then validate with: .\validation_script.ps1 check"
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating Solution for TEL-D1-103" -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    
    if (-not (Test-Path $Evidence)) {
        Write-Host " [ERROR] Evidence file not found: $Evidence" -ForegroundColor Red
        Write-Host " Total Score: 0/5 (0%)" -ForegroundColor Red
        return
    }
    
    $content = Get-Content -Raw -Path $Evidence -ErrorAction SilentlyContinue
    if ($content -match '<<FILL_') {
        Write-Host " [WARNING] Detected unfilled placeholder tokens (<<FILL_...>>) in evidence!" -ForegroundColor Yellow
    }
    
    $passed = 0
    $total  = 5
    # Check 1: Primary causal alert identified
    if ($content -and $content.IndexOf('DatabaseQueueSaturation', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 1: Primary causal alert identified" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 1: Primary causal alert identified (missing pattern: DatabaseQueueSaturation)" -ForegroundColor Red
    }
    # Check 2: Corroborating infrastructure alert recorded
    if ($content -and $content.IndexOf('DiskIOWaitHigh', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 2: Corroborating infrastructure alert recorded" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 2: Corroborating infrastructure alert recorded (missing pattern: DiskIOWaitHigh)" -ForegroundColor Red
    }
    # Check 3: Rogue query PID identified
    if ($content -and $content.IndexOf('9182', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 3: Rogue query PID identified" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 3: Rogue query PID identified (missing pattern: 9182)" -ForegroundColor Red
    }
    # Check 4: Target database resource identified
    if ($content -and $content.IndexOf('PostgreSQL', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 4: Target database resource identified" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 4: Target database resource identified (missing pattern: PostgreSQL)" -ForegroundColor Red
    }
    # Check 5: Remediation read replica routing proposed
    if ($content -and $content.IndexOf('replica', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 5: Remediation read replica routing proposed" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 5: Remediation read replica routing proposed (missing pattern: replica)" -ForegroundColor Red
    }
    $score = [math]::Round(($passed / $total) * 100)
    Write-Host "---------------------------------------------------"
    Write-Host " Test Summary: $passed / $total checks passed ($score%)" -ForegroundColor Cyan
    Write-Host "---------------------------------------------------"
    if ($passed -eq $total) {
        Write-Host " [SUCCESS] All validation checks passed successfully!" -ForegroundColor Green
    } else {
        Write-Host " [INCOMPLETE] Please address failed checks and re-run." -ForegroundColor Yellow
    }
}

switch ($Action) {
    'start' { Invoke-Start }
    'check' { Invoke-Check }
    'reset' { Invoke-Reset }
    default { Write-Host "Usage: .\validation_script.ps1 [start|check|reset]" }
}
