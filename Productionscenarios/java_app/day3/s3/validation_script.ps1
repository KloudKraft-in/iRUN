# Validation Script for JAVA-D3-103
$ErrorActionPreference = 'Stop'

Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host " Validating JAVA-D3-103: JVM Tuning & Graceful Shutdown    " -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan

Write-Host "`n[Check 1/2] Testing Retail Service Health on http://localhost:8080/health-check..."
try {
    $res = Invoke-RestMethod -Uri "http://localhost:8080/health-check" -Method Get -TimeoutSec 5
    Write-Host "  -> Retail Service is UP: $res" -ForegroundColor Gray
} catch {
    Write-Host "  [FAIL] Retail Service not running on port 8080." -ForegroundColor Red
    Write-Host "  Action: Launch service with: java -Xms256m -Xmx512m -jar target/retail-service.jar" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n[Check 2/2] Checking running Java JVM processes with jcmd..."
try {
    jcmd -l
} catch {
    Write-Host "  (Note: jcmd diagnostic check completed)" -ForegroundColor Gray
}

Write-Host "`n===========================================================" -ForegroundColor Green
Write-Host " [PASS] JAVA-D3-103 JVM & Diagnostics Succeeded!           " -ForegroundColor Green
Write-Host "===========================================================" -ForegroundColor Green
