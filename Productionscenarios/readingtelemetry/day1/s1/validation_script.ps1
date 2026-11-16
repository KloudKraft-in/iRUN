<#
.SYNOPSIS
  Validation & Harness Script for TEL-D1-101 - "Checkout Is Slow but the Dashboard Looks Green" (Windows)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    initialize incident (inject fault / start scenario)
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    restore baseline state
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'check')

$LabDir   = $PSScriptRoot
$Starter  = Join-Path $LabDir 'starter'
$Evidence = Join-Path $Starter 'evidence\evidence_D1_1.json'

function Invoke-Reset {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Resetting Scenario TEL-D1-101..." -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "Baseline state restored."
}

function Invoke-Start {
    Invoke-Reset
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host " Initializing Incident: TEL-D1-101" -ForegroundColor Yellow
    Write-Host " Checkout Is Slow but the Dashboard Looks Green" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host "Observed Failure: Grafana RED dashboard shows green status and average latency of ~185ms, while customers report 4.5s+ checkout timeouts. The panel query uses 'avg(payment_duration_seconds)' which flattens the bimodal distribution."
    Write-Host ""
    Write-Host "Your Mission: Follow guidelines in starter\README_START_HERE.txt"
    Write-Host "Fill evidence template in: starter\evidence\evidence_D1_1.json"
    Write-Host "Then validate with: .\validation_script.ps1 check"
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating Solution for TEL-D1-101" -ForegroundColor Cyan
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
    # Check 1: p95 histogram_quantile query present
    if ($content -and $content.IndexOf('histogram_quantile', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 1: p95 histogram_quantile query present" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 1: p95 histogram_quantile query present (missing pattern: histogram_quantile)" -ForegroundColor Red
    }
    # Check 2: Correct bucket metric targeted
    if ($content -and $content.IndexOf('payment_duration_seconds_bucket', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 2: Correct bucket metric targeted" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 2: Correct bucket metric targeted (missing pattern: payment_duration_seconds_bucket)" -ForegroundColor Red
    }
    # Check 3: Rate aggregation applied inside bucket sum
    if ($content -and $content.IndexOf('rate(', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 3: Rate aggregation applied inside bucket sum" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 3: Rate aggregation applied inside bucket sum (missing pattern: rate()" -ForegroundColor Red
    }
    # Check 4: HTTP requests metric queried for errors
    if ($content -and $content.IndexOf('http_requests_total', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 4: HTTP requests metric queried for errors" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 4: HTTP requests metric queried for errors (missing pattern: http_requests_total)" -ForegroundColor Red
    }
    # Check 5: Regex filter applied for 5xx errors
    if ($content -and $content.IndexOf('status=~', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 5: Regex filter applied for 5xx errors" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 5: Regex filter applied for 5xx errors (missing pattern: status=~)" -ForegroundColor Red
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
