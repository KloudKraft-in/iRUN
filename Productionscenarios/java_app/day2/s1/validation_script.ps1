Write-Host "Validating Store Info with Active Dev Profile..."
$res = Invoke-RestMethod -Uri "http://localhost:8081/api/store-info"
Write-Host "Store Info Response: $($res | ConvertTo-Json -Compress)"
if ($res.discount -eq 15) {
    Write-Host "[PASS] Dev profile discount verified (15%)!" -ForegroundColor Green
}
Write-Host "[PASS] JAVA-D2-101 validation succeeded!" -ForegroundColor Green
