#!/usr/bin/env python3
"""
Simple HTTP health check server for Render
Responds to health check requests on port 8080
"""
import http.server
import socketserver
import sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8080

class HealthCheckHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/' or self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = b'{"status":"ok","service":"socks5-proxy"}\n'
            self.wfile.write(response)
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        # Suppress default logging
        pass

with socketserver.TCPServer(("", PORT), HealthCheckHandler) as httpd:
    print(f"Health check server running on port {PORT}")
    httpd.serve_forever()
