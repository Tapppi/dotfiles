#!/usr/bin/env python3
"""
render.py — inject report.json into the HTML template and write index.html.
Usage: render.py <path-to-report.json>

Reads report.json, validates schema_version and suggestion-id uniqueness,
performs three token replacements in the template, writes index.html next
to report.json, and copies server.py alongside it. Prints the output path.
"""
import json
import os
import shutil
import sys


def main():
	if len(sys.argv) < 2:
		print("Usage: render.py <path-to-report.json>", file=sys.stderr)
		sys.exit(1)

	report_path = os.path.abspath(sys.argv[1])
	report_dir = os.path.dirname(report_path)
	script_dir = os.path.dirname(os.path.abspath(__file__))

	template_path = os.path.normpath(
		os.path.join(script_dir, "..", "assets", "report-template.html")
	)
	server_src = os.path.join(script_dir, "server.py")

	# ── Load report ───────────────────────────────────────────────────────
	try:
		with open(report_path, "r", encoding="utf-8") as fh:
			report = json.load(fh)
	except FileNotFoundError:
		print(f"Error: report not found: {report_path}", file=sys.stderr)
		sys.exit(1)
	except json.JSONDecodeError as exc:
		print(f"Error: report.json is not valid JSON: {exc}", file=sys.stderr)
		sys.exit(1)

	# ── Validate schema_version ───────────────────────────────────────────
	if report.get("schema_version") != 1:
		print(
			f"Error: schema_version must be 1, got {report.get('schema_version')!r}",
			file=sys.stderr,
		)
		sys.exit(1)

	# ── Validate suggestion id uniqueness ─────────────────────────────────
	seen: dict[str, str] = {}  # id → tool id
	for tool in report.get("tools", []):
		tool_id = tool.get("id", "<unknown>")
		for sug in tool.get("suggestions", []):
			sid = sug.get("id")
			if not sid:
				continue
			if sid in seen:
				print(
					f"Error: duplicate suggestion id {sid!r} "
					f"(in tool {tool_id!r} and {seen[sid]!r})",
					file=sys.stderr,
				)
				sys.exit(1)
			seen[sid] = tool_id

	# ── Extract template variables ────────────────────────────────────────
	report_id = report.get("report_id", "")
	generated_at = report.get("generated_at", "")

	# ── Read template ─────────────────────────────────────────────────────
	try:
		with open(template_path, "r", encoding="utf-8") as fh:
			html = fh.read()
	except FileNotFoundError:
		print(f"Error: template not found: {template_path}", file=sys.stderr)
		sys.exit(1)

	# ── Three token replacements per design D.1 ───────────────────────────
	# The tokens inside attribute quotes include the surrounding quotes.
	html = html.replace('"__REPORT_ID__"',    json.dumps(report_id))
	html = html.replace('"__GENERATED_AT__"', json.dumps(generated_at))
	# The REPORT_DATA token is unquoted — it lands as a JS object literal.
	html = html.replace("__REPORT_DATA__",    json.dumps(report, ensure_ascii=False))

	# ── Write index.html ──────────────────────────────────────────────────
	out_path = os.path.join(report_dir, "index.html")
	with open(out_path, "w", encoding="utf-8") as fh:
		fh.write(html)

	# ── Copy server.py ────────────────────────────────────────────────────
	server_dst = os.path.join(report_dir, "server.py")
	shutil.copy2(server_src, server_dst)

	print(out_path)


if __name__ == "__main__":
	main()
