# Day 2: Instructor Solution Guide & Coaching Manual
## Production Hosting, Identity, Dependency Injection & Performance (Module 2)

*(Instructor & Mentor Reference Only — Do Not Distribute Directly to Students)*

---

### Master Setup: Fetch Template Details
To clone or inspect the official starter boilerplate repository:

- **Execute:**
```shell
git clone https://github.com/KloudKraft-in/iRUN.git
```
- **Access Boilerplate Files:**
  - Day 2 Root: `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/dotnet_app/day2/`
  - Local Working Directory: `iRUN\Productionscenarios\dotnet_app\day2\` (Windows) or `iRUN/Productionscenarios/dotnet_app/day2/` (Ubuntu)

---

## Ticket NET-D2-201: IIS 503 Password Rotation & Virtual Identity (75 min)

### Setup: Fetch template details
- **Execute:**
```shell
git clone https://github.com/KloudKraft-in/iRUN.git
```
- Boilerplate Path: `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/dotnet_app/day2/s1`
- Local Working Directory: `iRUN\Productionscenarios\dotnet_app\day2\s1` (Ubuntu: `iRUN/Productionscenarios/dotnet_app/day2/s1`)

### 1. Root Cause Analysis (RCA)
- The Application Pool was configured to run under a local account (`AppPoolSvc`). An automated password rotation invalidated the password stored in IIS.
- WAS failed to log on the worker process (Event 5021). Five failures in five minutes triggered Rapid-Fail Protection (Event 5059), disabling the pool and returning HTTP 503.

### 2. Step-by-Step Solution Path
1. Run `.\validation_script.ps1 start`.
2. Migrate pool to `ApplicationPoolIdentity`:
   ```powershell
   Import-Module WebAdministration
   $Pool = 'RetailPortalPool'; $Site = 'C:\inetpub\wwwroot\RetailPortal'; $P = "IIS:\AppPools\$Pool"
   Set-ItemProperty $P -Name processModel -Value @{ identityType = 4 }
   Set-ItemProperty $P -Name processModel.userName -Value ''
   Set-ItemProperty $P -Name processModel.password -Value ''
   ```
3. Grant virtual account NTFS permissions:
   ```powershell
   icacls $Site /grant "IIS AppPool\$($Pool):(OI)(CI)RX" /T /Q
   icacls $Site | Out-File starter\evidence\acl.txt
   ```
4. Configure hardening (recycle every 24h, 1 GB memory limit, 5 crashes / 5 min rapid fail):
   ```powershell
   Set-ItemProperty $P -Name recycling.periodicRestart.time -Value ([TimeSpan]'1.00:00:00')
   Set-ItemProperty $P -Name recycling.periodicRestart.privateMemory -Value 1048576
   Set-ItemProperty $P -Name failure.rapidFailProtectionMaxCrashes -Value 5
   Set-ItemProperty $P -Name failure.rapidFailProtectionInterval -Value ([TimeSpan]'00:05:00')
   Start-WebAppPool $Pool
   ```
5. Save verification status to `starter\evidence\pool-state.txt`.
6. Run `.\validation_script.ps1` (or `.\validation_script.ps1 check`) $\rightarrow$ 10/10 PASS.

### 3. Grading Rubric (10 Points)
- Identified WAS 5021/5059 root cause: 2 pts
- Migrated to `ApplicationPoolIdentity`: 3 pts
- Granted least-privilege folder ACLs via icacls: 2 pts
- Configured recycling & rapid-fail protection: 2 pts
- Both HTTP (8080) and HTTPS (8443) return 200: 1 pt

---

## Ticket NET-D2-202: DI Scope Validation, Kestrel Limits & Single-File (75 min)

### Setup: Fetch template details
- **Execute:**
```shell
git clone https://github.com/KloudKraft-in/iRUN.git
```
- Boilerplate Path: `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/dotnet_app/day2/s2`
- Local Working Directory: `iRUN\Productionscenarios\dotnet_app\day2\s2` (Ubuntu: `iRUN/Productionscenarios/dotnet_app/day2/s2`)

### 1. Root Cause Analysis (RCA)
- `OrderProcessor` depends on `IDiscountRule`. However, `IDiscountRule` was not registered in the DI container.
- Because `ValidateScopes` and `ValidateOnBuild` are false in Production, the app booted cleanly. The readiness probe (`/health/ready`) resolved `OrderProcessor`, triggering a runtime `InvalidOperationException`.

### 2. Step-by-Step Solution Path
1. Run `.\validation_script.ps1 start`.
2. In `starter/OrderService/Program.cs`, add:
   ```csharp
   builder.Services.AddScoped<IDiscountRule, TieredDiscountRule>();
   builder.WebHost.ConfigureKestrel(options => {
       options.Limits.MaxRequestBodySize = 1_048_576; // 1 MB
       options.Limits.RequestHeadersTimeout = TimeSpan.FromSeconds(15);
       options.ConfigureEndpointDefaults(listen => listen.Protocols = HttpProtocols.Http1AndHttp2);
   });
   ```
3. Restart via harness: `.\validation_script.ps1 restart`.
4. Publish self-contained single-file build:
   ```powershell
   cd starter\OrderService
   dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o publish
   cd ..\..
   ```
5. Save required evidence files in `starter\evidence\`.
6. Run `.\validation_script.ps1` (or `.\validation_script.ps1 check`) $\rightarrow$ 10/10 PASS.

### 3. Grading Rubric (10 Points)
- Repaired DI registration: 3 pts
- Configured Kestrel request body limit: 2 pts
- Proved 2 MB payload rejection (HTTP 413): 2 pts
- Produced self-contained single-file build (> 20 MB): 2 pts
- Complete evidence logs: 1 pt

---

## Ticket NET-D2-203: Connection Pool Leak & EF Core N+1 Query (90 min)

### Setup: Fetch template details
- **Execute:**
```shell
git clone https://github.com/KloudKraft-in/iRUN.git
```
- Boilerplate Path: `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/dotnet_app/day2/s3`
- Local Working Directory: `iRUN\Productionscenarios\dotnet_app\day2\s3` (Ubuntu: `iRUN/Productionscenarios/dotnet_app/day2/s3`)

### 1. Root Cause Analysis (RCA)
- **Connection Leak:** `DapperPaymentRepository` opened `SqlConnection` without `using`. An event handler attached to `AppDomain.ProcessExit` created a root reference in the GC. After 100 requests, the pool was exhausted.
- **EF Core N+1:** `OrderQueryService` executed loops with two secondary database queries per order, generating ~401 queries.

### 2. Step-by-Step Solution Path
1. Run `.\validation_script.ps1 start`.
2. In `starter/PaymentApi/Services/DapperPaymentRepository.cs`, wrap connection in `await using` and delete `ProcessExit` hook:
   ```csharp
   await using var connection = new SqlConnection(_connectionString);
   await connection.OpenAsync();
   ```
3. In `starter/PaymentApi/Services/OrderQueryService.cs`, replace loop with a single LINQ projection (`AsNoTracking()`).
4. Restart via harness: `.\validation_script.ps1 restart`.
5. Run load test:
   ```powershell
   cd starter
   .\load-test.ps1 -Requests 500 -Concurrency 50
   cd ..
   ```
   $\rightarrow$ 0 failures.
6. Save evidence files in `starter\evidence\`.
7. Run `.\validation_script.ps1` (or `.\validation_script.ps1 check`) $\rightarrow$ 10/10 PASS.

### 3. Grading Rubric (10 Points)
- Connection leak diagnosed with counters / dump: 3 pts
- Proper disposal implemented via `using`: 2 pts
- EF Core N+1 query eliminated (`queryCount <= 3`): 2 pts
- Load test passing with 0 failures: 1 pt
- Evidence files present and verified: 2 pts
