# Incident Evidence: MIA-D2-202 (JWT Audience & SSL Handshake Repair)

- **Participant Name:** <<FILL_NAME>>
- **Date & Time:** <<FILL_TIMESTAMP>>

## 1. Decoded JWT Payload Analysis
```json
<<PASTE_DECODED_JWT_PAYLOAD>>
```

- Target Audience in Token (`aud`): <<FILL_TOKEN_AUDIENCE>>
- Audience Allowed by Gateway: <<FILL_GATEWAY_INITIAL_AUDIENCE>>

## 2. Certificate Inspection Findings
- Subject Common Name (CN): <<FILL_CN>>
- Expiry Date on Old Certificate: <<FILL_EXPIRY_DATE>>
- New Certificate Expiry Date: <<FILL_NEW_EXPIRY_DATE>>

## 3. Verification Curl Output
```
<<PASTE_SUCCESSFUL_CURL_RESPONSE_HERE>>
```
