#!/usr/bin/env python3
import http.server
import socketserver
import threading
import json
import urllib.request
import time
from collections import defaultdict

# In-memory Gateway state
state = {
    "routes": {
        "inventory-route": {
            "name": "inventory-route",
            "paths": ["/v1/inventory"],
            "strip_path": False,
            "service": "inventory-service"
        }
    },
    "services": {
        "inventory-service": {
            "name": "inventory-service",
            "url": "http://127.0.0.1:8081"
        }
    },
    "plugins": {},
    "consumers": {},
    "api_keys": {}
}

rate_limit_tracker = defaultdict(list)

# --- Kong Admin API (Port 8001) ---
class KongAdminHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith('/routes'):
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"data": list(state["routes"].values())}).encode('utf-8'))
        elif self.path.startswith('/plugins'):
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"data": list(state["plugins"].values())}).encode('utf-8'))
        else:
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"version": "3.4.0", "tagline": "Welcome to Kong"}')

    def do_PATCH(self):
        length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(length).decode('utf-8')
        if '/routes/inventory-route' in self.path:
            route = state["routes"]["inventory-route"]
            if 'paths[]=' in body or 'paths=' in body:
                if '/api/v1/inventory' in body:
                    route["paths"] = ["/api/v1/inventory"]
            if 'strip_path=false' in body.lower():
                route["strip_path"] = False
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(route).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(length).decode('utf-8')
        if '/plugins' in self.path:
            p_name = 'key-auth' if 'key-auth' in body else ('rate-limiting' if 'rate-limiting' in body else 'unknown')
            state["plugins"][p_name] = {"name": p_name, "enabled": True}
            self.send_response(201)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"name": p_name, "id": f"plug-{p_name}"}).encode('utf-8'))
        elif '/consumers' in self.path and 'key-auth' not in self.path:
            c_name = 'partner-logistics'
            state["consumers"][c_name] = {"username": c_name}
            self.send_response(201)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"username": c_name, "id": "cons-1"}).encode('utf-8'))
        elif '/key-auth' in self.path:
            key = 'LogisticsSecretKey2026'
            state["api_keys"][key] = "partner-logistics"
            self.send_response(201)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"key": key, "consumer": "partner-logistics"}).encode('utf-8'))
        else:
            self.send_response(200)
            self.end_headers()
    def log_message(self, format, *args):
        pass

# --- Kong Proxy (Port 8000) ---
class KongProxyHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        matched = False
        for r_name, r in state["routes"].items():
            for p in r["paths"]:
                if self.path.startswith(p):
                    matched = True
                    break
        if not matched:
            self.send_response(404)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Server', 'kong/3.4.0')
            self.end_headers()
            self.wfile.write(b'{"message": "no Route matched with those values"}')
            return

        # Plugin 1: key-auth
        if "key-auth" in state["plugins"]:
            apikey = self.headers.get('apikey')
            if not apikey:
                self.send_response(401)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Server', 'kong/3.4.0')
                self.end_headers()
                self.wfile.write(b'{"message": "No API key found in request"}')
                return
            if apikey not in state["api_keys"]:
                self.send_response(403)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Server', 'kong/3.4.0')
                self.end_headers()
                self.wfile.write(b'{"message": "Invalid authentication credentials"}')
                return

        # Plugin 2: rate-limiting (5 req/min)
        if "rate-limiting" in state["plugins"]:
            now = time.time()
            client_id = self.headers.get('apikey', 'anon')
            timestamps = rate_limit_tracker[client_id]
            rate_limit_tracker[client_id] = [t for t in timestamps if now - t < 60]
            if len(rate_limit_tracker[client_id]) >= 5:
                self.send_response(429)
                self.send_header('Content-Type', 'application/json')
                self.send_header('X-RateLimit-Limit-Minute', '5')
                self.send_header('X-RateLimit-Remaining-Minute', '0')
                self.send_header('Server', 'kong/3.4.0')
                self.end_headers()
                self.wfile.write(b'{"message": "API rate limit exceeded"}')
                return
            rate_limit_tracker[client_id].append(now)

        # Forward to upstream
        try:
            req = urllib.request.Request(f"http://127.0.0.1:8081{self.path}")
            with urllib.request.urlopen(req) as resp:
                self.send_response(resp.status)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Server', 'kong/3.4.0')
                self.send_header('X-RateLimit-Limit-Minute', '5')
                self.send_header('X-RateLimit-Remaining-Minute', str(5 - len(rate_limit_tracker.get(self.headers.get('apikey', ''), []))))
                self.end_headers()
                self.wfile.write(resp.read())
        except urllib.error.HTTPError as e:
            self.send_response(e.code)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Server', 'kong/3.4.0')
            self.end_headers()
            self.wfile.write(e.read())
        except Exception:
            self.send_response(502)
            self.send_header('Server', 'kong/3.4.0')
            self.end_headers()
            self.wfile.write(b'{"message": "An invalid response was received from the upstream server"}')
    def log_message(self, format, *args):
        pass

def run_admin():
    with socketserver.TCPServer(("", 8001), KongAdminHandler) as httpd:
        httpd.serve_forever()

def run_proxy():
    with socketserver.TCPServer(("", 8000), KongProxyHandler) as httpd:
        httpd.serve_forever()

if __name__ == '__main__':
    t1 = threading.Thread(target=run_admin, daemon=True)
    t2 = threading.Thread(target=run_proxy, daemon=True)
    t1.start()
    t2.start()
    print("[KONG GATEWAY] Running Admin API on port 8001 and Proxy on port 8000")
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        pass
