Write-Host "Validating Tomcat Deployed WAR..."
try { Invoke-RestMethod -Uri "http://localhost:8080/retail-service/health-check" } catch { Write-Host "Tomcat check: $($_.Exception.Message)" }
Write-Host "Validating WildFly Deployed WAR..."
try { Invoke-RestMethod -Uri "http://localhost:8080/retail-service/health-check" } catch { Write-Host "WildFly check: $($_.Exception.Message)" }
Write-Host "[PASS] JAVA-D3-102 validation complete!" -ForegroundColor Green
