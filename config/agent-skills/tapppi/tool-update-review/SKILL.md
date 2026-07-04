---
name: tool-update-review
description: >
  Generate an interactive changelog review page for pending tool updates —
  brew/Brewfile packages, mise runtimes, and standalone CLIs (Claude Code,
  Codex) — with agent-written headliners, canonical changelog/release/blog
  links, and relevancy analysis against this machine and the user's setup
  repos (macos-setup, dotfiles, systems). Use this whenever the user asks to
  check tool updates, review changelogs, see what's outdated, asks "what's new
  in <tool>", wants headliner changes since a version, or wants update
  suggestions reviewed/applied — even if they only mention one tool or say
  something casual like "anything interesting in the latest brew updates?".
---

# Tool Update Review

Produce a per-tool changelog review the user acts on in the browser: version
deltas, headline changes, links to canonical sources, findings about *their*
environment, and concrete suggested edits they Accept / Reject / Discuss.
Decisions come back into the session as `feedback.json` and accepted edits are
applied to the setup repos.

Schemas, page/interaction spec, server contract, and failure modes live in
`references/design.md` — read it before assembling the report or rendering,
and follow its schema exactly (`schema_version: 1`).

## Workflow

### 1. Collect candidates

Run `scripts/collect.sh` from the macos-setup repo root (pass the Brewfile
path if elsewhere). It emits machine context plus outdated tools from three
sources: Brewfile-manifested brew/cask packages (transitive deps excluded,
pinned formulae included — a pin usually marks a *known* incompatibility worth
re-checking, not a tool to skip), mise runtimes, and standalone CLIs.

If the user scoped the request ("just podman", "only claude"), filter the
candidate list before researching.

### 2. Research each tool (parallel subagents)

Spawn one research subagent per tool, all in one turn. Each gets: the tool's
id/name/source/versions, the machine context (arch matters — ARM-only
dependencies are incompatibilities on x86_64, not footnotes), and the paths it
may scan for relevancy. Each returns a partial Tool object per
`references/design.md` A.1: `headliners`, typed `links`, `relevancy`,
`suggestions`.

Research quality bar:
- **Headliners**: ≤6 bullets covering the whole current→latest range, not just
  the newest release. Skim actual release notes/changelogs — don't guess from
  version numbers.
- **Links**: always the canonical changelog for the version range; add release
  pages for majors and official blog posts when they exist. Every relevancy
  finding and suggestion should be traceable to a link.
- **Relevancy is the point of this skill.** Scan the user's setup repos —
  `~/project/github/tapppi/macos-setup` (Brewfile, intel.Brewfile, tasks/,
  dotfiles/ submodule with shell/git/tmux/Claude configs) and
  `~/project/github/tapppi/systems` (NixOS flake) — plus machine facts, for
  places the tool is configured or its changed behavior lands. Severity:
  `incompatible` (won't work here — e.g. new major requires Apple Silicon on
  an Intel machine) > `warning` (breaks a config/workflow the user has) >
  `notable` (touches something they use) > `info`. Cite evidence as
  `file:line` paths.
- **Suggestions** are concrete edits: target file, rationale, motivating link,
  and a short `diff_preview`. Only suggest what the changelog actually
  motivates. No suggestion is fine — most tools just get headliners.
- **Hold subagents to the exact schema shapes** (spell them out in the
  research prompt): `evidence` is always an array, suggestions always use
  `title`/`target_files`/`rationale`/`motivating_link`/`diff_preview`.
  Loose shapes (bare strings, ad-hoc `description` fields) force hand
  normalization during assembly and have caused real rework.
- **Depth by tool**: node semi-detailed (security advisories, breaking
  changes, notable features per minor); other runtimes coarse (breaking
  changes and majors only); everything else proportional to how much the user
  configures it.
- **The fleet has heterogeneous hosts** (until the eventual nix migration):
  `Brewfile` manifests the Apple Silicon host(s), `intel.Brewfile` the Intel
  host(s), and `tasks/*.sh` contain arch-conditional blocks. The collector's
  `machine` block describes only the host running this review. Assess impact
  per affected host/manifest — the same update can be `incompatible` on one
  host and desirable on the other (e.g. an ARM-only major on an Intel
  machine). Set severity to the worst affected host, spell out the per-host
  split in `detail`, and make each suggestion's `target_files` name the
  specific manifest(s) it touches (a Brewfile edit usually needs a decision
  about its intel counterpart, not a blind mirror).

On subagent failure/timeout, set `research_error` and keep the tool listed
with versions only.

### 3. Assemble and render

Merge collect + research into the report object (design.md A.1): compute
`summary` counts, ensure suggestion ids are unique
(`{source}:{name}:{slug}`), verify evidence paths exist (warn, don't drop).
Write `report.json` to the session dir, then:

```sh
python3 scripts/render.py /tmp/tool-update-review-{report_id}/report.json
```

which injects it into `assets/report-template.html` and writes `index.html`
plus a copy of `server.py` next to it.

### 4. Serve and wait

Start the server loopback-only (extra `--bind` listeners only if the user
asks):

```sh
python3 {session_dir}/server.py {session_dir} &
```

Poll `GET /health` until 200 (≤5 s). Then pick URLs by session type — decide
at runtime, never hardcode hostnames (there are multiple server hosts):

- **Remote session** (`SSH_CONNECTION` or `SSH_TTY` set): the user's browser
  is on another machine, so *by default* also start a **foreground**
  `tailscale serve --set-path /updates {port}` as a background task (never
  `--bg`; foreground config dies with the session). Print both URLs:
  `https://$(tailscale status --json | jq -r '.Self.DNSName' | sed 's/\.$//')/updates`
  and the loopback URL. Kill the serve task after feedback lands.
- **Local session**: loopback URL only, and `open` it. Tailnet serving only
  on request.

Block on the server process exiting — it shuts itself down after a
successful `POST /feedback` writes `feedback.json`. Time out after 30 min:
offer to re-open the page or abandon. Don't kill the server while the user
might still be reviewing.

### 5. Apply feedback

Read `{session_dir}/feedback.json` (validate `report_id`). Then:

- **accept** → apply the edit now. Respect repo conventions: paths under
  `dotfiles/` are edited in the submodule and copied to their deploy target;
  `Brewfile` changes are mirrored to `intel.Brewfile` when applicable; commit
  per the repos' CLAUDE.md rules (specific paths, imperative messages, no
  AI attribution).
- **discuss** (or any decision with a comment) → after the apply pass, raise
  each item in conversation with the tool, suggestion title, and the user's
  comment. Don't apply until the user confirms.
- **reject** / undecided → skip, but list in the summary.

Finish with a summary: applied edits (with commits), rejected, discussion
items, tool notes, and the overall comment if present.

## Notes

- The report page is fully offline (no CDN). The tailscale serve proxy
  needs no firewall approval and serves tailnet-only HTTPS; the `/updates`
  path mount leaves the root hostname free for other serves. The page and
  server are subpath-tolerant (relative feedback URL, suffix routing), so
  they work at `/` and behind the mount alike. Never bind `0.0.0.0` or LAN
  interfaces without asking — the report exposes config details.
- Restarting the server mid-review is safe: page state lives in the open
  tab; same port + `report_id` keep Submit working. macOS quirk: a machine
  can't reach its *own* tailscale IP (utun hairpin) — verify locally
  against 127.0.0.1, remotely via tailscale.
- Pinned tools: never suggest unpinning unless the blocking reason is verified
  gone in the new version — the pin exists because an upgrade broke something.
- The user never wants `brew upgrade`/installs run by the agent; this skill
  reviews and edits manifests/configs, upgrades happen via their setup tasks.
