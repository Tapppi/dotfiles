# Tool Update Review — Design Document

Table of contents:
- A. Data Model — report JSON schema (A.1) and feedback.json schema (A.2)
- B. Page Design — palette, wireframes, interaction spec, keyboard nav
- C. Server + Session Workflow — server spec (C.1), session steps (C.2), failure modes (C.3)
- D. Template Variables — placeholder strategy and suggestion-id mapping

## A. Data Model

### A.1 Report Input Schema

The report is a single JSON object injected into the page template. The top-level shape:

```jsonc
{
	"schema_version": 1,
	"report_id": "tool-update-review-20260704T143012",   // stable within a session run
	"generated_at": "2026-07-04T14:30:12Z",              // ISO-8601 UTC
	"machine": {
		"arch":    "x86_64",         // "x86_64" | "arm64"
		"os":      "macOS 15.3",
		"hostname": "your-mac"
	},
	"summary": {
		"total_outdated":      14,
		"incompatible_count":  2,
		"warning_count":       3,
		"suggestions_count":   7
	},
	"tools": [ /* Tool[] — see below */ ]
}
```

**Tool object:**

```jsonc
{
	// ── Identity ──────────────────────────────────────────────────────
	"id":      "brew:podman",           // stable: "{source}:{name}"
	"name":    "podman",
	"source":  "brew",                  // "brew" | "cask" | "mise" | "standalone"
	"pinned":  true,                    // brew pin active

	// ── Versions ──────────────────────────────────────────────────────
	"current_version": "4.9.3",
	"latest_version":  "5.5.1",

	// ── Research ──────────────────────────────────────────────────────
	"research_error": null,             // null | string — set if subagent failed
	"headliners": [                     // agent-written; ≤6 concise bullets
		"Migrated networking to netavark/aardvark stack",
		"libkrun dependency now required (Apple Silicon only)"
	],
	"links": [
		{
			"type":  "changelog",           // "changelog" | "release" | "blog"
			"label": "CHANGELOG.md",
			"url":   "https://github.com/containers/podman/blob/main/CHANGELOG.md"
		}
	],

	// ── Relevancy ─────────────────────────────────────────────────────
	"relevancy": [
		{
			"severity": "incompatible",     // "info" | "notable" | "warning" | "incompatible"
			"summary":  "Requires Apple Silicon (libkrun); Intel Mac not supported in v5+",
			"detail":   "Longer explanation with the concrete failure mode.",
			"evidence": [                   // file paths with optional :line suffix
				"Brewfile:84",
				"intel.Brewfile"
			],
			"motivating_change": "v5.0.0 release notes — 'libkrun is now a required dependency'"
		}
	],

	// ── Suggestions ───────────────────────────────────────────────────
	"suggestions": [
		{
			"id":    "brew:podman:keep-pin-add-comment",   // unique within report
			"title": "Retain pin; annotate Brewfile with Intel-incompatibility note",
			"target_files": [
				{
					"path":        "Brewfile",
					"description": "Add inline comment above podman line explaining pin rationale"
				}
			],
			"rationale": "Documents why the package is held so a future cleanup doesn't unpin it blindly.",
			"motivating_link": {
				"type":  "release",
				"label": "podman v5.0.0",
				"url":   "https://github.com/containers/podman/releases/tag/v5.0.0"
			},
			"diff_preview": "-brew \"podman\"\n+# Intel only — v5+ requires libkrun (ARM). Keep at 4.x.\n+brew \"podman\""
		}
	]
}
```

Source vocabulary: `brew` = Brewfile `brew` line, `cask` = Brewfile `cask` line,
`mise` = `mise outdated` runtime, `standalone` = tool updated outside brew
(claude CLI, codex CLI — version checked by running `--version` and comparing
to the latest release).

Node gets a richer `headliners[]` list (security advisories, notable API
changes); other mise runtimes get a coarser treatment (two or three bullets
max, focus on breaking changes only).

### A.2 Feedback Schema (`feedback.json`)

Written atomically by the server to `{session_dir}/feedback.json`.

```jsonc
{
	"report_id":    "tool-update-review-20260704T143012",
	"submitted_at": "2026-07-04T14:52:07Z",

	// One entry per suggestion the user interacted with.
	// Absent key = undecided.
	"decisions": {
		"brew:podman:keep-pin-add-comment": {
			"decision": "accept",           // "accept" | "reject" | "discuss"
			"comment":  ""                  // may be non-empty for any decision
		}
	},

	// Optional free-text comment anchored to a tool (not a suggestion).
	"tool_comments": {
		"mise:node": "Hold off until the project upgrades its .nvmrc"
	},

	"overall_comment": ""
}
```

`decision` semantics:
- `accept` — session applies the edit immediately, following dotfiles-submodule conventions.
- `reject` — session skips; records in summary.
- `discuss` — session does not apply; surfaces the suggestion + comment as a
  follow-up dialogue item after the apply pass.

## B. Page Design

### B.1 Aesthetic Constraints

Solarized Dark palette as CSS custom properties, no external dependencies:

| Token | Hex | Role |
|---|---|---|
| `--base03` | `#002b36` | page background |
| `--base02` | `#073642` | panel / card background |
| `--base01` | `#586e75` | border, de-emphasized |
| `--base00` | `#657b83` | secondary text |
| `--base0`  | `#839496` | body text |
| `--base1`  | `#93a1a1` | emphasis text |
| `--base2`  | `#eee8d5` | heading text |
| `--yellow` | `#b58900` | `warning` severity, pin badge, discuss state |
| `--orange` | `#cb4b16` | `notable` severity badge |
| `--red`    | `#dc322f` | `incompatible` severity, prominent callout |
| `--blue`   | `#268bd2` | links, `info` severity |
| `--cyan`   | `#2aa198` | Accept confirmed state |
| `--green`  | `#859900` | version delta new-version text, diff additions |
| `--violet` | `#6c71c4` | mise source badge |
| `--magenta`| `#d33682` | standalone source badge |

Single file: all CSS and JS inline. Zero CDN calls; system font stacks only.
Must render correctly offline.

### B.2 Page Layout

Header: title, date, machine context (arch highlighted when Intel — it gates
compatibility). Counts row: tools with updates, incompatible, suggestions.

Filter bar: source select (All|brew|cask|mise|standalone), severity select,
"Only relevant to me" toggle (hides tools with empty `relevancy[]`), sort
select (Incompatible first default | Name | Source | Major-delta first).
Client-side only: toggle `display:none` and reorder DOM nodes.

Sticky progress bar (`position: sticky; top: 0`): thin progress bar (cyan
decided / base01 remaining), text "N of M decided · K incompatible undecided"
(red flash when K > 0), Submit button — disabled until every suggestion on an
`incompatible`-severity tool has a decision; tooltip explains why.
Non-incompatible suggestions may be left undecided.

Per-tool `<section>`: collapsible; header row with name, `current → latest`
(latest in green), source badge, PINNED badge (yellow) when pinned; severity
callouts (incompatible = red filled block, others outlined) with evidence
paths; headliner bullets; links row (`[changelog ↗] [release ↗] [blog ↗]`);
suggestion cards; a per-tool note textarea.

Suggestion card: title, target file(s), rationale, motivating link, diff
preview (`+` green / `-` red in a `<pre>`), Accept/Reject/Discuss buttons,
comment textarea (1 row collapsed, 3 rows focused). Clicking an active
decision button toggles back to undecided.

| State | Visual |
|---|---|
| Undecided | default card |
| Accepted | left border + Accept button filled cyan, "ACCEPTED" |
| Rejected | left border base01, card dimmed, "REJECTED" |
| Discuss | left border + Discuss button filled yellow, "DISCUSS" |

Submit: POST JSON to `/feedback`; on 200 show full-page overlay "Feedback
submitted — return to your terminal"; on error keep data, show retry.

### B.3 Keyboard Navigation (nice-to-have)

`j`/`k` next/previous tool section (blue outline, scroll into view); `a`/`r`/`c`
act on first undecided suggestion in focused tool (repeats cycle); `s` submit
if ready; `f` cycle filter presets All → Incompatible → Relevant; `?` help
overlay. Suppressed while typing in a textarea.

## C. Server + Session Workflow

### C.1 Python Stdlib Server

`server.py {session_dir} {port}` — stdlib only (`http.server`, `socketserver`,
`json`, `os`, `threading`). Bind `127.0.0.1` only. Try port 8742, on EADDRINUSE
increment up to 8751, then fail with `lsof -i :8742` hint.
`allow_reuse_address = True`.

Endpoints:
- `GET /` → 200, serves `{session_dir}/index.html` read at request time.
- `GET /health` → `{"status":"ok"}` — session polls before opening browser.
- `POST /feedback` → validate JSON + `report_id` match (400 on mismatch);
  write `feedback.json.tmp`; `os.replace()` to `feedback.json`; respond
  `{"status":"written","path":...}`; then `threading.Thread(target=server.shutdown).start()`
  (shutdown must come from a different thread than `serve_forever()`), with a
  ~1 s delay so the response flushes.

Session detects submission by blocking on the server subprocess exit
(`wait(timeout=1800)`). Fallback: poll for `feedback.json` existence every 5 s.

### C.2 Session Steps

1. **Collect** — run `scripts/collect.sh` (brew outdated intersected with
   Brewfile + pin state, mise outdated, standalone CLI versions) → candidates JSON.
2. **Research** — one subagent per tool in parallel; each returns headliners,
   typed links, relevancy (against setup repos + machine arch), suggestions.
   Timeout → `research_error` set, tool still listed with versions only.
3. **Assemble** — merge, compute summary counts, validate suggestion-id
   uniqueness and evidence paths (warn, don't abort).
4. **Render** — `scripts/render.py report.json` → writes `index.html` into a
   session dir (`/tmp/tool-update-review-{report_id}/`).
5. **Serve** — launch `server.py`, poll `/health`, `open http://localhost:{port}/`.
6. **Wait** — block on server exit (30 min timeout; offer re-open or abandon).
7. **Apply** — read `feedback.json`; apply `accept` decisions per repo
   conventions (dotfiles submodule flow for `dotfiles/` paths; direct edit for
   `Brewfile` etc.); queue `discuss` items for conversation; summarize
   accepted/rejected/discuss/undecided + comments.

### C.3 Failure Modes

| Failure | Handling |
|---|---|
| All ports busy | Fail with `lsof` hint |
| Tab closed, no submit | Server stays up; 30-min timeout, offer re-open (state lives in the page until tab closes; re-open re-renders fresh) |
| Server crash | Check for valid `feedback.json` (partial submit), else offer re-serve |
| Stale `feedback.json` | `report_id` mismatch → warn, confirm before use |
| One tool's research fails | `research_error` shown, no suggestions for it |
| POST with unknown suggestion ids | 400, page shows error toast |

## D. Template Variables

Exactly three tokens, replaced by plain string substitution (no template engine):

```html
<meta name="report-id" content="__REPORT_ID__">
<meta name="generated-at" content="__GENERATED_AT__">
<script>const REPORT = __REPORT_DATA__;</script>
```

```python
html = html.replace('"__REPORT_ID__"', json.dumps(report_id))
html = html.replace('"__GENERATED_AT__"', json.dumps(generated_at))
html = html.replace('__REPORT_DATA__', json.dumps(report, ensure_ascii=False))
```

`__REPORT_DATA__` is unquoted in the template so the JSON object lands as a JS
expression. The other two sit inside attribute quotes, so the replacement
target includes the quotes.

Rendering is done in JS from `REPORT.tools[]`: sections carry
`data-tool-id` and `data-max-severity` attributes; suggestion cards carry
`data-suggestion-id` and `data-decision` (CSS attribute selectors drive visual
state). Submit walks the DOM to build the feedback payload.

Suggestion ids: `{source}:{name}:{slug}` — deterministic kebab-case slug of the
action, never index-based, unique within the report (`-2`, `-3` suffix on
collision). The session looks up accepted ids in its in-memory report to get
`target_files`, `diff_preview`, `rationale` for the edit.
