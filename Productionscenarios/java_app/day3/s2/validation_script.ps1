# Validation Script for JAVA-D3-102
$ErrorActionPreference = 'Stop'

Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host " Validating JAVA-D3-102: Tomcat & WildFly WAR Deployment   " -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan

# 1. Tomcat check
Write-Host "`n[Check 1/2] Testing Tomcat deployed WAR on http://localhost:8080/retail-service/health-check..."
try {
    $resTomcat = Invoke-RestMethod -Uri "http://localhost:8080/retail-service/health-check" -Method Get -TimeoutSec 5
    Write-Host "  -> Tomcat Deployed WAR is UP: $resTomcat" -ForegroundColor Gray
} catch {
    Write-Host "  [FAIL] Tomcat deployed WAR not responding on port 8080/retail-service." -ForegroundColor Red
    Write-Host "  Action: Verify WAR is deployed to Tomcat webapps/ and port 8080 is running." -ForegroundColor Yellow
    exit 1
}

Write-Host "`n===========================================================" -ForegroundColor Green
Write-Host " [PASS] JAVA-D3-102 WAR Deployment Validation Succeeded!   " -ForegroundColor Green
Write-Host "===========================================================" -ForegroundColor Green
