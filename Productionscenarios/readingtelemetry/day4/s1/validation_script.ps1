<#
.SYNOPSIS
  Validation & Harness Script for TEL-D4-401 - "Slow-Transaction Report for the Ops Review" (Windows)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    initialize incident (inject fault / start scenario)
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    restore baseline state
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'check')

$LabDir   = $PSScriptRoot
$Starter  = Join-Path $LabDir 'starter'
$Evidence = Join-Path $Starter 'evidence\evidence_D4_1.md'

function Invoke-Reset {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Resetting Scenario TEL-D4-401..." -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "Baseline state restored."
}

function Invoke-Start {
    Invoke-Reset
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host " Initializing Incident: TEL-D4-401" -ForegroundColor Yellow
    Write-Host " Slow-Transaction Report for the Ops Review" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host "Observed Failure: Operations review requires a p95 transaction latency ranking for ShopNow-Production. Default APM overviews do not isolate top-5 slowest transactions."
    Write-Host ""
    Write-Host "Your Mission: Follow guidelines in starter\README_START_HERE.txt"
    Write-Host "Fill evidence template in: starter\evidence\evidence_D4_1.md"
    Write-Host "Then validate with: .\validation_script.ps1 check"
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating Solution for TEL-D4-401" -ForegroundColor Cyan
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
    # Check 1: NRQL percentile function used
    if ($content -and $content.IndexOf('percentile(duration, 95)', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 1: NRQL percentile function used" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 1: NRQL percentile function used (missing pattern: percentile(duration, 95))" -ForegroundColor Red
    }
    # Check 2: Target appName filtered
    if ($content -and $content.IndexOf('ShopNow-Production', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 2: Target appName filtered" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 2: Target appName filtered (missing pattern: ShopNow-Production)" -ForegroundColor Red
    }
    # Check 3: Facet grouping by transaction name
    if ($content -and $content.IndexOf('FACET name', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 3: Facet grouping by transaction name" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 3: Facet grouping by transaction name (missing pattern: FACET name)" -ForegroundColor Red
    }
    # Check 4: Top 5 limit applied
    if ($content -and $content.IndexOf('LIMIT 5', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 4: Top 5 limit applied" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 4: Top 5 limit applied (missing pattern: LIMIT 5)" -ForegroundColor Red
    }
    # Check 5: Slowest transaction identified
    if ($content -and $content.IndexOf('processPayment', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 5: Slowest transaction identified" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 5: Slowest transaction identified (missing pattern: processPayment)" -ForegroundColor Red
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
