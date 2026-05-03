"""
Proxy server: serves static files on port 8000
and forwards /api/* requests to the Alpaca server (default port 11111).
Run: python server.py
"""
import http.server
import urllib.request
import urllib.error
import sys
import json

ALPACA_URL = "http://127.0.0.1:11111"
PORT = 8000

_slew = {"rate": 20, "fine": False}


class ProxyHandler(http.server.SimpleHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, PUT, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_GET(self):
        if self.path == '/slew-settings':
            self._send_json(_slew)
        elif self.path.startswith("/api/"):
            self._proxy("GET")
        else:
            super().do_GET()

    def do_PUT(self):
        if self.path == '/slew-settings':
            global _slew
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length) if length else b'{}'
            try:
                _slew = json.loads(body)
            except Exception:
                pass
            self._send_json({"ok": True})
        elif self.path.startswith("/api/"):
            self._proxy("PUT")
        else:
            self.send_error(405)

    def _send_json(self, data):
        try:
            body = json.dumps(data).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        except (ConnectionAbortedError, ConnectionResetError, BrokenPipeError):
            pass

    def _proxy(self, method):
        target = ALPACA_URL + self.path
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length) if length else None
        headers = {
            k: v for k, v in self.headers.items()
            if k.lower() not in ("host", "content-length")
        }
        timeout = 15 if method == "PUT" else 3
        try:
            req = urllib.request.Request(target, data=body, headers=headers, method=method)
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                data = resp.read()
                self.send_response(resp.status)
                for k, v in resp.headers.items():
                    if k.lower() not in ("transfer-encoding",):
                        self.send_header(k, v)
                self.end_headers()
                self.wfile.write(data)
        except (ConnectionAbortedError, ConnectionResetError, BrokenPipeError):
            pass
        except urllib.error.HTTPError as e:
            try:
                data = e.read()
                self.send_response(e.code)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(data)
            except (ConnectionAbortedError, ConnectionResetError, BrokenPipeError):
                pass
        except Exception as e:
            try:
                self.send_error(502, str(e))
            except (ConnectionAbortedError, ConnectionResetError, BrokenPipeError):
                pass

    def log_message(self, fmt, *args):
        print(fmt % args)

    def log_error(self, fmt, *args):
        if getattr(self, 'path', '').endswith('favicon.ico'):
            return
        print(fmt % args)


if __name__ == "__main__":
    alpaca_arg = next((a for a in sys.argv[1:] if a.startswith("http")), None)
    if alpaca_arg:
        ALPACA_URL = alpaca_arg.rstrip("/")
    with http.server.HTTPServer(("", PORT), ProxyHandler) as httpd:
        print(f"Serving on http://localhost:{PORT}")
        print(f"Proxying /api/* -> {ALPACA_URL}")
        httpd.serve_forever()
