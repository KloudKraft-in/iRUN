#!/usr/bin/env python3
import http.server
import socketserver
import time
import json
import sys

PORT = 8085

class SlowCheckoutHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        req_id = self.headers.get('X-Request-ID', 'req-unknown')
        print(f"[{time.strftime('%X')}] [BACKEND] Received checkout request {req_id}. Processing external payment gateway...")
        
        # Payment gateway takes 5.2 seconds to verify funds and finalize debit
        time.sleep(5.2)
        
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('X-Request-ID', req_id)
        self.end_headers()
        resp = {
            "status": "APPROVED",
            "transaction_id": "TXN-884129",
            "request_id": req_id,
            "processing_time_sec": 5.2
        }
        self.wfile.write(json.dumps(resp).encode('utf-8'))
        print(f"[{time.strftime('%X')}] [BACKEND] Payment finalized successfully (HTTP 200 OK) for {req_id}")
    def log_message(self, format, *args):
        pass

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else PORT
    with socketserver.TCPServer(("", port), SlowCheckoutHandler) as httpd:
        print(f"[SLOW CHECKOUT BACKEND] Listening on port {port}")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass
