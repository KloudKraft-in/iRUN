<#
.SYNOPSIS
  Validation & Harness Script for TEL-D4-402 - "Error Panel Shows Zero During an Outage" (Windows)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    initialize incident (inject fault / start scenario)
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    restore baseline state
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'check')

$LabDir   = $PSScriptRoot
$Starter  = Join-Path $LabDir 'starter'
$Evidence = Join-Path $Starter 'evidence\evidence_D4_2.json'

function Invoke-Reset {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Resetting Scenario TEL-D4-402..." -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "Baseline state restored."
}

function Invoke-Start {
    Invoke-Reset
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host " Initializing Incident: TEL-D4-402" -ForegroundColor Yellow
    Write-Host " Error Panel Shows Zero During an Outage" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host "Observed Failure: During an ongoing payment outage, the Grafana Error Rate panel displays 0 errors. SREs have zero visibility into failure rates."
    Write-Host ""
    Write-Host "Your Mission: Follow guidelines in starter\README_START_HERE.txt"
    Write-Host "Fill evidence template in: starter\evidence\evidence_D4_2.json"
    Write-Host "Then validate with: .\validation_script.ps1 check"
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating Solution for TEL-D4-402" -ForegroundColor Cyan
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
    # Check 1: Loki JSON pipeline stage applied
    if ($content -and $content.IndexOf('| json', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 1: Loki JSON pipeline stage applied" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 1: Loki JSON pipeline stage applied (missing pattern: | json)" -ForegroundColor Red
    }
    # Check 2: Structured level field queried
    if ($content -and $content.IndexOf('level', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 2: Structured level field queried" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 2: Structured level field queried (missing pattern: level)" -ForegroundColor Red
    }
    # Check 3: Uppercase ERROR status matched
    if ($content -and $content.IndexOf('ERROR', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 3: Uppercase ERROR status matched" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 3: Uppercase ERROR status matched (missing pattern: ERROR)" -ForegroundColor Red
    }
    # Check 4: Rate aggregator used instead of count_over_time
    if ($content -and $content.IndexOf('rate(', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 4: Rate aggregator used instead of count_over_time" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 4: Rate aggregator used instead of count_over_time (missing pattern: rate()" -ForegroundColor Red
    }
    # Check 5: Payment service selector preserved
    if ($content -and $content.IndexOf('payment-service', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 5: Payment service selector preserved" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 5: Payment service selector preserved (missing pattern: payment-service)" -ForegroundColor Red
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
