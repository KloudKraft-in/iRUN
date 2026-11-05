NET-D1-101: Orders API Port Conflict & Host Overrides
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. In Terminal 1, navigate to OrdersApi and run:
     cd starter/OrdersApi
     dotnet run --no-build
3. OBSERVED FAILURE:
     System.IO.IOException: Failed to bind to address http://localhost:5055: address already in use.
   Why this fails: Orders API configured port 5060 in appsettings.json, but a machine-level
   environment variable override (Kestrel__Endpoints__Http__Url) forces it to port 5055,
   which is actively occupied by a legacy sync daemon.

YOUR MISSION (Guidelines & Solve):
1. Locate and permanently remove the machine environment variable forcing port 5055:
     [Environment]::SetEnvironmentVariable('Kestrel__Endpoints__Http__Url', $null, 'Machine')
     [Environment]::SetEnvironmentVariable('Kestrel__Endpoints__Http__Url', $null, 'User')
     Remove-Item Env:\Kestrel__Endpoints__Http__Url -ErrorAction SilentlyContinue
2. Launch Orders API and verify it listens on http://localhost:5060.
3. Verify http://localhost:5060/health responds with 200 OK ("Healthy").
4. Update starter/evidence/evidence_D1_1.json with your findings.
5. Run validation:
     cd ..
     .\validation_script.ps1   (Ubuntu: ./validation_script.sh)
===============================================================================

