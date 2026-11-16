<#
.SYNOPSIS
  Validation & Harness Script for TEL-D5-502 - "Lambda Timeouts: Logs Insights Meets X-Ray" (Windows)
.DESCRIPTION
  .\validation_script.ps1          run validation checks on the solution
  .\validation_script.ps1 start    initialize incident (inject fault / start scenario)
  .\validation_script.ps1 check    run validation checks on the solution
  .\validation_script.ps1 reset    restore baseline state
#>
param([Parameter(Position = 0)][ValidateSet('start', 'check', 'reset', 'help')][string]$Action = 'check')

$LabDir   = $PSScriptRoot
$Starter  = Join-Path $LabDir 'starter'
$Evidence = Join-Path $Starter 'evidence\evidence_D5_2.md'

function Invoke-Reset {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Resetting Scenario TEL-D5-502..." -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "Baseline state restored."
}

function Invoke-Start {
    Invoke-Reset
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host " Initializing Incident: TEL-D5-502" -ForegroundColor Yellow
    Write-Host " Lambda Timeouts: Logs Insights Meets X-Ray" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host "Observed Failure: Order invoice generation Lambdas terminate abruptly with 'Task timed out after 30.00 seconds'. CloudWatch logs show timeouts but do not reveal the stalled downstream call."
    Write-Host ""
    Write-Host "Your Mission: Follow guidelines in starter\README_START_HERE.txt"
    Write-Host "Fill evidence template in: starter\evidence\evidence_D5_2.md"
    Write-Host "Then validate with: .\validation_script.ps1 check"
}

function Invoke-Check {
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Validating Solution for TEL-D5-502" -ForegroundColor Cyan
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
    # Check 1: Timeout message filtered
    if ($content -and $content.IndexOf('Task timed out', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 1: Timeout message filtered" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 1: Timeout message filtered (missing pattern: Task timed out)" -ForegroundColor Red
    }
    # Check 2: Hanging subsegment identified
    if ($content -and $content.IndexOf('S3:PutObject', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 2: Hanging subsegment identified" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 2: Hanging subsegment identified (missing pattern: S3:PutObject)" -ForegroundColor Red
    }
    # Check 3: Target S3 bucket captured
    if ($content -and $content.IndexOf('shopnow-invoices-archive', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 3: Target S3 bucket captured" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 3: Target S3 bucket captured (missing pattern: shopnow-invoices-archive)" -ForegroundColor Red
    }
    # Check 4: VPC routing / endpoint root cause cited
    if ($content -and $content.IndexOf('VPC', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 4: VPC routing / endpoint root cause cited" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 4: VPC routing / endpoint root cause cited (missing pattern: VPC)" -ForegroundColor Red
    }
    # Check 5: 30-second execution limit noted
    if ($content -and $content.IndexOf('30', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Host "  [PASS] Rule 5: 30-second execution limit noted" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Rule 5: 30-second execution limit noted (missing pattern: 30)" -ForegroundColor Red
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
