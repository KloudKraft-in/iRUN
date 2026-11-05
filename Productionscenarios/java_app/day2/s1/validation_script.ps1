# Validation Script for JAVA-D2-101
$ErrorActionPreference = 'Stop'

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host " Validating JAVA-D2-101: Spring Profiles & Binding " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

Write-Host "`n[Check] Querying Store Info endpoint on http://localhost:8081/api/store-info..."
try {
    $res = Invoke-RestMethod -Uri "http://localhost:8081/api/store-info" -Method Get -TimeoutSec 5
    Write-Host "  -> Store Info Response: " -NoNewline -ForegroundColor Gray
    Write-Host ($res | ConvertTo-Json -Compress) -ForegroundColor White

    if ($null -eq $res.environment -or $null -eq $res.discount) {
        Write-Host "  [FAIL] Configuration values are null or unbound." -ForegroundColor Red
        Write-Host "  Action: Implement @ConfigurationProperties and application-dev/prod.properties" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "  [FAIL] Unable to connect to product-service on port 8081." -ForegroundColor Red
    Write-Host "  Action: Ensure application is running with active profile: mvn spring-boot:run" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n===================================================" -ForegroundColor Green
Write-Host " [PASS] JAVA-D2-101 Configuration Binding Succeeded! " -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green
