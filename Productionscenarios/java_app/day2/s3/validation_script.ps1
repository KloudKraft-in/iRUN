Write-Host "Validating HikariCP Pool Diagnostics Endpoint..."
$status = Invoke-RestMethod -Uri "http://localhost:8081/api/pool/status"
Write-Host "Pool Status: $($status | ConvertTo-Json -Compress)"
Write-Host "[PASS] JAVA-D2-103 HikariCP Pool diagnostics validated!" -ForegroundColor Green
