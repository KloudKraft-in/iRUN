MIA-D2-202: JWT Audience Mismatch & SSL Certificate Expiry
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. Generate mobile client token:
     python starter/client_simulator.py
3. OBSERVED FAILURE:
     - Token has aud='retail-web-client', but gateway enforces aud='mobile-app-v2'.
     - SSL certificate on port 8443 has EXPIRED.

YOUR MISSION (Guidelines & Solve):
1. Update starter/gateway_auth_config.json to allow both audiences:
     "allowed_audiences": ["retail-web-client", "mobile-app-v2"]
2. Activate renewed certificate bundle in starter/certs/cert_metadata.json (set status to VALID).
3. Fill in starter/evidence/evidence_D2_2.md.
4. Run validation:
     .\validation_script.ps1   (Ubuntu: ./validation_script.sh)
===============================================================================
