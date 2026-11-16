<#
.SYNOPSIS
  Validation & Harness Script for TEL-D4-403 - "Latency Percentile and Service Variable Are Wrong" (Windows)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    initialize incident (inject fault / start scenario)
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    restore baseline state
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'check')

$LabDir   = $PSScriptRoot
$Starter  = Join-Path $LabDir 'starter'
$Evidence = Join-Path $Starter 'evidence\evidence_D4_3.json'

function Invoke-Reset {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Resetting Scenario TEL-D4-403..." -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "Baseline state restored."
}

function Invoke-Start {
    Invoke-Reset
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host " Initializing Incident: TEL-D4-403" -ForegroundColor Yellow
    Write-Host " Latency Percentile and Service Variable Are Wrong" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host "Observed Failure: SRE dashboard latency percentiles show flat lines measuring cumulative stats since server reboot, and selecting a service in the variable dropdown causes panels to show 'No Data'."
    Write-Host ""
    Write-Host "Your Mission: Follow guidelines in starter\README_START_HERE.txt"
    Write-Host "Fill evidence template in: starter\evidence\evidence_D4_3.json"
    Write-Host "Then validate with: .\validation_script.ps1 check"
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating Solution for TEL-D4-403" -ForegroundColor Cyan
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
    # Check 1: Quantile set to 0.95
    if ($content -and $content.IndexOf('histogram_quantile(0.95', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 1: Quantile set to 0.95" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 1: Quantile set to 0.95 (missing pattern: histogram_quantile(0.95)" -ForegroundColor Red
    }
    # Check 2: Rate wrapped around bucket counter
    if ($content -and $content.IndexOf('rate(http_request_duration_seconds_bucket', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 2: Rate wrapped around bucket counter" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 2: Rate wrapped around bucket counter (missing pattern: rate(http_request_duration_seconds_bucket)" -ForegroundColor Red
    }
    # Check 3: Aggregation includes le label
    if ($content -and $content.IndexOf('by (le', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 3: Aggregation includes le label" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 3: Aggregation includes le label (missing pattern: by (le)" -ForegroundColor Red
    }
    # Check 4: Non-capturing regex group implemented
    if ($content -and $content.IndexOf('?:', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 4: Non-capturing regex group implemented" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 4: Non-capturing regex group implemented (missing pattern: ?:)" -ForegroundColor Red
    }
    # Check 5: Variable interpolation preserved
    if ($content -and $content.IndexOf('service=~"$service"', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 5: Variable interpolation preserved" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 5: Variable interpolation preserved (missing pattern: service=~"$service")" -ForegroundColor Red
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
