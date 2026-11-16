<#
.SYNOPSIS
  Validation & Harness Script for TEL-D3-301 - "Error Spike on One Host After a Release" (Windows)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    initialize incident (inject fault / start scenario)
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    restore baseline state
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'check')

$LabDir   = $PSScriptRoot
$Starter  = Join-Path $LabDir 'starter'
$Evidence = Join-Path $Starter 'evidence\evidence_D3_1.md'

function Invoke-Reset {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Resetting Scenario TEL-D3-301..." -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "Baseline state restored."
}

function Invoke-Start {
    Invoke-Reset
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host " Initializing Incident: TEL-D3-301" -ForegroundColor Yellow
    Write-Host " Error Spike on One Host After a Release" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host "Observed Failure: Post-deployment error rate surges to 8.4%. Standard log searches fail to extract unstructured error codes from application logs on host web-prod-04."
    Write-Host ""
    Write-Host "Your Mission: Follow guidelines in starter\README_START_HERE.txt"
    Write-Host "Fill evidence template in: starter\evidence\evidence_D3_1.md"
    Write-Host "Then validate with: .\validation_script.ps1 check"
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating Solution for TEL-D3-301" -ForegroundColor Cyan
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
    # Check 1: Culprit host isolated
    if ($content -and $content.IndexOf('web-prod-04', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 1: Culprit host isolated" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 1: Culprit host isolated (missing pattern: web-prod-04)" -ForegroundColor Red
    }
    # Check 2: Regex extraction command used
    if ($content -and $content.IndexOf('rex field=_raw', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 2: Regex extraction command used" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 2: Regex extraction command used (missing pattern: rex field=_raw)" -ForegroundColor Red
    }
    # Check 3: Error code pattern matched
    if ($content -and $content.IndexOf('ERR-[0-9]{4}', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 3: Error code pattern matched" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 3: Error code pattern matched (missing pattern: ERR-[0-9]{4})" -ForegroundColor Red
    }
    # Check 4: Timechart aggregation present
    if ($content -and $content.IndexOf('timechart', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 4: Timechart aggregation present" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 4: Timechart aggregation present (missing pattern: timechart)" -ForegroundColor Red
    }
    # Check 5: Session transaction grouping implemented
    if ($content -and $content.IndexOf('transaction session_id', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 5: Session transaction grouping implemented" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 5: Session transaction grouping implemented (missing pattern: transaction session_id)" -ForegroundColor Red
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
