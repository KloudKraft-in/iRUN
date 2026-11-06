#!/usr/bin/env python3
import http.server
import socketserver
import json
import sys

PORT = 8080

class CatalogHandler(http.server.SimpleHTTPRequestHandler):
    def do_HEAD(self):
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Server', 'Apache-Tomcat/10.1.18')
        self.end_headers()

    def do_GET(self):
        if self.path in ['/catalog', '/catalog/']:
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Server', 'Apache-Tomcat/10.1.18')
            self.end_headers()
            payload = {
                "status": "UP",
                "application": "Apex Retail Catalog Service",
                "service": "Tomcat-Catalog-Engine",
                "items_count": 14850
            }
            self.wfile.write(json.dumps(payload, indent=2).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        pass

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else PORT
    with socketserver.TCPServer(("", port), CatalogHandler) as httpd:
        print(f"[TOMCAT CATALOG] Service active and listening on http://localhost:{port}/catalog")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass
