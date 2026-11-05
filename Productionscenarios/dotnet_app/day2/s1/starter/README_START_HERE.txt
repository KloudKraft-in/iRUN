NET-D2-201: IIS 503 Password Rotation & Virtual Identity
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. Test the site:
     curl.exe -i http://localhost:8080/
3. OBSERVED FAILURE:
     HTTP Error 503 - Service Unavailable
   Why this fails: The application pool was configured with a static service account (AppPoolSvc)
   whose password rotated. Five logon failures triggered Rapid-Fail Protection, disabling the pool.

YOUR MISSION (Guidelines & Solve):
1. Save the WAS 5021/5059 event log to starter/evidence/was-events.txt.
2. Migrate the application pool to ApplicationPoolIdentity (virtual account with no passwords):
     Import-Module WebAdministration
     Set-ItemProperty "IIS:\AppPools\RetailPortalPool" -Name processModel -Value @{ identityType = 4 }
3. Grant NTFS permissions to the virtual identity:
     icacls C:\inetpub\wwwroot\RetailPortal /grant "IIS AppPool\RetailPortalPool:(OI)(CI)RX" /T /Q
     icacls C:\inetpub\wwwroot\RetailPortal | Out-File starter\evidence\acl.txt
4. Configure operational hardening (recycling & rapid-fail protection) and start pool:
     Start-WebAppPool RetailPortalPool
5. Confirm HTTP (8080) and HTTPS (8443) return 200 OK.
6. Run validation:
     cd ..
     .\validation_script.ps1   (Ubuntu: ./validation_script.sh)
===============================================================================

