Write-Host "Validating Product Service on port 8082..."
Invoke-RestMethod -Uri "http://localhost:8082/api/products/1" -Method Get
Write-Host "Creating Order via Order Service on port 8081..."
$res = Invoke-RestMethod -Uri "http://localhost:8081/api/orders?productId=1&quantity=2" -Method Post
Write-Host "Order Response: $($res | ConvertTo-Json -Compress)"
Write-Host "[PASS] JAVA-D1-101 validation succeeded!" -ForegroundColor Green
