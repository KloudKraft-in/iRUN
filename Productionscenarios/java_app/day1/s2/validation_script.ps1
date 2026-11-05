# Validation Script for JAVA-D1-102
$ErrorActionPreference = 'Stop'

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host " Validating JAVA-D1-102: JAR / WAR Deployment      " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

# 1. Validate Standalone JAR on Port 8083
Write-Host "`n[Check 1/2] Testing Standalone Executable JAR on http://localhost:8083..."
try {
    $resJar = Invoke-RestMethod -Uri "http://localhost:8083/api/demo" -Method Get -TimeoutSec 5
    Write-Host "  -> Standalone JAR is UP on port 8083: " -NoNewline -ForegroundColor Gray
    Write-Host ($resJar | ConvertTo-Json -Compress) -ForegroundColor White
} catch {
    Write-Host "  [FAIL] Unable to connect to Standalone JAR on port 8083." -ForegroundColor Red
    Write-Host "  Action: Start jar-demo on port 8083: java -jar target/jar-demo-0.0.1-SNAPSHOT.jar" -ForegroundColor Yellow
    exit 1
}

# 2. Validate Tomcat Deployed WAR on Port 8080
Write-Host "`n[Check 2/2] Testing Deployed WAR on Tomcat http://localhost:8080/war-demo..."
try {
    $resWar = Invoke-RestMethod -Uri "http://localhost:8080/war-demo/api/demo" -Method Get -TimeoutSec 5
    Write-Host "  -> Tomcat Deployed WAR is UP on port 8080: " -NoNewline -ForegroundColor Gray
    Write-Host ($resWar | ConvertTo-Json -Compress) -ForegroundColor White
} catch {
    Write-Host "  [FAIL] Unable to connect to Tomcat WAR on port 8080/war-demo." -ForegroundColor Red
    Write-Host "  Action: Ensure Tomcat is running and war-demo.war is deployed to webapps/" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n===================================================" -ForegroundColor Green
Write-Host " [PASS] JAVA-D1-102 Validation Succeeded! " -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green
