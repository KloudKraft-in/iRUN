NET-D1-103: Staging Background Service Keeps Stopping
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. Query the service status:
     Get-Service InvoiceSyncService   (Ubuntu: systemctl status invoicesync)
3. OBSERVED FAILURE:
     Status is Stopped (or failed with exit code 1).
   Why this fails: InvoiceSync is a Generic Host (Host.CreateApplicationBuilder).
   Generic Host ignores ASPNETCORE_ENVIRONMENT and only resolves DOTNET_ENVIRONMENT!
   Defaulting to Production caused an OptionsValidationException due to missing connection string.

YOUR MISSION (Guidelines & Solve):
1. Check the Application Event Log for the OptionsValidationException.
2. Update the service environment to DOTNET_ENVIRONMENT=Staging:
     Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\InvoiceSyncService' -Name Environment -Value @('DOTNET_ENVIRONMENT=Staging')
     Start-Service InvoiceSyncService
3. Verify heartbeat messages in starter/InvoiceSync/Logs/invoice_sync.log show Environment: Staging.
4. Complete starter/evidence/evidence_D1_3.md.
5. Run validation:
     cd ..
     .\validation_script.ps1   (Ubuntu: ./validation_script.sh)
===============================================================================

