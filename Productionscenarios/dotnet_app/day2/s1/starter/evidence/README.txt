Save these three files here before you run validation (names are exact):

  was-events.txt   Windows: System-log WAS events (Event ID 5021/5059) exported with Get-WinEvent or wevtutil
                   Ubuntu : journalctl -u retailportal output that shows the 217/USER failure
  acl.txt          Windows: output of  icacls C:\inetpub\wwwroot\RetailPortal   (must list IIS AppPool\RetailPortalPool)
                   Ubuntu : output of  ls -l /opt/retailportal/app  and  systemctl cat retailportal
  pool-state.txt   Windows: Get-WebAppPoolState + the curl results for 8080 and 8443 (both 200)
                   Ubuntu : systemctl status retailportal + curl results for 8080 and 8443 (both 200)

