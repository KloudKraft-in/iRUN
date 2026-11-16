<#
.SYNOPSIS
  Validation & Harness Script for TEL-D6-601 - "Metric Anomaly to Root Cause in One Platform" (Windows)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    initialize incident (inject fault / start scenario)
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    restore baseline state
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'check')

$LabDir   = $PSScriptRoot
$Starter  = Join-Path $LabDir 'starter'
$Evidence = Join-Path $Starter 'evidence\evidence_D6_1.md'

function Invoke-Reset {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Resetting Scenario TEL-D6-601..." -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "Baseline state restored."
}

function Invoke-Start {
    Invoke-Reset
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host " Initializing Incident: TEL-D6-601" -ForegroundColor Yellow
    Write-Host " Metric Anomaly to Root Cause in One Platform" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host "Observed Failure: At 09:12 UTC, checkout conversion drops by 35%. Engineers must correlate metric anomaly to application logs and distributed traces without tool switching."
    Write-Host ""
    Write-Host "Your Mission: Follow guidelines in starter\README_START_HERE.txt"
    Write-Host "Fill evidence template in: starter\evidence\evidence_D6_1.md"
    Write-Host "Then validate with: .\validation_script.ps1 check"
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating Solution for TEL-D6-601" -ForegroundColor Cyan
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
    # Check 1: Anomaly timestamp identified
    if ($content -and $content.IndexOf('09:12', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 1: Anomaly timestamp identified" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 1: Anomaly timestamp identified (missing pattern: 09:12)" -ForegroundColor Red
    }
    # Check 2: Target service identified
    if ($content -and $content.IndexOf('checkout-api', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 2: Target service identified" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 2: Target service identified (missing pattern: checkout-api)" -ForegroundColor Red
    }
    # Check 3: Correlated Trace ID extracted
    if ($content -and $content.IndexOf('6a71e29f8c12', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 3: Correlated Trace ID extracted" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 3: Correlated Trace ID extracted (missing pattern: 6a71e29f8c12)" -ForegroundColor Red
    }
    # Check 4: Tempo trace tool referenced
    if ($content -and $content.IndexOf('Tempo', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 4: Tempo trace tool referenced" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 4: Tempo trace tool referenced (missing pattern: Tempo)" -ForegroundColor Red
    }
    # Check 5: Loki log error filter applied
    if ($content -and $content.IndexOf('status="ERROR"', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 5: Loki log error filter applied" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 5: Loki log error filter applied (missing pattern: status="ERROR")" -ForegroundColor Red
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
