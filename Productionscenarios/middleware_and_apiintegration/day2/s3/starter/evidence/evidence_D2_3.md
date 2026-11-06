# Incident Evidence: MIA-D2-203 (Distributed Timeout Chain Repair)

- **Participant Name:** <<FILL_NAME>>
- **Date & Time:** <<FILL_TIMESTAMP>>

## 1. Multi-Hop Trace Analysis

| Hop / Component | Configured / Observed Timeout | Observed Behavior |
|---|---|---|
| Edge Gateway (Kong) | <<FILL_TIMEOUT>> | <<FILL_STATUS_RETURNED_TO_CLIENT>> |
| Reverse Proxy (Nginx) | <<FILL_TIMEOUT>> | <<FILL_STATUS_IN_ACCESS_LOG>> |
| Backend Microservice | <<FILL_EXECUTION_TIME>> | <<FILL_FINAL_TRANSACTION_STATUS>> |

## 2. Root Cause Explanation (The "Ghost Order" Mystery)
<<EXPLAIN_WHY_THE_CUSTOMER_SAW_A_504_TIMEOUT_BUT_THE_PAYMENT_WENT_THROUGH>>

## 3. Corrected Timeout Hierarchy
- Kong `read_timeout`: <<FILL_TIMEOUT_MS>>
- Nginx `proxy_read_timeout`: <<FILL_TIMEOUT_SEC>>
- Microservice internal execution SLA: <<FILL_TIMEOUT_SEC>>

## 4. Architectural Recommendations
<<LIST_2_ARCHITECTURAL_SAFEGUARDS_TO_PREVENT_GHOST_TRANSACTIONS>>
