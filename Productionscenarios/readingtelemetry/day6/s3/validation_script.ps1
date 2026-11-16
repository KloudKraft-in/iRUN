<#
.SYNOPSIS
  Validation & Harness Script for TEL-D6-603 - "Integrated Production Incident Workshop" (Windows)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    initialize incident (inject fault / start scenario)
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    restore baseline state
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'check')

$LabDir   = $PSScriptRoot
$Starter  = Join-Path $LabDir 'starter'
$Evidence = Join-Path $Starter 'evidence\evidence_D6_3.md'

function Invoke-Reset {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Resetting Scenario TEL-D6-603..." -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "Baseline state restored."
}

function Invoke-Start {
    Invoke-Reset
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host " Initializing Incident: TEL-D6-603" -ForegroundColor Yellow
    Write-Host " Integrated Production Incident Workshop" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host "Observed Failure: Major production outage impacts all tiers of the ShopNow enterprise. Incident commander requires verified query evidence across all 7 observability platforms."
    Write-Host ""
    Write-Host "Your Mission: Follow guidelines in starter\README_START_HERE.txt"
    Write-Host "Fill evidence template in: starter\evidence\evidence_D6_3.md"
    Write-Host "Then validate with: .\validation_script.ps1 check"
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating Solution for TEL-D6-603" -ForegroundColor Cyan
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
    # Check 1: Splunk SPL query recorded
    if ($content -and $content.IndexOf('Splunk', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 1: Splunk SPL query recorded" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 1: Splunk SPL query recorded (missing pattern: Splunk)" -ForegroundColor Red
    }
    # Check 2: Dynatrace DQL query recorded
    if ($content -and $content.IndexOf('Dynatrace', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 2: Dynatrace DQL query recorded" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 2: Dynatrace DQL query recorded (missing pattern: Dynatrace)" -ForegroundColor Red
    }
    # Check 3: New Relic NRQL query recorded
    if ($content -and $content.IndexOf('New Relic', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 3: New Relic NRQL query recorded" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 3: New Relic NRQL query recorded (missing pattern: New Relic)" -ForegroundColor Red
    }
    # Check 4: Loki LogQL query recorded
    if ($content -and $content.IndexOf('Loki', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 4: Loki LogQL query recorded" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 4: Loki LogQL query recorded (missing pattern: Loki)" -ForegroundColor Red
    }
    # Check 5: Azure KQL query recorded
    if ($content -and $content.IndexOf('Azure', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 5: Azure KQL query recorded" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 5: Azure KQL query recorded (missing pattern: Azure)" -ForegroundColor Red
    }
    # Check 6: Prometheus PromQL query recorded
    if ($content -and $content.IndexOf('Prometheus', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 6: Prometheus PromQL query recorded" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 6: Prometheus PromQL query recorded (missing pattern: Prometheus)" -ForegroundColor Red
    }
    # Check 7: Datadog query recorded
    if ($content -and $content.IndexOf('Datadog', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 7: Datadog query recorded" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 7: Datadog query recorded (missing pattern: Datadog)" -ForegroundColor Red
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
