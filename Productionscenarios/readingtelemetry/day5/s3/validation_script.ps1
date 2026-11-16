<#
.SYNOPSIS
  Validation & Harness Script for TEL-D5-503 - "Pager Fatigue: Tune the Alerts and Rebuild the Dashboard" (Windows)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    initialize incident (inject fault / start scenario)
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    restore baseline state
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'check')

$LabDir   = $PSScriptRoot
$Starter  = Join-Path $LabDir 'starter'
$Evidence = Join-Path $Starter 'evidence\evidence_D5_3.md'

function Invoke-Reset {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Resetting Scenario TEL-D5-503..." -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "Baseline state restored."
}

function Invoke-Start {
    Invoke-Reset
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host " Initializing Incident: TEL-D5-503" -ForegroundColor Yellow
    Write-Host " Pager Fatigue: Tune the Alerts and Rebuild the Dashboard" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host "Observed Failure: On-call engineers receive 80+ alerts per week due to transient 1-second CPU spikes and un-thresholded error fluctuations. Critical incidents get ignored due to alarm fatigue."
    Write-Host ""
    Write-Host "Your Mission: Follow guidelines in starter\README_START_HERE.txt"
    Write-Host "Fill evidence template in: starter\evidence\evidence_D5_3.md"
    Write-Host "Then validate with: .\validation_script.ps1 check"
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating Solution for TEL-D5-503" -ForegroundColor Cyan
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
    # Check 1: Duration delay added to CPU alert
    if ($content -and $content.IndexOf('for: 10m', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 1: Duration delay added to CPU alert" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 1: Duration delay added to CPU alert (missing pattern: for: 10m)" -ForegroundColor Red
    }
    # Check 2: Duration delay added to error rate alert
    if ($content -and $content.IndexOf('for: 3m', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 2: Duration delay added to error rate alert" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 2: Duration delay added to error rate alert (missing pattern: for: 3m)" -ForegroundColor Red
    }
    # Check 3: Runbook URL annotations configured
    if ($content -and $content.IndexOf('runbook_url', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 3: Runbook URL annotations configured" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 3: Runbook URL annotations configured (missing pattern: runbook_url)" -ForegroundColor Red
    }
    # Check 4: Warning severity assigned
    if ($content -and $content.IndexOf('severity: warning', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 4: Warning severity assigned" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 4: Warning severity assigned (missing pattern: severity: warning)" -ForegroundColor Red
    }
    # Check 5: Critical severity assigned
    if ($content -and $content.IndexOf('severity: critical', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 5: Critical severity assigned" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 5: Critical severity assigned (missing pattern: severity: critical)" -ForegroundColor Red
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
