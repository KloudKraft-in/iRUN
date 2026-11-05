# Day 1: Instructor Solution Guide & Coaching Manual
## .NET Application Hosting, Configuration & Architecture (Module 1)

*(Instructor & Mentor Reference Only — Do Not Distribute Directly to Students)*

---

### Master Setup: Fetch Template Details
To clone or inspect the official starter boilerplate repository:

- **Execute:**
```shell
git clone https://github.com/KloudKraft-in/iRUN.git
```
- **Access Boilerplate Files:**
  - Day 1 Root: `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/dotnet_app/day1/`
  - Local Working Directory: `iRUN\Productionscenarios\dotnet_app\day1\` (Windows) or `iRUN/Productionscenarios/dotnet_app/day1/` (Ubuntu)

---

## Ticket NET-D1-101: Orders API Port Conflict (60 min)

### Setup: Fetch template details
- **Execute:**
```shell
git clone https://github.com/KloudKraft-in/iRUN.git
```
- Boilerplate Path: `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/dotnet_app/day1/s1`
- Local Working Directory: `iRUN\Productionscenarios\dotnet_app\day1\s1` (Ubuntu: `iRUN/Productionscenarios/dotnet_app/day1/s1`)

### 1. Root Cause Analysis (RCA)
- The Orders API configured port 5060 in `appsettings.json`. However, a machine-level environment variable `Kestrel__Endpoints__Http__Url=http://localhost:5055` was set on the host.
- In .NET configuration hierarchy:
  $$\text{CLI Args} > \text{Environment Variables} > \text{appsettings.json} > \text{launchSettings.json}$$
  The machine variable takes precedence. Port 5055 is actively held by `legacy-sync-daemon`, resulting in `System.IO.IOException`.

### 2. Step-by-Step Solution Path
1. Run `.\validation_script.ps1 start` to inject the fault and start the daemon.
2. Remove the machine variable:
   ```powershell
   [Environment]::SetEnvironmentVariable('Kestrel__Endpoints__Http__Url', $null, 'Machine')
   [Environment]::SetEnvironmentVariable('Kestrel__Endpoints__Http__Url', $null, 'User')
   Remove-Item Env:\Kestrel__Endpoints__Http__Url -ErrorAction SilentlyContinue
   ```
   *(Ubuntu: `sudo sed -i '/Kestrel__Endpoints__Http__Url/d' /etc/environment && unset Kestrel__Endpoints__Http__Url`)*
3. In `starter/OrdersApi`, run `dotnet run --no-build` $\rightarrow$ binds to `http://localhost:5060`.
4. Update `starter/evidence/evidence_D1_1.json`.
5. Run `.\validation_script.ps1` (or `.\validation_script.ps1 check`) $\rightarrow$ 10/10 PASS.

### 3. Grading Rubric (10 Points)
- Daemon on 5055 untouched: 2 pts
- OrdersApi listening on 5060 + Health 200: 2 pts
- Permanent machine variable removal: 2 pts
- Correct identification of variable name and scope: 2 pts
- Root cause explanation: 2 pts

---

## Ticket NET-D1-102: IIS ANCM 502.5 Out-of-Process Failure (75 min)

### Setup: Fetch template details
- **Execute:**
```shell
git clone https://github.com/KloudKraft-in/iRUN.git
```
- Boilerplate Path: `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/dotnet_app/day1/s2`
- Local Working Directory: `iRUN\Productionscenarios\dotnet_app\day1\s2` (Ubuntu: `iRUN/Productionscenarios/dotnet_app/day1/s2`)

### 1. Root Cause Analysis (RCA)
- In `C:\inetpub\wwwroot\CustomerPortal\web.config`, `arguments` was set to `.\CustomerPortalMisspelled.dll`.
- In Out-of-Process hosting, ANCM spawns `dotnet.exe` to run the app. Because the DLL was missing, the child process crashed immediately with exit code `0x80004005`, returning HTTP 502.5.

### 2. Step-by-Step Solution Path
1. Run `.\validation_script.ps1 start`.
2. Export Event ID 1010 to `starter\evidence\eventlog-export.txt`:
   ```powershell
   Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='IIS AspNetCore Module V2'} -MaxEvents 5 | 
       Format-List TimeCreated, Id, Message | Out-File starter\evidence\eventlog-export.txt -Width 250
   ```
3. Update `web.config` to `arguments=".\CustomerPortal.dll"`, keeping `hostingModel="OutOfProcess"`.
4. Copy `web.config` to `starter\evidence\web.config`.
5. Restart pool: `Restart-WebAppPool RetailCustomerPortalPool`.
6. Complete `starter\evidence\process-comparison.md`.
7. Run `.\validation_script.ps1` (or `.\validation_script.ps1 check`) $\rightarrow$ 10/10 PASS.

### 3. Grading Rubric (10 Points)
- Diagnosed root cause via logs / stdout: 3 pts
- Repaired DLL argument while preserving OutOfProcess: 2 pts
- Event log export saved: 1 pt
- Corrected `web.config` saved: 1 pt
- Process comparison table completed: 2 pts
- Written architectural trade-off explanation: 1 pt

---

## Ticket NET-D1-103: Staging Worker Service Environment Scoping (75 min)

### Setup: Fetch template details
- **Execute:**
```shell
git clone https://github.com/KloudKraft-in/iRUN.git
```
- Boilerplate Path: `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/dotnet_app/day1/s3`
- Local Working Directory: `iRUN\Productionscenarios\dotnet_app\day1\s3` (Ubuntu: `iRUN/Productionscenarios/dotnet_app/day1/s3`)

### 1. Root Cause Analysis (RCA)
- `InvoiceSync` uses .NET Generic Host (`Host.CreateApplicationBuilder`).
- The Generic Host only resolves `DOTNET_ENVIRONMENT`. The registry had `ASPNETCORE_ENVIRONMENT=Staging`, which Generic Host ignored.
- The service defaulted to `Production`, where `ErpSettings:ConnectionString` is blank, triggering an `OptionsValidationException` during `ValidateOnStart()`.

### 2. Step-by-Step Solution Path
1. Run `.\validation_script.ps1 start`.
2. Configure the registry environment:
   ```powershell
   Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\InvoiceSyncService' -Name Environment -Value @('DOTNET_ENVIRONMENT=Staging')
   Start-Service InvoiceSyncService
   ```
3. Verify heartbeat log in `starter\Logs\invoice_sync.log`.
4. Fill in `starter\evidence\evidence_D1_3.md`.
5. Run `.\validation_script.ps1` (or `.\validation_script.ps1 check`) $\rightarrow$ 10/10 PASS.

### 3. Grading Rubric (10 Points)
- Captured original exception: 2 pts
- Explanation of Generic Host vs Web Host: 3 pts
- Service environment correctly set to `DOTNET_ENVIRONMENT`: 3 pts
- Verified sustained running state + heartbeat: 2 pts
