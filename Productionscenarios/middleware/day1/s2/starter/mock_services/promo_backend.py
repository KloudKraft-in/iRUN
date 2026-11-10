#!/usr/bin/env python3
import http.server
import socketserver
import json
import sys

PORT = 8080

class PromoHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path in ['/promo', '/promo/']:
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Server', 'Retail-Promo-Engine/2.4')
            self.end_headers()
            data = {
                "campaign": "Fall Festive Sale 2026",
                "status": "ACTIVE",
                "discount_percent": 25,
                "promo_code": "FALL25"
            }
            self.wfile.write(json.dumps(data, indent=2).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()
    def log_message(self, format, *args):
        pass

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else PORT
    with socketserver.TCPServer(("", port), PromoHandler) as httpd:
        print(f"[PROMO_BACKEND] Service listening on http://127.0.0.1:{port}/promo")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass
