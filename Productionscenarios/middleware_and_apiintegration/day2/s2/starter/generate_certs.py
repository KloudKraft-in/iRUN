#!/usr/bin/env python3
# Helper to generate self-signed expired and valid certificate metadata
import datetime
import json

expired_meta = {
    "subject": "CN=api.retail.internal, O=Apex Cloud Retail, C=US",
    "issuer": "CN=Apex Cloud Retail CA",
    "not_before": "2025-10-01 00:00:00 UTC",
    "not_after": "2026-10-27 23:59:59 UTC",
    "status": "EXPIRED",
    "serial_number": "0x4A19B8E3120A"
}

renewed_meta = {
    "subject": "CN=api.retail.internal, O=Apex Cloud Retail, C=US",
    "issuer": "CN=Apex Cloud Retail CA",
    "not_before": "2026-10-28 00:00:00 UTC",
    "not_after": "2028-10-28 23:59:59 UTC",
    "status": "VALID",
    "serial_number": "0x4A19B8E399FF"
}

with open('certs/cert_metadata.json', 'w') as f:
    json.dump({"active": expired_meta, "renewed": renewed_meta}, f, indent=2)

print("[CERTS] Metadata written for expired and renewed certificates.")
