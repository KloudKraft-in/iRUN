# Validation Script for JAVA-D1-103
$ErrorActionPreference = 'Stop'

Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host " Validating JAVA-D1-103: Maven/Gradle & Dependency Mgmt   " -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan

Write-Host "`n[Check 1/2] Executing Maven clean package..."
try {
    mvn clean package -DskipTests
    if ($LASTEXITCODE -ne 0) { throw "Maven build exited with code $LASTEXITCODE" }
} catch {
    Write-Host "  [FAIL] Maven build failed." -ForegroundColor Red
    exit 1
}

Write-Host "`n[Check 2/2] Verifying generated executable fat JAR..."
$jars = Get-ChildItem -Path "target" -Filter "*.jar" -ErrorAction SilentlyContinue
if ($jars.Count -eq 0) {
    Write-Host "  [FAIL] No JAR artifact found in target/ directory." -ForegroundColor Red
    exit 1
}
Write-Host "  -> Generated JAR: $($jars[0].Name) ($([math]::Round($jars[0].Length / 1MB, 2)) MB)" -ForegroundColor Gray

Write-Host "`n===========================================================" -ForegroundColor Green
Write-Host " [PASS] JAVA-D1-103 Build Validation Succeeded!           " -ForegroundColor Green
Write-Host "===========================================================" -ForegroundColor Green
