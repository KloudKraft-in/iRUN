#!/usr/bin/env python3
import base64
import json
import sys

# Sample Mobile JWT Token with mismatched audience
header = {"alg": "HS256", "typ": "JWT"}
payload = {
    "sub": "user_mobile_9941",
    "iss": "https://auth.retail.internal",
    "aud": "retail-web-client",   # Mismatch! Gateway expects 'mobile-app-v2'
    "exp": 1793232000,
    "role": "customer"
}

def make_token():
    h_b64 = base64.urlsafe_b64encode(json.dumps(header).encode()).decode().rstrip('=')
    p_b64 = base64.urlsafe_b64encode(json.dumps(payload).encode()).decode().rstrip('=')
    return f"{h_b64}.{p_b64}.dummy_signature_bytes_apex_cloud"

if __name__ == '__main__':
    token = make_token()
    print("[MOBILE CLIENT] Generated token:")
    print(token)
    print("\n[DECODED PAYLOAD]:")
    print(json.dumps(payload, indent=2))
