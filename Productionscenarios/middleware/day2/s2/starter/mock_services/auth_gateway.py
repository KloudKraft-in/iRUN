#!/usr/bin/env python3
import http.server
import socketserver
import json
import base64
import sys

CONFIG_FILE = "gateway_auth_config.json"

class AuthGatewayHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # 1. Check SSL Certificate status
        with open('certs/cert_metadata.json', 'r') as f:
            certs = json.load(f)
        if certs['active']['status'] == 'EXPIRED':
            self.send_response(525)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"error": "SSL Handshake Failed: Certificate Expired (verify error:num=10)"}')
            return

        # 2. Check JWT Authorization Header
        auth_hdr = self.headers.get('Authorization', '')
        if not auth_hdr.startswith('Bearer '):
            self.send_response(401)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"error": "Missing or malformed Authorization header"}')
            return

        token = auth_hdr.replace('Bearer ', '').strip()
        parts = token.split('.')
        if len(parts) < 2:
            self.send_response(401)
            self.end_headers()
            self.wfile.write(b'{"error": "Invalid token format"}')
            return

        try:
            # Add padding
            rem = len(parts[1]) % 4
            p_b64 = parts[1] + ('=' * (4 - rem) if rem else '')
            claims = json.loads(base64.urlsafe_b64decode(p_b64).decode())
        except Exception as e:
            self.send_response(401)
            self.end_headers()
            self.wfile.write(f'{{"error": "Corrupt token claims: {e}"}}'.encode())
            return

        # Read Gateway Config
        with open(CONFIG_FILE, 'r') as f:
            cfg = json.load(f)
            
        allowed_audiences = cfg.get("allowed_audiences", ["mobile-app-v2"])
        token_aud = claims.get("aud")

        if token_aud not in allowed_audiences:
            self.send_response(401)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({
                "error": "Unauthorized",
                "reason": f"Audience claim mismatch: token has '{token_aud}', gateway requires one of {allowed_audiences}"
            }).encode())
            return

        # Success
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({
            "status": "AUTHENTICATED",
            "user_id": claims.get("sub"),
            "profile": {
                "name": "Apex Mobile Shopper",
                "status": "VIP Tier 1"
            }
        }).encode())
    def log_message(self, format, *args):
        pass

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8443
    with socketserver.TCPServer(("", port), AuthGatewayHandler) as httpd:
        print(f"[AUTH GATEWAY] Gateway listening on port {port}")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass
