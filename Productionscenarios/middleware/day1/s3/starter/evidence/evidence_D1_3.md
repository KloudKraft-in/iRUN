# Incident Evidence: MIA-D1-103 (Kong Gateway Routing & Security)

- **Participant Name:** <<FILL_NAME>>
- **Date & Time:** <<FILL_TIMESTAMP>>

## 1. Route Discovery & Correction
- Initial Route Path: <<FILL_INITIAL_ROUTE_PATH>>
- Corrected Route Path: <<FILL_CORRECTED_ROUTE_PATH>>

## 2. Security Test Matrix

| Test Case | Request Header | Expected Status | Actual Status |
|---|---|---|---|
| No API Key | None | 401 Unauthorized | <<FILL>> |
| Invalid API Key | `apikey: bad-key` | 403 Forbidden | <<FILL>> |
| Valid API Key | `apikey: <<FILL_SECRET_KEY>>` | 200 OK | <<FILL>> |
| Rate Limit Exceeded (6th req) | `apikey: <<FILL_SECRET_KEY>>` | 429 Too Many Requests | <<FILL>> |

## 3. Kong Plugins Enabled
<<LIST_ENABLED_PLUGINS_AND_THEIR_ROLES>>
