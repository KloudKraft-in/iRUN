# Incident Evidence: MIA-D1-102 (Nginx 502 Bad Gateway)

- **Participant Name:** <<FILL_NAME>>
- **Date & Time:** <<FILL_TIMESTAMP>>

## 1. Upstream Log Error
```
<<FILL_EXACT_ERROR_LINE_FROM_NGINX_ERROR_LOG>>
```

## 2. Port Discovery
- Expected Upstream Port: <<FILL_ACTUAL_PORT_BACKEND_IS_LISTENING_ON>>
- Misconfigured Upstream Port: <<FILL_PORT_FOUND_IN_INITIAL_CONFIG>>

## 3. Configuration Diff
```nginx
<<PASTE_YOUR_FIXED_LOCATION_BLOCK_HERE>>
```

## 4. Header Preservation Justification
<<EXPLAIN_WHY_X_FORWARDED_FOR_AND_X_REAL_IP_ARE_CRITICAL>>
