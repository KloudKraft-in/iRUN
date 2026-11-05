#!/usr/bin/env python3
"""legacy-sync-daemon.py - stand-in for the legacy integration daemon that owns TCP 5055.
Started by `lab.sh start` (as the systemd unit 'legacy-sync-daemon'). It must keep running."""
import socket
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 5055


class DualStackServer(HTTPServer):
    address_family = socket.AF_INET6

    def server_bind(self):
        self.socket.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 0)  # also take IPv4
        super().server_bind()


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        body = b"LEGACY-SYNC-DAEMON OK\n"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


try:
    server = DualStackServer(("::", PORT), Handler)
except OSError:
    server = HTTPServer(("0.0.0.0", PORT), Handler)
server.serve_forever()
