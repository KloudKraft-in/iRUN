# Validation Script for JAVA-D2-102
$ErrorActionPreference = 'Stop'

Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host " Validating JAVA-D2-102: Actuator & Endpoint Security      " -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan

# 1. Public Health Check
Write-Host "`n[Check 1/3] Testing Public /actuator/health (Should be 200 without auth)..."
try {
    $h = Invoke-WebRequest -Uri "http://localhost:8081/actuator/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "  -> Public health returned HTTP $($h.StatusCode) OK." -ForegroundColor Gray
} catch {
    Write-Host "  [FAIL] /actuator/health not accessible." -ForegroundColor Red
    exit 1
}

# 2. Unauthenticated Sensitive Endpoint Check (Expect 401)
Write-Host "`n[Check 2/3] Testing Unauthenticated /actuator/env (Must return 401 Unauthorized)..."
try {
    $envFail = Invoke-WebRequest -Uri "http://localhost:8081/actuator/env" -UseBasicParsing -TimeoutSec 5
    Write-Host "  [FAIL] /actuator/env is publicly exposed without authentication!" -ForegroundColor Red
    exit 1
} catch {
    if ($_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::Unauthorized) {
        Write-Host "  -> Correctly blocked with HTTP 401 Unauthorized." -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Unexpected response: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# 3. Authenticated Sensitive Endpoint Check
Write-Host "`n[Check 3/3] Testing Authenticated /actuator/env with admin:admin123..."
try {
    $secPass = ConvertTo-SecureString "admin123" -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ("admin", $secPass)
    $authRes = Invoke-RestMethod -Uri "http://localhost:8081/actuator/env" -Credential $cred -TimeoutSec 5
    Write-Host "  -> Authenticated /actuator/env successfully accessed with admin role." -ForegroundColor Gray
} catch {
    Write-Host "  [FAIL] Authenticated access failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n===========================================================" -ForegroundColor Green
Write-Host " [PASS] JAVA-D2-102 Actuator & Security Validation Succeeded! " -ForegroundColor Green
Write-Host "===========================================================" -ForegroundColor Green
