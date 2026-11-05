# Validation Script for JAVA-D1-101
$ErrorActionPreference = 'Stop'

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host " Validating JAVA-D1-101: Monolith to Microservices " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

# 1. Validate Product Service on Port 8082
Write-Host "`n[Check 1/2] Testing Product Service on http://localhost:8082/api/products/1..."
try {
    $prod = Invoke-RestMethod -Uri "http://localhost:8082/api/products/1" -Method Get -TimeoutSec 5
    Write-Host "  -> Product Service is UP. Response: " -NoNewline -ForegroundColor Gray
    Write-Host ($prod | ConvertTo-Json -Compress) -ForegroundColor White
} catch {
    Write-Host "  [FAIL] Unable to connect to Product Service on port 8082." -ForegroundColor Red
    Write-Host "  Reason: The product-service process is not currently running." -ForegroundColor Yellow
    Write-Host "  Action: Open a separate terminal, navigate to product-service, and run: mvn spring-boot:run" -ForegroundColor Yellow
    exit 1
}

# 2. Validate Order Service on Port 8081
Write-Host "`n[Check 2/2] Testing Order Service on http://localhost:8081/api/orders..."
try {
    $res = Invoke-RestMethod -Uri "http://localhost:8081/api/orders?productId=1&quantity=2" -Method Post -TimeoutSec 5
    Write-Host "  -> Order Service is UP. Order Response: " -NoNewline -ForegroundColor Gray
    Write-Host ($res | ConvertTo-Json -Compress) -ForegroundColor White
} catch {
    Write-Host "  [FAIL] Unable to connect to Order Service on port 8081." -ForegroundColor Red
    Write-Host "  Reason: The order-service process is not currently running." -ForegroundColor Yellow
    Write-Host "  Action: Open a separate terminal, navigate to order-service, and run: mvn spring-boot:run" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n===================================================" -ForegroundColor Green
Write-Host " [PASS] JAVA-D1-101 Validation Succeeded! " -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green
