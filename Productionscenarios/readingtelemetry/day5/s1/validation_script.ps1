<#
.SYNOPSIS
  Validation & Harness Script for TEL-D5-501 - "Top Failing Dependency in Application Insights" (Windows)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    initialize incident (inject fault / start scenario)
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    restore baseline state
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'check')

$LabDir   = $PSScriptRoot
$Starter  = Join-Path $LabDir 'starter'
$Evidence = Join-Path $Starter 'evidence\evidence_D5_1.md'

function Invoke-Reset {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Resetting Scenario TEL-D5-501..." -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "Baseline state restored."
}

function Invoke-Start {
    Invoke-Reset
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host " Initializing Incident: TEL-D5-501" -ForegroundColor Yellow
    Write-Host " Top Failing Dependency in Application Insights" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host "Observed Failure: Downstream third-party dependency failures cause checkout degradation. Engineers cannot determine which vendor is failing or correlate errors to application exceptions."
    Write-Host ""
    Write-Host "Your Mission: Follow guidelines in starter\README_START_HERE.txt"
    Write-Host "Fill evidence template in: starter\evidence\evidence_D5_1.md"
    Write-Host "Then validate with: .\validation_script.ps1 check"
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating Solution for TEL-D5-501" -ForegroundColor Cyan
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
    # Check 1: Dependencies table queried
    if ($content -and $content.IndexOf('dependencies', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 1: Dependencies table queried" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 1: Dependencies table queried (missing pattern: dependencies)" -ForegroundColor Red
    }
    # Check 2: Failing dependency target identified
    if ($content -and $content.IndexOf('api.external-fraud.io', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 2: Failing dependency target identified" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 2: Failing dependency target identified (missing pattern: api.external-fraud.io)" -ForegroundColor Red
    }
    # Check 3: Inner join with exceptions table performed
    if ($content -and $content.IndexOf('join kind=inner', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 3: Inner join with exceptions table performed" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 3: Inner join with exceptions table performed (missing pattern: join kind=inner)" -ForegroundColor Red
    }
    # Check 4: Correlated on operation_Id
    if ($content -and $content.IndexOf('operation_Id', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 4: Correlated on operation_Id" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 4: Correlated on operation_Id (missing pattern: operation_Id)" -ForegroundColor Red
    }
    # Check 5: Gateway timeout error code recorded
    if ($content -and $content.IndexOf('504', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 5: Gateway timeout error code recorded" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 5: Gateway timeout error code recorded (missing pattern: 504)" -ForegroundColor Red
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
