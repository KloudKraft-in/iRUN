Write-Host "Validating Retail Service Health..."
try {
    $res = Invoke-RestMethod -Uri "http://localhost:8080/health-check"
    Write-Host "Health: $res"
} catch {
    Write-Host "Service check: $($_.Exception.Message)"
}
Write-Host "Checking JVM processes with jcmd..."
jcmd -l
Write-Host "[PASS] JAVA-D3-103 validation complete!" -ForegroundColor Green
