<#
.SYNOPSIS
  Validation & Harness Script for TEL-D6-602 - "Error Budget Burn and a Cardinality Bill" (Windows)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    initialize incident (inject fault / start scenario)
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    restore baseline state
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'check')

$LabDir   = $PSScriptRoot
$Starter  = Join-Path $LabDir 'starter'
$Evidence = Join-Path $Starter 'evidence\evidence_D6_2.md'

function Invoke-Reset {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Resetting Scenario TEL-D6-602..." -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "Baseline state restored."
}

function Invoke-Start {
    Invoke-Reset
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host " Initializing Incident: TEL-D6-602" -ForegroundColor Yellow
    Write-Host " Error Budget Burn and a Cardinality Bill" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host "Observed Failure: A sudden release introduces high-cardinality labels, causing Prometheus TSDB series count to explode and depleting the 30-day error budget in under 2 hours."
    Write-Host ""
    Write-Host "Your Mission: Follow guidelines in starter\README_START_HERE.txt"
    Write-Host "Fill evidence template in: starter\evidence\evidence_D6_2.md"
    Write-Host "Then validate with: .\validation_script.ps1 check"
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating Solution for TEL-D6-602" -ForegroundColor Cyan
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
    # Check 1: High-cardinality label identified
    if ($content -and $content.IndexOf('user_id', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 1: High-cardinality label identified" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 1: High-cardinality label identified (missing pattern: user_id)" -ForegroundColor Red
    }
    # Check 2: Prometheus labeldrop action specified
    if ($content -and $content.IndexOf('labeldrop', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 2: Prometheus labeldrop action specified" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 2: Prometheus labeldrop action specified (missing pattern: labeldrop)" -ForegroundColor Red
    }
    # Check 3: metric_relabel_configs block used
    if ($content -and $content.IndexOf('metric_relabel_configs', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 3: metric_relabel_configs block used" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 3: metric_relabel_configs block used (missing pattern: metric_relabel_configs)" -ForegroundColor Red
    }
    # Check 4: Error budget burn rate documented
    if ($content -and $content.IndexOf('burn', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 4: Error budget burn rate documented" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 4: Error budget burn rate documented (missing pattern: burn)" -ForegroundColor Red
    }
    # Check 5: Regex selector defined
    if ($content -and $content.IndexOf('regex:', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 5: Regex selector defined" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 5: Regex selector defined (missing pattern: regex:)" -ForegroundColor Red
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
