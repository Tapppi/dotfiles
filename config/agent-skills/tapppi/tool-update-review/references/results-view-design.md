# Tool Update Review — Results View Extension Design

Extension to `references/design.md`. Covers the live-tracking Results view that
replaces the static success overlay after Submit. The report view remains accessible
as a read-only tab. The server stays alive until the user clicks Finish.

Table of contents:
- A. `status.json` schema
- B. Server changes — endpoint spec
- C. Page design — transition, layout, wireframes, polling
- D. Session workflow changes for `SKILL.md`

---

## A. `status.json` Schema

### File location and write pattern

```
{session_dir}/status.json          <- live file; page polls this
{session_dir}/status.json.tmp      <- transient; os.replace()d into place
```

The server reads the file on every GET /status request. The session writes it
atomically: open `.tmp`, json.dump + trailing newline, `os.replace()` to final
path. The page tolerates 404 (server not yet written first status) and handles
partial responses gracefully by checking `schema_version`.

### Schema (schema_version 2)

```jsonc
{
  "schema_version": 2,
  "report_id": "tool-update-review-20260704T143012",

  // "applying" | "discussing" | "done"
  // "applying"   — session executing accepted suggestion actions
  // "discussing" — apply pass complete, session surfacing discuss items in
  //                conversation (user may still be interacting with session)
  // "done"       — all work complete; done flag true; Finish button enabled
  "phase": "applying",

  "started_at": "2026-07-04T14:52:10Z",  // when session began apply pass
  "written_at": "2026-07-04T14:53:42Z",  // timestamp of this write (staleness check)

  "actions": [
    {
      // Suggestion-backed: the suggestion id from feedback.json decisions
      // Synthetic (non-suggestion work): "{verb}:{context}" format
      //   commit:dotfiles       — git commit in dotfiles submodule
      //   commit:macos-setup    — git commit in parent repo
      // Add more synthetic ids as needed; the page treats them identically.
      "id": "brew:podman:keep-pin-add-comment",

      // Human-readable one-liner shown in the action list
      "label": "Add pin comment to Brewfile",

      // Mirrors the user's decision from feedback.json, null for synthetic actions
      "decision": "accept",   // "accept" | "reject" | "discuss" | null

      // "pending" — not yet started
      // "running" — actively executing (spinner shown)
      // "done"    — completed successfully
      // "failed"  — execution error (detail lines explain)
      // "skipped" — not executed (decision was reject/discuss/undecided, or
      //             a dependency failed)
      "state": "running",

      "started_at": "2026-07-04T14:52:11Z",  // ISO UTC; null if not started
      "finished_at": null,                    // ISO UTC; null if not finished

      // Written on transition to done/failed/skipped; null while pending/running
      "note": null,    // e.g. "Committed as abc1234 in dotfiles"

      // Last ≤10 lines of relevant output; empty array if none
      // e.g. diff hunk applied, commit hash, error message
      "detail": []
    }
    // ... more actions in execution order
  ],

  // Free-form markdown-ish text written by the session at done time.
  // Covers: what was applied, commits made, discuss items and their comments,
  // rejected/undecided items, follow-up actions needed.
  // Empty string until the session writes it (phase "done").
  "recap": "",

  // Each element is the markdown text of one changelog entry appended to
  // ${XDG_STATE_HOME:-~/.local/state}/tool-update-review/changelog.md
  // during this session. Empty list until entries are written.
  // Example element: "## 2026-07-04\n### brew: gh 2.48.0 → 2.52.0\n..."
  "changelog_entries": [],

  // Written at done time. Counts are over user decisions (from feedback),
  // not over action execution states. "failed" counts execution failures
  // among accepted suggestions (not user rejections).
  "summary": {
    "applied":   3,   // accepted + execution succeeded
    "rejected":  2,   // user rejected
    "discussed": 1,   // user selected discuss (not applied, raised in session)
    "undecided": 0,   // no decision made (skipped)
    "failed":    0    // accepted but execution failed
  },

  // Terminal signal. The page enables the Finish button when true.
  // Set to true only in the same write that sets phase "done".
  "done": false
}
```

### Action ordering

The `actions` array is in execution order: accepted suggestions first (in the
order they appear in the feedback), then synthetic commit actions, then
rejected/undecided items (state "skipped"). The page renders them in array
order.

### State transitions

```
pending → running → done
                 → failed
         skipped  (set directly from pending, no running state)
```

A single session write covers one transition at a time (e.g. pending→running,
then running→done in the next write). Never write both in one atomic op; the
page needs to observe "running" to show the spinner.

---

## B. Server Changes

### `/feedback` — change: remove shutdown, add duplicate guard

**Remove**: the `threading.Thread(target=_shutdown).start()` call.

**Add**: duplicate-submit guard at the top of the `do_POST` handler for
`/feedback`, before reading the request body:

```python
feedback_path = os.path.join(sess_dir, "feedback.json")
if os.path.exists(feedback_path):
    # Already submitted (e.g. second tab, page refresh with Submit clicked again)
    self._error(409, "already_submitted")
    return
```

All other `/feedback` behavior unchanged: JSON validation, report_id check,
unknown-id check, atomic write, 200 response.

### `GET .../status` — new endpoint

Added to `do_GET`, checked before the catch-all HTML serve:

```python
if self._route().endswith("/status"):
    status_path = os.path.join(sess_dir, "status.json")
    try:
        with open(status_path, "rb") as fh:
            data = fh.read()
    except FileNotFoundError:
        self.send_error(404, "status.json not found")
        return
    self.send_response(200)
    self.send_header("Content-Type", "application/json")
    self.send_header("Cache-Control", "no-store")
    self.send_header("Content-Length", str(len(data)))
    self.end_headers()
    self.wfile.write(data)
    return
```

No in-memory caching. Reads the file on every request so the page always gets
the latest atomic write.

### `POST .../shutdown` — new endpoint

Added to `do_POST`, checked before the `/feedback` branch:

```python
if self._route().endswith("/shutdown"):
    # Idempotent: if shutdown already scheduled, still return 200.
    body = json.dumps({"status": "shutdown_scheduled"}).encode("utf-8")
    self.send_response(200)
    self.send_header("Content-Type", "application/json")
    self.send_header("Content-Length", str(len(body)))
    self.end_headers()
    self.wfile.write(body)

    def _shutdown():
        time.sleep(1)
        for httpd in server_holder:
            httpd.shutdown()

    threading.Thread(target=_shutdown, daemon=True).start()
    return
```

The response flushes before the 1 s delay fires. Subsequent POST /shutdown
calls while the server is shutting down may get an ECONNRESET (quiet-disconnect
handler covers it) or another 200 — both are fine.

### Routing order in `do_GET`

```
1. endswith("/health")   → {"status":"ok"}
2. endswith("/status")   → status.json or 404
3. catch-all             → index.html
```

### Routing order in `do_POST`

```
1. endswith("/shutdown") → schedule shutdown, 200
2. endswith("/feedback") → validate + write feedback.json, 200 (or 400/409)
3. else                  → 404
```

### Unchanged behaviors

- Multi-bind (`--bind ADDR`) support: all server instances share `server_holder`;
  shutdown triggered on any interface tears down all.
- Quiet-disconnect suppression (ENOTCONN/ECONNRESET/EPIPE).
- Port-walking (8742–8751).
- `allow_reuse_address = True`, daemon threads.

---

## C. Page Design

### C.1 Initial-load state detection

On `DOMContentLoaded`, before rendering the report view, the page issues one
probe:

```js
const base = location.pathname.replace(/\/+$/, '');

async function probeStatus() {
    try {
        const r = await fetch(base + '/status', { cache: 'no-store' });
        if (r.ok) {
            const data = await r.json();
            // feedback already submitted (e.g. page refresh mid-apply)
            transitionToResults(data);
            startPolling();
            return;
        }
    } catch (_) { /* server not up yet, or network error — fall through */ }
    // Normal path: render report view
    renderHeader();
    renderTools();
    updateProgress();
    applyFilters();
}
probeStatus();
```

404 or any network error: render report view normally. 200: go straight to
Results view and start polling. This handles page refreshes during apply.

### C.2 Submit handler change

Replace the success-overlay code with:

```js
if (resp.ok) {
    transitionToResults(null);   // null = no initial data yet
    startPolling();
} else { /* existing error path */ }
```

### C.3 View transition (`transitionToResults`)

1. Hide `#filter-bar` (`display:none`).
2. Replace `#progress-bar-container` contents with the tab strip + results
   status bar (see layout below). Do not remove the element; keep it sticky.
3. Freeze the report view: set all `<button>`, `<textarea>`, `<select>`,
   `<input>` inside `#main` to `disabled`; add a CSS class `report-frozen`
   to `#main` that reduces opacity to 0.5.
4. Create `#results-panel` div (see layout), insert it into the DOM after
   `#progress-bar-container` and before `#main`.
5. Show `#results-panel`, hide `#main` (the Report tab will toggle these).

`transitionToResults(initialData)` accepts the first status blob or null. If
non-null, render it immediately before the first poll arrives.

### C.4 Results view layout

```
#progress-bar-container (repurposed — stays sticky):
┌──────────────────────────────────────────────────────────────────┐
│  [Results ●]  [Report]        Applying…  · last update 0s ago   │
└──────────────────────────────────────────────────────────────────┘

#results-panel:
┌──────────────────────────────────────────────────────────────────┐
│  #results-status-bar                                             │
│  Applying changes… (2 / 7 done · 0 failed)                      │
├──────────────────────────────────────────────────────────────────┤
│  ACTIONS                                                         │
│  [ state icon ]  label                         note (if any)    │
│  ...                                                             │
├──────────────────────────────────────────────────────────────────┤
│  NOTES / RECAP      (hidden until recap non-empty)               │
│  ...                                                             │
├──────────────────────────────────────────────────────────────────┤
│  CHANGELOG ENTRIES  (hidden until changelog_entries non-empty)   │
│  ...                                                             │
├──────────────────────────────────────────────────────────────────┤
│                                    [Finish ↗]  (disabled / enabled) │
└──────────────────────────────────────────────────────────────────┘
```

### C.5 ASCII wireframes

#### In-progress state

```
╔══════════════════════════════════════════════════════════════════╗
║  [Results ●]  [Report]              Applying… · updated 1s ago  ║
╠══════════════════════════════════════════════════════════════════╣
║  Applying changes — 2 of 5 done · 0 failed                      ║
╠══════════════════════════════════════════════════════════════════╣
║  ACTIONS                                                         ║
║  ✓  brew:podman:keep-pin-add-comment  Add pin comment to Brewfile║
║  ✓  commit:dotfiles                   Committed abc1234          ║
║  ⠇  mise:node:update-nvmrc            Updating .nvmrc…          ║  ← spinner
║  ○  commit:macos-setup                (pending)                  ║
║  —  brew:curl:no-action               Skipped (rejected)         ║
╠══════════════════════════════════════════════════════════════════╣
║  NOTES / RECAP                          (greyed — not yet ready) ║
╠══════════════════════════════════════════════════════════════════╣
║  CHANGELOG ENTRIES                      (greyed — not yet ready) ║
╠══════════════════════════════════════════════════════════════════╣
║                                    [Finish ↗]  (disabled, grey)  ║
╚══════════════════════════════════════════════════════════════════╝
```

#### Done state

```
╔══════════════════════════════════════════════════════════════════╗
║  [Results ●]  [Report]              Done · 2026-07-04 14:58 UTC ║
╠══════════════════════════════════════════════════════════════════╣
║  Complete — 3 applied · 2 rejected · 1 discuss · 0 failed       ║
╠══════════════════════════════════════════════════════════════════╣
║  ACTIONS                                                         ║
║  ✓  brew:podman:keep-pin-add-comment  Add pin comment to Brewfile║
║  ✓  commit:dotfiles                   Committed abc1234          ║
║  ✓  mise:node:update-nvmrc            Updated .nvmrc to 22.x    ║
║  ✗  brew:gh:update-config             Failed: merge conflict     ║
║  —  brew:curl:no-action               Skipped (rejected)         ║
╠══════════════════════════════════════════════════════════════════╣
║  NOTES / RECAP                                                   ║
║  Applied 3 of 4 accepted edits. brew:gh config had a merge       ║
║  conflict — manual fix needed. Committed dotfiles (abc1234) and  ║
║  macos-setup (def5678). Discuss: mise:node — user note: "Hold   ║
║  off until .nvmrc upgraded."                                     ║
╠══════════════════════════════════════════════════════════════════╣
║  CHANGELOG ENTRIES                                               ║
║  ## 2026-07-04                                                   ║
║  ### brew: gh 2.48.0 → 2.52.0                                   ║
║  Updated config alias for new --json flag.                       ║
╠══════════════════════════════════════════════════════════════════╣
║                                    [Finish ↗]  (enabled, cyan)   ║
╚══════════════════════════════════════════════════════════════════╝
```

#### Closing splash (full-page overlay, after Finish clicked)

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║                         ✓                                        ║
║                   Session complete                               ║
║           This window can be closed.                             ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

### C.6 Element detail

**Tab strip** (replaces progress-bar-container contents):
- Two buttons: "Results" and "Report". Active tab uses `--cyan` underline or
  filled background. Clicking "Report" shows `#main`, hides `#results-panel`;
  clicking "Results" reverses.
- Right-aligned status text: phase label + "updated N s ago" computed from
  `written_at`. Turn red if `written_at` is >120 s ago and `done` is false
  (stale session hint).

**Results status bar** (`#results-status-bar`):
- During apply: `"Applying changes — N of M done · K failed"`. K > 0 colors
  text red.
- Phase "discussing": `"In discussion — apply pass complete"` in yellow.
- Done: `"Complete — N applied · M rejected · K discuss · J failed"`. J > 0
  adds red badge.

**Action list item** per action entry:

| State   | Icon | Color             |
|---------|------|-------------------|
| pending | ○    | `--base01`        |
| running | ⠇    | `--cyan` (spins)  |
| done    | ✓    | `--green`         |
| failed  | ✗    | `--red`           |
| skipped | —    | `--base01`        |

Row layout: `[icon] [label]  [note]` on one line. Clicking a row expands a
`<pre>` showing `detail` lines (if non-empty), in monospace, `--base00` text
on `--base03` background. Collapsed by default.

**Recap section** (`#results-recap`):
Hidden (`display:none`) until `recap` is non-empty. Section label + `<pre>`
rendering of the recap text (whitespace-preserving, monospace). Not a textarea
— read only.

**Changelog section** (`#results-changelog`):
Hidden until `changelog_entries` is non-empty. Section label + one `<pre>`
block per entry, separated by a thin `--base01` rule. Monospace.

**Finish button** (`#finish-btn`):
- Disabled (grey, `cursor:not-allowed`) while `done` is false.
- Enabled (cyan) when `done` is true.
- If any action is still in state `running` when Finish is clicked (should not
  happen if `done` is properly gated, but guard anyway): show a confirm dialog:
  "Session may still be running. Finish anyway?" — yes → proceed, no → cancel.
- On click: POST to `base + '/shutdown'`. On 200: show closing splash overlay
  (reuse `.overlay-box` structure; text "Session complete — this window can be
  closed"). On network error: show error toast "Shutdown failed — the session
  may have already ended. Safe to close this window."

### C.7 Polling lifecycle

```js
let pollTimer = null;
let pollBackoff = 2000;   // ms; normal interval
let sessionEnded = false;

function startPolling() {
    if (pollTimer) return;
    schedulePoll();
}

function schedulePoll() {
    pollTimer = setTimeout(poll, pollBackoff);
}

async function poll() {
    pollTimer = null;
    if (sessionEnded) return;
    try {
        const r = await fetch(base + '/status', { cache: 'no-store' });
        if (r.ok) {
            const data = await r.json();
            pollBackoff = 2000;
            renderResults(data);
            if (data.done) {
                // Stop polling; Finish button is now enabled.
                return;
            }
        } else if (r.status === 404) {
            // Server up but status.json not yet written; back off.
            pollBackoff = Math.min(pollBackoff * 1.5, 10000);
        } else {
            pollBackoff = 5000;
        }
    } catch (_) {
        // Network error: server may have gone away prematurely.
        pollBackoff = Math.min(pollBackoff * 1.5, 15000);
        updateStatusBar('Connection lost — retrying…', 'warn');
    }
    schedulePoll();
}
```

Stop polling when `done: true` renders (no `schedulePoll()` call after that
branch). Also stop on closing splash (set `sessionEnded = true`).

**Stale indicator**: `renderResults` compares `written_at` to `Date.now()`. If
delta > 120 s and `done` is false, append to the tab status text:
`" · session may have stopped"` in yellow.

### C.8 `renderResults(data)`

Called on every successful poll and on `transitionToResults(initialData)`.
Idempotent: update existing DOM elements by id rather than re-rendering from
scratch (prevents scroll jumping).

Update:
1. Tab status text (phase, updated-ago).
2. `#results-status-bar` text.
3. Action list: for each action in `data.actions`, find or create the row by
   `data-action-id`, update icon, label, note, detail pre (toggled by click).
   Preserve expanded/collapsed state of detail pres across renders.
4. Recap section: show/hide + update text.
5. Changelog section: show/hide + update entries.
6. Finish button: enable/disable.

### C.9 Solarized Dark and dependency constraints

All new elements use the existing CSS custom properties. No new CDN calls.
Spinner animation: pure CSS `@keyframes spin` on the ⠇ character's parent
span, or cycle through braille frames in JS (`⠇⠏⠋⠙⠸⠴⠦⠧` at 120 ms) — either
is fine.

Subpath-tolerant URL construction (same pattern as existing /feedback):
```js
const base = location.pathname.replace(/\/+$/, '');
// base + '/status', base + '/shutdown', base + '/feedback'
```

---

## D. Session Workflow Changes (`SKILL.md`)

### New step sequence

Replace steps 4 (Serve and wait) and 5 (Apply feedback) with the following:

**4. Serve**

Start the server (unchanged from original). Poll `/health` until 200. Open URL.

**5. Wait for feedback.json**

Block by polling `{session_dir}/feedback.json` existence every 5 s (do NOT
block on server exit — the server no longer shuts down after feedback). Timeout
after 30 min: offer to re-open the page or abandon.

If `feedback.json` already exists when the server starts (e.g. session crashed
and was restarted): validate `report_id`. If it matches, skip the wait and
proceed immediately to step 6. If it mismatches, warn the user and ask whether
to serve fresh (rename the old file) or use the stale one.

**6. Write initial status.json**

Immediately after detecting `feedback.json`, build the initial `status.json`
and write it atomically:
- `phase`: `"applying"`
- `started_at`: now
- `written_at`: now
- `done`: false
- `actions`: one entry per feedback decision, in suggestion order, state
  `"pending"` for accepted/rejected/discussed; plus synthetic commit actions
  at the end (state `"pending"`). Rejected and undecided decisions get
  `"skipped"` immediately — they will never run.
- `recap`, `changelog_entries`, `summary`: empty/zero.

After writing, the page's next poll will get this file (it was 404 before).

**7. Apply accepted suggestions — per-action status updates**

For each accepted suggestion in order:
1. Write status.json: set action state `"running"`, `started_at: now`.
2. Apply the edit (dotfiles submodule flow or direct file edit).
3. Write status.json: set action state `"done"` or `"failed"`, `finished_at:
   now`, `note: <one-line outcome>`, `detail: [<last ≤10 lines of output>]`.

Commit actions (`commit:dotfiles`, `commit:macos-setup`) follow the same
pattern: running → done/failed.

**8. Append to changelog and write changelog entries**

For each runtime upgrade that was applied (mise runtimes, standalone CLIs),
append one entry to `${XDG_STATE_HOME:-~/.local/state}/tool-update-review/changelog.md`:

```markdown
## {YYYY-MM-DD}
### {source}: {name} {old_version} → {new_version}
{one to three sentence summary of what changed — pulled from headliners}
```

Create the file and parent directory if they do not exist (`mkdir -p`).

Collect all appended entries as strings; include them in the terminal
status.json write (step 9).

**9. Write terminal status.json**

After all actions complete and changelog is updated:
- `phase`: `"done"` (or `"discussing"` if discuss items remain — then
  transition to `"done"` after the discuss pass).
- `done`: `true`.
- `recap`: write the end-of-work summary (applied edits with commit hashes,
  failed actions with remediation hints, discuss items with user comments,
  rejected/undecided items).
- `changelog_entries`: all strings from step 8.
- `summary`: compute from action outcomes.
- `written_at`: now.

**10. Surface discuss items in conversation**

After writing terminal status, raise each `discuss` item in the session
conversation (tool name, suggestion title, user's comment). Do not apply
until the user confirms. This step is session-side only — no status.json
update needed (recap already mentions these).

**11. Wait for Finish (POST /shutdown)**

Block by polling for server exit (the shutdown endpoint triggers
`server.shutdown()` from a thread, which causes `serve_forever()` to return,
which causes the daemon threads to join and `main()` to exit). Use
`subprocess.wait(timeout=1800)` (30 min). Alternatively poll for the process
exit every 5 s within the timeout.

If timeout expires: print a message to the terminal ("Review session timed
out — you can still click Finish in the browser, or close it.") and proceed
to teardown anyway.

**12. Teardown**

Kill the tailscale serve proxy (if started). Clean up any temp files.
Session complete.

### Failure modes

| Failure | Handling |
|---|---|
| Session crashes mid-apply (stale `running` state) | Page detects `written_at` >120 s old with `done: false`; shows "session may have stopped" hint. Restart session from step 5 — it reads existing `feedback.json` and resumes. Already-completed actions show `done`/`failed` in `actions`; session skips them (check state before re-running). |
| User never clicks Finish | 30-min timeout at step 11; teardown proxy; server exits; session reports done in terminal. The browser tab becomes inert (poll errors; stale indicator). |
| `feedback.json` exists at serve time, report_id matches | Skip wait (step 5); proceed to step 6. Print "Resuming from existing feedback." |
| `feedback.json` exists, report_id mismatch | Warn; ask user: "Use stale feedback from a different session?" Default: rename stale file and re-serve fresh. |
| Apply edit fails (e.g. merge conflict) | Action state → `"failed"` with error in `detail`. Continue to next action. Note in recap. |
| POST /feedback returns 409 from a second tab | Page shows error toast "Feedback already submitted". Expected; harmless — the first submit stands. |
| Server gone when Finish is clicked | `fetch('/shutdown')` network error; page shows "Safe to close this window" toast. |
| All ports busy | Unchanged from original design (fail with lsof hint). |
