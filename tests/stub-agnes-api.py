import json
from http.server import BaseHTTPRequestHandler, HTTPServer


class H(BaseHTTPRequestHandler):
    def do_POST(self):
        n = int(self.headers.get("content-length", 0))
        body = json.loads(self.rfile.read(n) or b"{}")
        model = body.get("model", "")
        if model.endswith("2.5-flash"):
            payload = {"error": {"message": "simulated upstream outage"}}
            code = 500
        else:
            payload = {"data": [{"url": f"https://example.test/{model}.png"}], "task_id": "stub-1"}
            code = 200
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(payload).encode())

    def log_message(self, *a):
        pass


HTTPServer(("127.0.0.1", 18011), H).serve_forever()
