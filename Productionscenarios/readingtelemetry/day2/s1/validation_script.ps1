<#
.SYNOPSIS
  Validation & Harness Script for TEL-D2-201 - "Davis Opened a Problem: Find the Root Cause" (Windows)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    initialize incident (inject fault / start scenario)
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    restore baseline state
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'check')

$LabDir   = $PSScriptRoot
$Starter  = Join-Path $LabDir 'starter'
$Evidence = Join-Path $Starter 'evidence\evidence_D2_1.md'

function Invoke-Reset {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Resetting Scenario TEL-D2-201..." -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "Baseline state restored."
}

function Invoke-Start {
    Invoke-Reset
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host " Initializing Incident: TEL-D2-201" -ForegroundColor Yellow
    Write-Host " Davis Opened a Problem: Find the Root Cause" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host "Observed Failure: Dynatrace Davis AI engine automatically opened Problem P-24101 indicating payment degradation. Navigating complex UI menus makes finding the root cause code span difficult."
    Write-Host ""
    Write-Host "Your Mission: Follow guidelines in starter\README_START_HERE.txt"
    Write-Host "Fill evidence template in: starter\evidence\evidence_D2_1.md"
    Write-Host "Then validate with: .\validation_script.ps1 check"
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating Solution for TEL-D2-201" -ForegroundColor Cyan
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
    # Check 1: Dynatrace problem card ID identified
    if ($content -and $content.IndexOf('P-24101', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 1: Dynatrace problem card ID identified" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 1: Dynatrace problem card ID identified (missing pattern: P-24101)" -ForegroundColor Red
    }
    # Check 2: Failing topology service isolated
    if ($content -and $content.IndexOf('PaymentService', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 2: Failing topology service isolated" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 2: Failing topology service isolated (missing pattern: PaymentService)" -ForegroundColor Red
    }
    # Check 3: Code-level failing method captured
    if ($content -and $content.IndexOf('StripeGatewayConnector.authorize', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 3: Code-level failing method captured" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 3: Code-level failing method captured (missing pattern: StripeGatewayConnector.authorize)" -ForegroundColor Red
    }
    # Check 4: Underlying network timeout exception identified
    if ($content -and $content.IndexOf('SocketTimeoutException', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 4: Underlying network timeout exception identified" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 4: Underlying network timeout exception identified (missing pattern: SocketTimeoutException)" -ForegroundColor Red
    }
    # Check 5: Host infrastructure node identified
    if ($content -and $content.IndexOf('prod-host-03', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 5: Host infrastructure node identified" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 5: Host infrastructure node identified (missing pattern: prod-host-03)" -ForegroundColor Red
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
