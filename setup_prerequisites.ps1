# Setup and Verification Script for iRUN Production Scenarios
$ErrorActionPreference = 'Continue'
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host " iRUN / Production Scenarios Prerequisite Check & Setup " -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan

# 1. Check & Install Java JDK
Write-Host "`n[1/6] Checking Java JDK..." -ForegroundColor Yellow
if (Get-Command java -ErrorAction SilentlyContinue) {
    Write-Host "  -> Java is already installed:" -ForegroundColor Green
    java -version
} else {
    Write-Host "  -> Installing Eclipse Temurin JDK 17 via winget..." -ForegroundColor Yellow
    winget install EclipseAdoptium.Temurin.17.JDK --accept-source-agreements --accept-package-agreements
}

# 2. Check & Install Apache Maven
Write-Host "`n[2/6] Checking Apache Maven..." -ForegroundColor Yellow
if (Get-Command mvn -ErrorAction SilentlyContinue) {
    Write-Host "  -> Maven is already installed:" -ForegroundColor Green
    mvn -version
} else {
    Write-Host "  -> Installing Apache Maven via winget..." -ForegroundColor Yellow
    winget install Apache.Maven --accept-source-agreements --accept-package-agreements
}

# 3. Check & Install Git
Write-Host "`n[3/6] Checking Git..." -ForegroundColor Yellow
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "  -> Git is already installed:" -ForegroundColor Green
    git --version
} else {
    Write-Host "  -> Installing Git via winget..." -ForegroundColor Yellow
    winget install Git.Git --accept-source-agreements --accept-package-agreements
}

# 4. Download & Extract Apache Tomcat 10.1
Write-Host "`n[4/6] Checking Apache Tomcat 10.1..." -ForegroundColor Yellow
$tomcatPath = "C:\training_tools\apache-tomcat-10.1.20"
if (Test-Path $tomcatPath) {
    Write-Host "  -> Apache Tomcat 10.1 already exists at $tomcatPath" -ForegroundColor Green
} else {
    Write-Host "  -> Downloading Tomcat 10.1 to C:\training_tools..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path "C:\training_tools" -Force | Out-Null
    Invoke-WebRequest -Uri "https://archive.apache.org/dist/tomcat/tomcat-10/v10.1.20/bin/apache-tomcat-10.1.20-windows-x64.zip" -OutFile "C:\training_tools\tomcat10.zip"
    Expand-Archive -Path "C:\training_tools\tomcat10.zip" -DestinationPath "C:\training_tools" -Force
    Remove-Item "C:\training_tools\tomcat10.zip" -Force
    Write-Host "  -> Tomcat 10.1 extracted to C:\training_tools" -ForegroundColor Green
}

# 5. Download & Extract WildFly 30
Write-Host "`n[5/6] Checking WildFly 30.0.1.Final..." -ForegroundColor Yellow
$wildflyPath = "C:\training_tools\wildfly-30.0.1.Final"
if (Test-Path $wildflyPath) {
    Write-Host "  -> WildFly 30 already exists at $wildflyPath" -ForegroundColor Green
} else {
    Write-Host "  -> Downloading WildFly 30 to C:\training_tools..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path "C:\training_tools" -Force | Out-Null
    Invoke-WebRequest -Uri "https://github.com/wildfly/wildfly/releases/download/30.0.1.Final/wildfly-30.0.1.Final.zip" -OutFile "C:\training_tools\wildfly30.zip"
    Expand-Archive -Path "C:\training_tools\wildfly30.zip" -DestinationPath "C:\training_tools" -Force
    Remove-Item "C:\training_tools\wildfly30.zip" -Force
    Write-Host "  -> WildFly 30 extracted to C:\training_tools" -ForegroundColor Green
}

# 6. Verify Port Availability
Write-Host "`n[6/6] Checking Required Ports (8080, 8081, 8082, 8083, 8888, 9990)..." -ForegroundColor Yellow
$ports = @(8080, 8081, 8082, 8083, 8888, 9990)
$occupied = Get-NetTCPConnection -LocalPort $ports -State Listen -ErrorAction SilentlyContinue
if ($occupied) {
    Write-Host "  [WARNING] The following ports are already in use:" -ForegroundColor Red
    $occupied | Select-Object LocalPort, OwningProcess | Format-Table -AutoSize
    Write-Host "  Please terminate processes on these ports before starting exercises." -ForegroundColor Red
} else {
    Write-Host "  -> All required ports (8080, 8081, 8082, 8083, 8888, 9990) are completely FREE!" -ForegroundColor Green
}

Write-Host "`n=====================================================" -ForegroundColor Green
Write-Host " Prerequisites setup check completed! " -ForegroundColor Green
Write-Host " Restart your PowerShell terminal if you installed new tools via winget." -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green

