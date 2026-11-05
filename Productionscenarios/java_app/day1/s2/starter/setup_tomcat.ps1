
$ErrorActionPreference = "Stop"

Write-Host "===== TOMCAT SETUP =====" -ForegroundColor Cyan

# STEP 1: Check Java
Write-Host "`n1. Checking Java..."
java -version

# STEP 2: Create installation directory
Write-Host "`n2. Creating directory..."

$InstallDirectory = "C:\Tools"
$TomcatVersion = "10.1.61"
$TomcatHome = Join-Path $InstallDirectory "apache-tomcat-$TomcatVersion"
$ZipPath = Join-Path $InstallDirectory "tomcat.zip"

New-Item -ItemType Directory -Force -Path $InstallDirectory | Out-Null

# STEP 3: Download Tomcat
if (!(Test-Path "$TomcatHome\bin\startup.bat")) {

    Write-Host "`n3. Downloading Tomcat..."

    $DownloadUrl = "https://dlcdn.apache.org/tomcat/tomcat-10/v$TomcatVersion/bin/apache-tomcat-$TomcatVersion.zip"

    Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath

    # STEP 4: Extract
    Write-Host "`n4. Extracting Tomcat..."

    Expand-Archive -Path $ZipPath -DestinationPath $InstallDirectory -Force

    Remove-Item $ZipPath -Force
}
else {
    Write-Host "`nTomcat already downloaded."
}

# STEP 5: Configure environment
Write-Host "`n5. Configuring CATALINA_HOME..."

$env:CATALINA_HOME = $TomcatHome

[Environment]::SetEnvironmentVariable(
    "CATALINA_HOME",
    $TomcatHome,
    "User"
)

# STEP 6: Verify
Write-Host "`n6. Verifying installation..."

$RequiredFiles = @(
    "$TomcatHome\bin\startup.bat",
    "$TomcatHome\bin\shutdown.bat",
    "$TomcatHome\conf\server.xml"
)

foreach ($File in $RequiredFiles) {
    if (!(Test-Path $File)) {
        throw "Missing file: $File"
    }

    Write-Host "FOUND: $File" -ForegroundColor Green
}

# STEP 7: Check port
Write-Host "`n7. Checking port 8080..."

netstat -ano | findstr ":8080"

Write-Host "`n================================"
Write-Host "TOMCAT SETUP COMPLETED!" -ForegroundColor Green
Write-Host "Tomcat Home: $TomcatHome"
Write-Host "================================"
