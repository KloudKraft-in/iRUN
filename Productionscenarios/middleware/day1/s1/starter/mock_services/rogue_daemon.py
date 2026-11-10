#!/usr/bin/env python3
import http.server
import socketserver
import sys

PORT = 8082

class RogueHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.end_headers()
        self.wfile.write(b"Rogue daemon process occupying port 8082\n")
    def log_message(self, format, *args):
        pass

if __name__ == '__main__':
    with socketserver.TCPServer(("", PORT), RogueHandler) as httpd:
        print(f"[ROGUE_DAEMON] Conflicting background process listening on port {PORT}")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass
