NET-D1-102: IIS ANCM 502.5 Out-of-Process Failure
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. Attempt to browse the site:
     curl.exe -i http://localhost:8080/
3. OBSERVED FAILURE:
     HTTP Error 502.5 - Process Failure / ANCM Out-Of-Process Startup Failure
   Why this fails: The team reconfigured Customer Portal from In-Process to Out-of-Process
   hosting in web.config, but the arguments attribute pointed to a misspelled DLL filename.

YOUR MISSION (Guidelines & Solve):
1. Export the ANCM failure event to starter/evidence/eventlog-export.txt:
     Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='IIS AspNetCore Module V2'} -MaxEvents 5 |
       Format-List TimeCreated, Id, Message | Out-File starter\evidence\eventlog-export.txt -Width 250
2. Fix web.config in C:\inetpub\wwwroot\CustomerPortal\web.config so arguments points to
   CustomerPortal.dll, strictly keeping hostingModel="OutOfProcess".
3. Save a copy of your corrected web.config into starter/evidence/web.config.
4. Restart the IIS application pool:
     Restart-WebAppPool RetailCustomerPortalPool
5. Verify http://localhost:8080/ returns 200 OK and /whoami shows processName: "dotnet".
6. Complete starter/evidence/process-comparison.md.
7. Run validation:
     cd ..
     .\validation_script.ps1   (Ubuntu: ./validation_script.sh)
===============================================================================

