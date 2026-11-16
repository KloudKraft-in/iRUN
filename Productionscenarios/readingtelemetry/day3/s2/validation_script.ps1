<#
.SYNOPSIS
  Validation & Harness Script for TEL-D3-302 - "Which App Is Failing? Ask Grail" (Windows)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    initialize incident (inject fault / start scenario)
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    restore baseline state
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'check')

$LabDir   = $PSScriptRoot
$Starter  = Join-Path $LabDir 'starter'
$Evidence = Join-Path $Starter 'evidence\evidence_D3_2.md'

function Invoke-Reset {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Resetting Scenario TEL-D3-302..." -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "Baseline state restored."
}

function Invoke-Start {
    Invoke-Reset
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host " Initializing Incident: TEL-D3-302" -ForegroundColor Yellow
    Write-Host " Which App Is Failing? Ask Grail" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host "Observed Failure: Multiple microservices log failures simultaneously across Kubernetes clusters. Traditional search fails to summarize error types by service entity."
    Write-Host ""
    Write-Host "Your Mission: Follow guidelines in starter\README_START_HERE.txt"
    Write-Host "Fill evidence template in: starter\evidence\evidence_D3_2.md"
    Write-Host "Then validate with: .\validation_script.ps1 check"
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating Solution for TEL-D3-302" -ForegroundColor Cyan
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
    # Check 1: DQL fetch logs statement used
    if ($content -and $content.IndexOf('fetch logs', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 1: DQL fetch logs statement used" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 1: DQL fetch logs statement used (missing pattern: fetch logs)" -ForegroundColor Red
    }
    # Check 2: Error status filtered
    if ($content -and $content.IndexOf('filter status == "ERROR"', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 2: Error status filtered" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 2: Error status filtered (missing pattern: filter status == "ERROR")" -ForegroundColor Red
    }
    # Check 3: Dynatrace entity service grouped
    if ($content -and $content.IndexOf('dt.entity.service', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 3: Dynatrace entity service grouped" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 3: Dynatrace entity service grouped (missing pattern: dt.entity.service)" -ForegroundColor Red
    }
    # Check 4: Culprit service identified
    if ($content -and $content.IndexOf('inventory-worker', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 4: Culprit service identified" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 4: Culprit service identified (missing pattern: inventory-worker)" -ForegroundColor Red
    }
    # Check 5: Root cause deadlock exception identified
    if ($content -and $content.IndexOf('DeadlockException', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 5: Root cause deadlock exception identified" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 5: Root cause deadlock exception identified (missing pattern: DeadlockException)" -ForegroundColor Red
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
