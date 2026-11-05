# Day 2: Participant Incident Handbook
## Production Hosting, Identity, Dependency Injection & Performance

> **Your Role:** You are on duty during peak enterprise operations. A series of critical security and performance incidents have hit the retail platform. Your job is to fetch the scenario code, diagnose the issues, apply operational hardening, and optimize the system.

---

### Master Setup: Fetch Template Details
Before starting Day 2 tickets, clone the boilerplate repository onto your lab machine:

- **Execute in Terminal:**
```shell
git clone https://github.com/KloudKraft-in/iRUN.git
```
- **Access Boilerplate Files:**
  - Online Reference: `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/dotnet_app/day2/`
  - Local Lab Working Directory: `C:\Labs\` (Windows) or `/opt/labs/` (Ubuntu)

---

## Ticket 1: NET-D2-201 — "Website Dead With 503 After Password Change!"
* **Priority:** P2 (Production Outage)
* **Estimated Time:** 60–75 minutes
* **Scenario Path:** `D2-1/`

### Setup: Fetch template details
- **Execute:**
```shell
git clone https://github.com/KloudKraft-in/iRUN.git
```
- Navigate to `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/dotnet_app/day2/s1` to fetch boilerplate code.
- On your local lab VM, navigate to:
  ```powershell
  cd C:\Labs\D2-1
  # (Ubuntu: cd /opt/labs/D2-1)
  ```

### The Story (In Plain English)
Following a routine password rotation for service accounts, the main retail website is returning **HTTP 503 - Service Unavailable**. Starting the application pool manually works only until the next HTTP request, which causes it to crash and shut down again.

### What You See When You Start
1. Run `.\lab.ps1 start` (Ubuntu: `./lab.sh start`).
2. Run `curl.exe -i http://localhost:8080/`.
3. You receive an immediate `HTTP 503 Service Unavailable`. Check the app pool—it has stopped.

### Your Investigation Clues
* **Check WAS Event Logs:** Look in System Event Log under source `Microsoft-Windows-WAS`. Event 5021 indicates an invalid identity / logon failure, and Event 5059 indicates the pool was disabled by Rapid-Fail Protection.
* **The Root Cause:** The pool was configured with a static local account (`AppPoolSvc`) whose password was changed.
* **The Solution (Virtual Identity):** Migrate the pool to `ApplicationPoolIdentity`. This virtual account has no password to rotate and is managed automatically by Windows.
* **Grant Permissions:** Remember to grant `IIS AppPool\RetailPortalPool` Read & Execute permissions on `C:\inetpub\wwwroot\RetailPortal` using `icacls`.

### Your Goal
1. Save the WAS 5021/5059 event log to `evidence/was-events.txt`.
2. Migrate the application pool to `ApplicationPoolIdentity`.
3. Grant NTFS Read & Execute permissions to the virtual identity via `icacls`.
4. Configure operational hardening (1440 min recycling, 1 GB private memory limit, Rapid-Fail protection).
5. Start the pool and confirm both HTTP (8080) and HTTPS (8443) return HTTP 200 OK.
6. Validate with `.\lab.ps1 check` and clean up with `.\lab.ps1 reset`.

---

## Ticket 2: NET-D2-202 — "App Boots Up Fine, But Readiness Fails in Staging!"
* **Priority:** P3 (Release Blocker)
* **Estimated Time:** 60–75 minutes
* **Scenario Path:** `D2-2/`

### Setup: Fetch template details
- **Execute:**
```shell
git clone https://github.com/KloudKraft-in/iRUN.git
```
- Navigate to `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/dotnet_app/day2/s2` to fetch boilerplate code.
- On your local lab VM, navigate to:
  ```powershell
  cd C:\Labs\D2-2
  # (Ubuntu: cd /opt/labs/D2-2)
  ```

### The Story (In Plain English)
Order Service passes startup checks, and `/health/live` returns 200 OK. However, the readiness probe (`/health/ready`) throws HTTP 500. Additionally, security mandates require strict Kestrel body size limits and a self-contained single-file build.

### What You See When You Start
1. Run `.\lab.ps1 start` (Ubuntu: `./lab.sh start`).
2. `/health/live` returns 200 OK.
3. `/health/ready` returns 500 Internal Server Error.

### Your Investigation Clues
* **Why did it boot in Production?** ASP.NET Core disables DI scope and build validation in `Production` for performance.
* **Catch the error in Development:** Run the app with `ASPNETCORE_ENVIRONMENT=Development`. The startup crash will identify that `IDiscountRule` is missing from the container!
* **Kestrel Limits:** Configure `MaxRequestBodySize = 1048576` (1 MB) and `Http1AndHttp2` protocols in `Program.cs`.

### Your Goal
1. Register `builder.Services.AddScoped<IDiscountRule, TieredDiscountRule>()` in `OrderService/Program.cs`.
2. Add Kestrel limits and protocols in `Program.cs`.
3. Run `.\lab.ps1 restart` to recompile and relaunch the service.
4. Verify `/health/ready` returns 200, small POST returns 200, and 2 MB POST returns HTTP 413.
5. Publish a self-contained single-file build to `publish/`.
6. Save required evidence files and validate with `.\lab.ps1 check`.
7. Clean up: `.\lab.ps1 reset`.

---

## Ticket 3: NET-D2-203 — "Midday Traffic Spikes Cause Database Timeouts!"
* **Priority:** P2 (Intermittent Peak Outage)
* **Estimated Time:** 75–90 minutes
* **Scenario Path:** `D2-3/`

### Setup: Fetch template details
- **Execute:**
```shell
git clone https://github.com/KloudKraft-in/iRUN.git
```
- Navigate to `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/dotnet_app/day2/s3` to fetch boilerplate code.
- On your local lab VM, navigate to:
  ```powershell
  cd C:\Labs\D2-3
  # (Ubuntu: cd /opt/labs/D2-3)
  ```

### The Story (In Plain English)
During lunch rush traffic, customers experience checkout freezes. The log reports: *Timeout expired prior to obtaining a connection from the pool. Max pool size (100) was reached.* In addition, order summaries take several seconds to load.

### What You See When You Start
1. Run `.\lab.ps1 start` (Ubuntu: `./lab.sh start`).
2. Run `.\load-test.ps1 -Requests 500 -Concurrency 50`. The first 100 succeed, and then the remaining 400 fail!

### Your Investigation Clues
* **Find the connection leak:** Look at `PaymentApi/Services/DapperPaymentRepository.cs`. Is `SqlConnection` wrapped in a `using` statement? Notice the `AppDomain.ProcessExit` subscription keeping connections alive in memory forever!
* **Watch it live:** Monitor active connections using `dotnet-counters monitor -p <PID> --providers Microsoft.Data.SqlClient.EventSource`.
* **Fix the N+1 query:** In `PaymentApi/Services/OrderQueryService.cs`, replace the procedural loop with a single LINQ projection using `.Select(...)` and `.AsNoTracking()`.

### Your Goal
1. Wrap the connection in `await using var connection = new SqlConnection(...)` and remove the event hook in `DapperPaymentRepository.cs`.
2. Refactor `OrderQueryService.cs` so it executes only 1 SQL query (`queryCount <= 3`).
3. Run `.\lab.ps1 restart`.
4. Re-run `load-test.ps1` with 500 requests $\rightarrow$ verify **0 failures**.
5. Save metrics and diffs into `evidence/` and validate with `.\lab.ps1 check`.
6. Clean up: `.\lab.ps1 reset`.

