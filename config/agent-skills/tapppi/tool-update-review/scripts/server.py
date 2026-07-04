#!/usr/bin/env python3
"""
server.py — local review server for tool-update-review sessions.
Usage: server.py <session_dir> [port] [--bind ADDR]

Always listens on 127.0.0.1; each --bind ADDR adds a listener on the
same port (e.g. the tailscale IP from `tailscale ip -4` for remote
review). The report holds config details, so only add interfaces the
user trusts — a tailnet qualifies, a shared LAN may not. All listeners
shut down after a successful POST /feedback on any of them.

Note: on macOS a browser/curl on this same machine may fail to reach
the machine's own tailscale IP (utun hairpin) — locals use 127.0.0.1,
remotes use the tailscale address; that split is why multi-bind exists.
"""
import http.server
import json
import os
import socketserver
import sys
import threading
import time


def main():
	args = sys.argv[1:]
	bind_addrs = ["127.0.0.1"]
	while "--bind" in args:
		idx = args.index("--bind")
		try:
			addr = args[idx + 1]
		except IndexError:
			print("Error: --bind requires an address", file=sys.stderr)
			sys.exit(1)
		if addr not in bind_addrs:
			bind_addrs.append(addr)
		del args[idx:idx + 2]

	if len(args) < 1:
		print("Usage: server.py <session_dir> [port] [--bind ADDR ...]", file=sys.stderr)
		sys.exit(1)

	session_dir = os.path.abspath(args[0])
	start_port = int(args[1]) if len(args) > 1 else 8742

	# ── Load report metadata ──────────────────────────────────────────────
	report_path = os.path.join(session_dir, "report.json")
	try:
		with open(report_path, "r", encoding="utf-8") as fh:
			report = json.load(fh)
	except FileNotFoundError:
		print(f"Error: report.json not found in {session_dir!r}", file=sys.stderr)
		sys.exit(1)
	except json.JSONDecodeError as exc:
		print(f"Error: report.json is not valid JSON: {exc}", file=sys.stderr)
		sys.exit(1)

	expected_report_id = report.get("report_id", "")
	known_ids: set[str] = set()
	for tool in report.get("tools", []):
		for sug in tool.get("suggestions", []):
			sid = sug.get("id")
			if sid:
				known_ids.add(sid)

	# ── Mutable holder so the handler closure can reach every listener ────
	server_holder: list = []

	# ── Request handler ───────────────────────────────────────────────────
	def make_handler(sess_dir: str, k_ids: set, exp_id: str):
		class Handler(http.server.BaseHTTPRequestHandler):

			def log_message(self, fmt, *args):  # suppress default access log
				pass

			# Paths are matched by suffix so the server works both served
			# directly and behind a proxy mount (e.g. tailscale serve
			# --set-path /updates), whether or not the proxy strips the
			# mount prefix.
			def _route(self):
				return self.path.split("?", 1)[0].rstrip("/")

			# ── GET ───────────────────────────────────────────────────────
			def do_GET(self):
				if self._route().endswith("/health"):
					body = json.dumps({"status": "ok"}).encode("utf-8")
					self.send_response(200)
					self.send_header("Content-Type", "application/json")
					self.send_header("Content-Length", str(len(body)))
					self.end_headers()
					self.wfile.write(body)
					return

				# Anything else (/, /updates, favicon probes) gets the page.
				index_path = os.path.join(sess_dir, "index.html")
				try:
					with open(index_path, "rb") as fh:
						data = fh.read()
				except FileNotFoundError:
					self.send_error(404, "index.html not found")
					return
				self.send_response(200)
				self.send_header("Content-Type", "text/html; charset=utf-8")
				self.send_header("Content-Length", str(len(data)))
				self.end_headers()
				self.wfile.write(data)

			# ── POST ──────────────────────────────────────────────────────
			def do_POST(self):
				if not self._route().endswith("/feedback"):
					self.send_error(404, "Not found")
					return

				length = int(self.headers.get("Content-Length", 0))
				raw = self.rfile.read(length)

				# Validate JSON
				try:
					payload = json.loads(raw)
				except Exception:
					self._error(400, "Malformed JSON")
					return

				# Validate report_id
				if payload.get("report_id") != exp_id:
					self._error(
						400,
						f"report_id mismatch: expected {exp_id!r}, "
						f"got {payload.get('report_id')!r}",
					)
					return

				# Validate suggestion ids
				submitted_ids = set(payload.get("decisions", {}).keys())
				unknown = submitted_ids - k_ids
				if unknown:
					self._error(
						400,
						"Unknown suggestion id(s): " + ", ".join(sorted(unknown)),
					)
					return

				# Atomically write feedback.json
				feedback_path = os.path.join(sess_dir, "feedback.json")
				tmp_path = feedback_path + ".tmp"
				with open(tmp_path, "w", encoding="utf-8") as fh:
					json.dump(payload, fh, ensure_ascii=False, indent="\t")
					fh.write("\n")
				os.replace(tmp_path, feedback_path)

				body = json.dumps(
					{"status": "written", "path": feedback_path}
				).encode("utf-8")
				self.send_response(200)
				self.send_header("Content-Type", "application/json")
				self.send_header("Content-Length", str(len(body)))
				self.end_headers()
				self.wfile.write(body)

				# Shut down from a separate thread (~1 s delay so response flushes)
				def _shutdown():
					time.sleep(1)
					for httpd in server_holder:
						httpd.shutdown()

				threading.Thread(target=_shutdown, daemon=True).start()

			# ── Helper ───────────────────────────────────────────────────
			def _error(self, code: int, message: str):
				body = json.dumps({"error": message}).encode("utf-8")
				self.send_response(code)
				self.send_header("Content-Type", "application/json")
				self.send_header("Content-Length", str(len(body)))
				self.end_headers()
				self.wfile.write(body)

		return Handler

	# ── Server class with address reuse and quiet disconnect handling ─────
	class Server(socketserver.ThreadingTCPServer):
		allow_reuse_address = True
		daemon_threads = True

		def handle_error(self, request, client_address):
			# Suppress tracebacks for clients that vanish mid-request
			# (ENOTCONN 57 / ECONNRESET 54 / EPIPE 32 — routine, especially
			# for same-host probes of a tailscale/utun address on macOS).
			exc = sys.exception()
			if isinstance(exc, OSError) and exc.errno in (32, 54, 57):
				return
			super().handle_error(request, client_address)

	Handler = make_handler(session_dir, known_ids, expected_report_id)

	# ── Port walking: one port that is free on every bind address ─────────
	servers: list = []
	port = start_port
	max_port = max(8751, start_port)
	while port <= max_port:
		opened = []
		try:
			for addr in bind_addrs:
				opened.append(Server((addr, port), Handler))
			servers = opened
			break
		except OSError:
			for srv in opened:
				srv.server_close()
			port += 1

	if not servers:
		print(
			f"Error: all ports {start_port}–{max_port} are busy. "
			f"Check with: lsof -i :{start_port}",
			file=sys.stderr,
		)
		sys.exit(1)

	server_holder.extend(servers)
	for addr in bind_addrs:
		print(f"SERVING http://{addr}:{port}/", flush=True)

	threads = [
		threading.Thread(target=srv.serve_forever, daemon=True)
		for srv in servers
	]
	for thread in threads:
		thread.start()
	for thread in threads:
		thread.join()


if __name__ == "__main__":
	main()
