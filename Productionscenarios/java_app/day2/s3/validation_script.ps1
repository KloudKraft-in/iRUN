# Validation Script for JAVA-D2-103
$ErrorActionPreference = 'Stop'

Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host " Validating JAVA-D2-103: Startup Diagnostics & HikariCP   " -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan

Write-Host "`n[Check] Testing HikariCP Pool Diagnostics on http://localhost:8081/api/pool/status..."
try {
    $status = Invoke-RestMethod -Uri "http://localhost:8081/api/pool/status" -Method Get -TimeoutSec 5
    Write-Host "  -> Pool Status: " -NoNewline -ForegroundColor Gray
    Write-Host ($status | ConvertTo-Json -Compress) -ForegroundColor White
} catch {
    Write-Host "  [FAIL] Unable to connect to Pool Diagnostics on port 8081." -ForegroundColor Red
    Write-Host "  Action: Ensure application starts cleanly without BeanCreationException." -ForegroundColor Yellow
    exit 1
}

Write-Host "`n===========================================================" -ForegroundColor Green
Write-Host " [PASS] JAVA-D2-103 HikariCP Diagnostics Succeeded!       " -ForegroundColor Green
Write-Host "===========================================================" -ForegroundColor Green
