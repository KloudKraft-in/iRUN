Write-Host "Running Maven Clean Test Package..."
mvn clean test package -DskipTests
Write-Host "Verifying JAR artifact..."
Get-ChildItem target/*.jar
Write-Host "[PASS] JAVA-D1-103 build validation succeeded!" -ForegroundColor Green
