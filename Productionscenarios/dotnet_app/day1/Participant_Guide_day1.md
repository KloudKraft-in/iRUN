# Day 1: Participant Incident Handbook
## .NET Application Hosting, Configuration & Architecture

> **Your Role:** You are the on-call operations engineer at RetailCorp. Three urgent incident tickets have been assigned to you. Your goal is to fetch the starter code, reproduce each issue, investigate why it is happening, implement the fix, and verify it with the automated lab harness.

---

### Master Setup: Fetch Template Details
Before starting any ticket, clone the boilerplate repository onto your lab machine:

- **Execute in Terminal:**
```shell
git clone https://github.com/KloudKraft-in/iRUN.git
```
- **Access Boilerplate Files:**
  - Online Reference: `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/dotnet_app/day1/`
  - Local Lab Working Directory: `C:\Labs\` (Windows) or `/opt/labs/` (Ubuntu)

---

## Ticket 1: NET-D1-101 — "The API Won't Listen to Its Port!"
* **Priority:** P2 (Application is Down)
* **Estimated Time:** 45–60 minutes
* **Scenario Path:** `D1-1/`

### Setup: Fetch template details
- **Execute:**
```shell
git clone https://github.com/KloudKraft-in/iRUN.git
```
- Navigate to `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/dotnet_app/day1/s1` to fetch boilerplate code.
- On your local lab VM, navigate to:
  ```powershell
  cd C:\Labs\D1-1
  # (Ubuntu: cd /opt/labs/D1-1)
  ```

### The Story (In Plain English)
The developer configured the Orders API to run on **port 5060** in `appsettings.json`. But every time you attempt to launch it, it crashes with an error that **port 5055 is already in use**.

### What You See When You Start
1. Run `.\lab.ps1 start` (Ubuntu: `./lab.sh start`) to initialize the incident.
2. Go to `OrdersApi` and run `dotnet run --no-build`.
3. It fails with: `Failed to bind to address http://localhost:5055: address already in use`.

### Your Investigation Clues
* **Who is listening on port 5055?** Use network tools (`Get-NetTCPConnection` on Windows or `ss -ltnp` on Linux) to identify who holds 5055. *Crucial rule: Do NOT kill that process! It is a critical legacy daemon.*
* **Why does .NET try port 5055 if the config says 5060?**
  - Remember .NET configuration hierarchy: Environment Variables override `appsettings.json`!
  - Look for a Machine-level environment variable named `Kestrel__Endpoints__Http__Url`.
* **What about launchSettings.json?** That file has port 5070 in it, but `launchSettings.json` is development-only inside Visual Studio, not in deployed builds.

### Your Goal
1. Locate and permanently remove the machine environment variable forcing port 5055.
2. Launch Orders API and verify it says: `Now listening on: http://localhost:5060`.
3. Confirm `http://localhost:5060/health` responds with `Healthy`.
4. Update `evidence/evidence_D1_1.json` and run `.\lab.ps1 check` to validate.
5. Clean up when finished: `.\lab.ps1 reset`.

---

## Ticket 2: NET-D1-102 — "Website Shows Error 502.5 After Settings Change"
* **Priority:** P2 (Customers Facing Outage)
* **Estimated Time:** 60–75 minutes
* **Scenario Path:** `D1-2/`

### Setup: Fetch template details
- **Execute:**
```shell
git clone https://github.com/KloudKraft-in/iRUN.git
```
- Navigate to `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/dotnet_app/day1/s2` to fetch boilerplate code.
- On your local lab VM, navigate to:
  ```powershell
  cd C:\Labs\D1-2
  # (Ubuntu: cd /opt/labs/D1-2)
  ```

### The Story (In Plain English)
Your team reconfigured the Customer Portal on IIS from "In-Process" to "Out-of-Process" hosting to isolate worker crashes. But immediately upon saving `web.config`, the website returned **HTTP Error 502.5 - Process Failure**. (On Ubuntu: Nginx shows **502 Bad Gateway**).

### What You See When You Start
1. Run `.\lab.ps1 start` (Ubuntu: `./lab.sh start`).
2. Run `curl.exe -i http://localhost:8080/`.
3. You receive an `HTTP 502.5` error page.

### Your Investigation Clues
* **Where is the crash log?** Check Windows **Event Viewer** $\rightarrow$ **Application Log** under the source `IIS AspNetCore Module V2`. Event 1010 reveals the exact missing process command line!
* **Enable stdout logging:** In `C:\inetpub\wwwroot\CustomerPortal\web.config`, change `stdoutLogEnabled="false"` to `"true"` to log startup crashes directly to disk.
* **Inspect the DLL name:** Look at the `arguments` attribute inside `web.config`. Is the DLL filename spelled correctly?

### Your Goal
1. Export the ANCM failure event to `evidence/eventlog-export.txt`.
2. Fix `web.config` so it points to the correct DLL, while **strictly keeping `hostingModel="OutOfProcess"`**!
3. Restart the application pool (`Restart-WebAppPool RetailCustomerPortalPool`).
4. Verify `http://localhost:8080/` returns HTTP 200 and `/whoami` shows `processName: "dotnet"`.
5. Complete `evidence/process-comparison.md` and validate with `.\lab.ps1 check`.
6. Clean up: `.\lab.ps1 reset`.

---

## Ticket 3: NET-D1-103 — "Staging Background Service Keeps Stopping"
* **Priority:** P3 (Pre-production Blocker)
* **Estimated Time:** 60–75 minutes
* **Scenario Path:** `D1-3/`

### Setup: Fetch template details
- **Execute:**
```shell
git clone https://github.com/KloudKraft-in/iRUN.git
```
- Navigate to `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/dotnet_app/day1/s3` to fetch boilerplate code.
- On your local lab VM, navigate to:
  ```powershell
  cd C:\Labs\D1-3
  # (Ubuntu: cd /opt/labs/D1-3)
  ```

### The Story (In Plain English)
A background worker service (`InvoiceSyncService`) deployed to a staging VM crashes immediately after startup (Status: Stopped).

### What You See When You Start
1. Run `.\lab.ps1 start` (Ubuntu: `./lab.sh start`).
2. Run `Get-Service InvoiceSyncService` $\rightarrow$ Status is `Stopped`.
3. Try starting it with `Start-Service InvoiceSyncService`. Check 3 seconds later—it has crashed again!

### Your Investigation Clues
* **Why did it crash?** Check the Application Event Log for `InvoiceSyncService`. Look for `OptionsValidationException: ERP ConnectionString is required`.
* **Why is the connection string missing?** Look at `appsettings.json` versus `appsettings.Staging.json`. The connection string is in Staging, but the default file is blank!
* **Why did it ignore Staging?**
  - Check the registry environment block: `Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\InvoiceSyncService -Name Environment`.
  - It was set to `ASPNETCORE_ENVIRONMENT=Staging`.
  - But InvoiceSync is a **Generic Host Worker Service** (`Host.CreateApplicationBuilder`)! Generic Hosts completely ignore `ASPNETCORE_*` and only resolve `DOTNET_ENVIRONMENT`!

### Your Goal
1. Update the service environment in the registry to `DOTNET_ENVIRONMENT=Staging`.
2. Start the service and confirm it stays `Running` after 5 seconds.
3. Verify heartbeat messages in `Logs\invoice_sync.log` show `Environment: Staging`.
4. Complete `evidence/evidence_D1_3.md` and validate with `.\lab.ps1 check`.
5. Clean up: `.\lab.ps1 reset`.

