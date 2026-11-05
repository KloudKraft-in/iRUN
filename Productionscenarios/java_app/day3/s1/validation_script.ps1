# Validation Script for JAVA-D3-101
$ErrorActionPreference = 'Stop'

Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host " Validating JAVA-D3-101: Spring Cloud Centralized Config   " -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan

# 1. Config Server
Write-Host "`n[Check 1/2] Testing Config Server on http://localhost:8888/retail-service/dev..."
try {
    $cfg = Invoke-RestMethod -Uri "http://localhost:8888/retail-service/dev" -Method Get -TimeoutSec 5
    Write-Host "  -> Config Server is UP. App Name: $($cfg.name)" -ForegroundColor Gray
} catch {
    Write-Host "  [FAIL] Centralized Config Server not responding on port 8888." -ForegroundColor Red
    Write-Host "  Action: Start ConfigServerApplication on port 8888: mvn spring-boot:run" -ForegroundColor Yellow
    exit 1
}

# 2. Retail Client
Write-Host "`n[Check 2/2] Testing Retail Client on http://localhost:8083/discount..."
try {
    $disc = Invoke-RestMethod -Uri "http://localhost:8083/discount" -Method Get -TimeoutSec 5
    Write-Host "  -> Retail Client is UP. Current Discount: $disc" -ForegroundColor White
} catch {
    Write-Host "  [FAIL] Retail Client not responding on port 8083." -ForegroundColor Red
    Write-Host "  Action: Start retail-client on port 8083: mvn spring-boot:run" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n===========================================================" -ForegroundColor Green
Write-Host " [PASS] JAVA-D3-101 Centralized Config Succeeded!          " -ForegroundColor Green
Write-Host "===========================================================" -ForegroundColor Green
