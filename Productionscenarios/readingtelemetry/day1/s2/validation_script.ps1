<#
.SYNOPSIS
  Validation & Harness Script for TEL-D1-102 - "Orders Fail for One Product: Follow the Trace" (Windows)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    initialize incident (inject fault / start scenario)
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    restore baseline state
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'check')

$LabDir   = $PSScriptRoot
$Starter  = Join-Path $LabDir 'starter'
$Evidence = Join-Path $Starter 'evidence\evidence_D1_2.md'

function Invoke-Reset {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Resetting Scenario TEL-D1-102..." -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "Baseline state restored."
}

function Invoke-Start {
    Invoke-Reset
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host " Initializing Incident: TEL-D1-102" -ForegroundColor Yellow
    Write-Host " Orders Fail for One Product: Follow the Trace" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host "Observed Failure: Orders for promotional SKU 'PROD-7729' fail intermittently with generic 500 error screens. Aggregate service metrics report healthy throughput, masking isolated transaction failures."
    Write-Host ""
    Write-Host "Your Mission: Follow guidelines in starter\README_START_HERE.txt"
    Write-Host "Fill evidence template in: starter\evidence\evidence_D1_2.md"
    Write-Host "Then validate with: .\validation_script.ps1 check"
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating Solution for TEL-D1-102" -ForegroundColor Cyan
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
    # Check 1: Trace ID identified and recorded
    if ($content -and $content.IndexOf('4bf92f3577b34da6a3ce929d0e0e4736', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 1: Trace ID identified and recorded" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 1: Trace ID identified and recorded (missing pattern: 4bf92f3577b34da6a3ce929d0e0e4736)" -ForegroundColor Red
    }
    # Check 2: Failing span operation identified
    if ($content -and $content.IndexOf('inventory.reserveStock', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 2: Failing span operation identified" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 2: Failing span operation identified (missing pattern: inventory.reserveStock)" -ForegroundColor Red
    }
    # Check 3: Target promotional SKU identified
    if ($content -and $content.IndexOf('PROD-7729', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 3: Target promotional SKU identified" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 3: Target promotional SKU identified (missing pattern: PROD-7729)" -ForegroundColor Red
    }
    # Check 4: Business exception captured from Loki
    if ($content -and $content.IndexOf('StockReservationException', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 4: Business exception captured from Loki" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 4: Business exception captured from Loki (missing pattern: StockReservationException)" -ForegroundColor Red
    }
    # Check 5: Root cause audit lock documented
    if ($content -and $content.IndexOf('audit', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 5: Root cause audit lock documented" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 5: Root cause audit lock documented (missing pattern: audit)" -ForegroundColor Red
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
