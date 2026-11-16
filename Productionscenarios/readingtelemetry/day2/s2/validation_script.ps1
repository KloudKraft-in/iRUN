<#
.SYNOPSIS
  Validation & Harness Script for TEL-D2-202 - "Datadog Monitor Fires: Confirm It in Splunk" (Windows)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    initialize incident (inject fault / start scenario)
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    restore baseline state
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'check')

$LabDir   = $PSScriptRoot
$Starter  = Join-Path $LabDir 'starter'
$Evidence = Join-Path $Starter 'evidence\evidence_D2_2.md'

function Invoke-Reset {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Resetting Scenario TEL-D2-202..." -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "Baseline state restored."
}

function Invoke-Start {
    Invoke-Reset
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host " Initializing Incident: TEL-D2-202" -ForegroundColor Yellow
    Write-Host " Datadog Monitor Fires: Confirm It in Splunk" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host "Observed Failure: Datadog composite monitor triggers alert: CPU > 80% on prod-worker-02 AND Error Rate > 5%. Raw log evidence must be extracted from Splunk to confirm transaction failure."
    Write-Host ""
    Write-Host "Your Mission: Follow guidelines in starter\README_START_HERE.txt"
    Write-Host "Fill evidence template in: starter\evidence\evidence_D2_2.md"
    Write-Host "Then validate with: .\validation_script.ps1 check"
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating Solution for TEL-D2-202" -ForegroundColor Cyan
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
    # Check 1: Transaction correlation ID verified
    if ($content -and $content.IndexOf('TXN-88129-CORR', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 1: Transaction correlation ID verified" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 1: Transaction correlation ID verified (missing pattern: TXN-88129-CORR)" -ForegroundColor Red
    }
    # Check 2: Correct Splunk index targeted
    if ($content -and $content.IndexOf('index=retail_prod', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 2: Correct Splunk index targeted" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 2: Correct Splunk index targeted (missing pattern: index=retail_prod)" -ForegroundColor Red
    }
    # Check 3: Correct worker host identified
    if ($content -and $content.IndexOf('prod-worker-02', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 3: Correct worker host identified" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 3: Correct worker host identified (missing pattern: prod-worker-02)" -ForegroundColor Red
    }
    # Check 4: Splunk sourcetype specified
    if ($content -and $content.IndexOf('sourcetype=', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 4: Splunk sourcetype specified" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 4: Splunk sourcetype specified (missing pattern: sourcetype=)" -ForegroundColor Red
    }
    # Check 5: Correct sourcetype formatted
    if ($content -and $content.IndexOf('checkout:json', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 5: Correct sourcetype formatted" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 5: Correct sourcetype formatted (missing pattern: checkout:json)" -ForegroundColor Red
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
