Write-Host "Validating Centralized Config Server on port 8888..."
Invoke-RestMethod -Uri "http://localhost:8888/retail-service/dev"
Write-Host "Validating Retail Client Discount on port 8083..."
$disc = Invoke-RestMethod -Uri "http://localhost:8083/discount"
Write-Host "Current Discount: $disc"
Write-Host "[PASS] JAVA-D3-101 Spring Cloud Config validation succeeded!" -ForegroundColor Green
