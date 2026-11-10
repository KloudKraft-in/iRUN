#!/usr/bin/env python3
import http.server
import socketserver
import json
import sys

PORT = 8081

class InventoryHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/api/v1/inventory' or self.path == '/api/v1/inventory/':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            data = {
                "warehouse": "Regional Logistics DC-East",
                "sku_items": [
                    {"sku": "SKU-9921", "qty": 140, "status": "AVAILABLE"},
                    {"sku": "SKU-4412", "qty": 85,  "status": "AVAILABLE"},
                    {"sku": "SKU-1102", "qty": 0,   "status": "OUT_OF_STOCK"}
                ]
            }
            self.wfile.write(json.dumps(data, indent=2).encode('utf-8'))
        elif self.path == '/api/v1/inventory/crash':
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"error": "Internal Database Connection Timeout", "tier": "Backend-DB"}).encode('utf-8'))
        else:
            self.send_response(404)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"error": "Resource Not Found"}).encode('utf-8'))
    def log_message(self, format, *args):
        pass

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else PORT
    with socketserver.TCPServer(("", port), InventoryHandler) as httpd:
        print(f"[INVENTORY BACKEND] Upstream microservice listening on port {port}")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass
