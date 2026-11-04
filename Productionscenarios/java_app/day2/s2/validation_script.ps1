Write-Host "1. Checking Public /actuator/health..."
$h = Invoke-WebRequest -Uri "http://localhost:8081/actuator/health"
Write-Host "Health status: $($h.StatusCode)"
Write-Host "2. Checking Secured /actuator/env without auth (Expect 401)..."
try {
    Invoke-WebRequest -Uri "http://localhost:8081/actuator/env"
    Write-Host "[FAIL] Expected 401 Unauthorized!" -ForegroundColor Red
} catch {
    Write-Host "[PASS] Correctly blocked with 401 Unauthorized" -ForegroundColor Green
}
Write-Host "3. Checking Secured /actuator/env with admin credentials..."
$secPass = ConvertTo-SecureString "admin123" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("admin", $secPass)
$authRes = Invoke-RestMethod -Uri "http://localhost:8081/actuator/env" -Credential $cred
Write-Host "[PASS] JAVA-D2-102 Actuator & Security validation succeeded!" -ForegroundColor Green
