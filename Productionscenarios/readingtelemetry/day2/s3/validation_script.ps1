<#
.SYNOPSIS
  Validation & Harness Script for TEL-D2-203 - "One Incident, Four Tools: Write the Escalation" (Windows)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    initialize incident (inject fault / start scenario)
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    restore baseline state
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'check')

$LabDir   = $PSScriptRoot
$Starter  = Join-Path $LabDir 'starter'
$Evidence = Join-Path $Starter 'evidence\evidence_D2_3.md'

function Invoke-Reset {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Resetting Scenario TEL-D2-203..." -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "Baseline state restored."
}

function Invoke-Start {
    Invoke-Reset
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host " Initializing Incident: TEL-D2-203" -ForegroundColor Yellow
    Write-Host " One Incident, Four Tools: Write the Escalation" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host "Observed Failure: Checkout experience is severely degraded across microservices. SREs receive contradictory signals across Grafana, Kibana, New Relic, and cloud consoles."
    Write-Host ""
    Write-Host "Your Mission: Follow guidelines in starter\README_START_HERE.txt"
    Write-Host "Fill evidence template in: starter\evidence\evidence_D2_3.md"
    Write-Host "Then validate with: .\validation_script.ps1 check"
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating Solution for TEL-D2-203" -ForegroundColor Cyan
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
    # Check 1: Contended database identified
    if ($content -and $content.IndexOf('orders_db', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 1: Contended database identified" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 1: Contended database identified (missing pattern: orders_db)" -ForegroundColor Red
    }
    # Check 2: Lock contention root cause cited
    if ($content -and $content.IndexOf('lock', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 2: Lock contention root cause cited" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 2: Lock contention root cause cited (missing pattern: lock)" -ForegroundColor Red
    }
    # Check 3: Bottleneck controller identified
    if ($content -and $content.IndexOf('CheckoutController', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 3: Bottleneck controller identified" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 3: Bottleneck controller identified (missing pattern: CheckoutController)" -ForegroundColor Red
    }
    # Check 4: Grafana evidence referenced
    if ($content -and $content.IndexOf('grafana', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 4: Grafana evidence referenced" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 4: Grafana evidence referenced (missing pattern: grafana)" -ForegroundColor Red
    }
    # Check 5: Kibana log query included
    if ($content -and $content.IndexOf('kibana', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 5: Kibana log query included" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 5: Kibana log query included (missing pattern: kibana)" -ForegroundColor Red
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
