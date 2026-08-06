#!/usr/bin/env python3
"""heartbeat — the toy service Milestone 1 scenarios break and learners fix.

Simulates a minimal app: writes a heartbeat line to its log every 2s and
serves a trivial healthcheck on :8080/health. Real enough to have a PID,
real logs, and a real port to probe, without pulling in a framework.
"""
import http.server
import socketserver
import threading
import time

LOG_PATH = "/var/log/heartbeat/heartbeat.log"


def beat():
    while True:
        with open(LOG_PATH, "a") as f:
            f.write(f"{time.strftime('%Y-%m-%dT%H:%M:%S')} heartbeat ok\n")
        time.sleep(2)


class Health(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"ok\n")
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, *args):
        pass  # keep stdout quiet; heartbeat.log is the real signal


if __name__ == "__main__":
    threading.Thread(target=beat, daemon=True).start()
    with socketserver.TCPServer(("0.0.0.0", 8080), Health) as httpd:
        httpd.serve_forever()
