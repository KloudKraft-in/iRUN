<#
.SYNOPSIS
  Validation & Harness Script for TEL-D3-303 - "The p95 Latency Monitor That Never Fires" (Windows)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    initialize incident (inject fault / start scenario)
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    restore baseline state
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'check')

$LabDir   = $PSScriptRoot
$Starter  = Join-Path $LabDir 'starter'
$Evidence = Join-Path $Starter 'evidence\evidence_D3_3.json'

function Invoke-Reset {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Resetting Scenario TEL-D3-303..." -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "Baseline state restored."
}

function Invoke-Start {
    Invoke-Reset
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host " Initializing Incident: TEL-D3-303" -ForegroundColor Yellow
    Write-Host " The p95 Latency Monitor That Never Fires" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host "Observed Failure: Critical checkout latency surges past 4 seconds during a promotion, yet the Datadog alert monitor remains completely green and silent."
    Write-Host ""
    Write-Host "Your Mission: Follow guidelines in starter\README_START_HERE.txt"
    Write-Host "Fill evidence template in: starter\evidence\evidence_D3_3.json"
    Write-Host "Then validate with: .\validation_script.ps1 check"
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating Solution for TEL-D3-303" -ForegroundColor Cyan
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
    # Check 1: P95 aggregator used
    if ($content -and $content.IndexOf('p95(last_5m)', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 1: P95 aggregator used" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 1: P95 aggregator used (missing pattern: p95(last_5m))" -ForegroundColor Red
    }
    # Check 2: Production environment targeted
    if ($content -and $content.IndexOf('env:prod', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 2: Production environment targeted" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 2: Production environment targeted (missing pattern: env:prod)" -ForegroundColor Red
    }
    # Check 3: Correct metric targeted
    if ($content -and $content.IndexOf('shopnow.checkout.duration', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 3: Correct metric targeted" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 3: Correct metric targeted (missing pattern: shopnow.checkout.duration)" -ForegroundColor Red
    }
    # Check 4: Threshold set to 2.5s
    if ($content -and $content.IndexOf('2.5', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 4: Threshold set to 2.5s" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 4: Threshold set to 2.5s (missing pattern: 2.5)" -ForegroundColor Red
    }
    # Check 5: Composite alert logic configured
    if ($content -and $content.IndexOf('composite', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 5: Composite alert logic configured" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 5: Composite alert logic configured (missing pattern: composite)" -ForegroundColor Red
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
