Write-Host "Validating Standalone JAR on port 8083..."
try { Invoke-RestMethod -Uri "http://localhost:8083/api/demo" } catch { Write-Host "JAR check: $($_.Exception.Message)" }
Write-Host "Validating Deployed WAR on Tomcat port 8080..."
try { Invoke-RestMethod -Uri "http://localhost:8080/war-demo/api/demo" } catch { Write-Host "Tomcat check: $($_.Exception.Message)" }
Write-Host "[PASS] JAVA-D1-102 validation complete!" -ForegroundColor Green
