# AGENTS.md

## OpenCode config ownership

- `opencode.json` is the synced entrypoint that loads `oh-my-openagent` and
  `opencode-claude-auth`.
- `oh-my-openagent.json` is the tracked companion config for agent/category
  model selection.
- This repo does not keep a separate hand-maintained mirror of every bundled
  MCP server or skill shipped by `oh-my-openagent`; those stay plugin-managed.
- Claude auth stays explicit via the dedicated `opencode-claude-auth` plugin.
- No extra tmux/git-specific wrapper config is tracked here; the setup relies
  on built-in platform capabilities and the shared OpenAgent config.

## Agent Context Files (CLAUDE.md / AGENTS.md)

- Projects may have both `CLAUDE.md` (for Claude Code) and `AGENTS.md` (for
  OpenCode and other agents), plus `.local.md` variants (`CLAUDE.local.md`,
  `AGENTS.local.md`) for machine-specific overrides that are gitignored.
- When editing agent context files, always check whether the counterpart
  file also exists in the same directory and update both to keep them in
  sync. This applies to the base files and to `.local.md` variants.

## Long-running Processes and tmux

- For multi-step workflows, persistent processes, dev servers, database sessions,
  or long-lived scripts: **create a new tmux window** in the user's existing
  project session instead of running them in the background or spawning new
  sessions. Name the window descriptively (e.g. `tmux new-window -n devserver`).
- For containerised workloads: attach to the container, stream logs, or exec
  into it as appropriate for the task — don't just fire-and-forget.
- Prefer keeping long-running output visible and accessible over hiding it.

## Git Workflow

- If the project has no `AGENTS.md` or docs with commit/branch conventions,
  check `git log --oneline -20` for commit message style before committing
  and `git branch -a` for branch naming patterns before creating branches.
- **Only commit changes from the current agent session.** Do not stage
  unrelated edits or pre-existing unstaged changes unless explicitly told to.
- When work is complete and no further user input is needed, commit it
  (but do not push) so the user can review with git-based tools.
- Prefer atomic commits: one logical change per commit. Split large changes
  into meaningful pieces.

## Platform Gotchas

- **`sed -i` portability**: GNU sed is first in `$PATH` on this machine.
  GNU sed treats `sed -i ''` as an error (interprets the empty string as a
  missing filename). Always use `sed -i.bak` and clean up the `.bak` file
  afterwards — this syntax works identically on both GNU and BSD sed. Never
  use `sed -i ''`.

## Available CLI Tooling

The following tools are available in this environment via Homebrew and mise:

- **Containers**: `podman` with Docker compatibility socket (`$DOCKER_HOST`)
  and compose support, `kubectl`/`helm` for Kubernetes, `kail` for streaming
  pod logs.
- **Cloud**: `gcloud`, `az`/`azcopy`, `terraform`.
- **Data**: `jq`/`yq` for JSON/YAML, `duckdb` for analytical SQL — **use DuckDB
  for ad-hoc data analysis, test result aggregation, CSV/Parquet exploration,
  etc.** unless the project specifies another tool.
- **HTTP**: `curl`, `httpie` (`http`/`https` commands).
- **Databases**: `psql` (via `libpq`), `redis-cli`, `sqlite3`, `kcat` (kafkacat)
  for Kafka topic peeking.
- **Search/files**: `ripgrep` (`rg`), `fd`, `fzf`, `tree`.
- **Git/GitHub**: `git`, `gh` CLI — use `gh` for GitHub code search, pull
  requests, issues, checks, and releases. Prefer `gh` over web fetching or
  scraping for GitHub operations. Always pass explicit flags (`--repo`,
  `--json`, `--jq`, `--limit`, etc.) to avoid interactive prompts.
- **Languages/runtimes**: All runtimes installed via `mise` (node, go, rust,
  python, etc.). Use `uv` for Python dependency management and `uvx` to run
  Python CLI packages — prefer these over `pip install`.
- **Shell**: `bash` 5, `tmux`/`tmuxinator`, `shellcheck`, `parallel`, `pv`
  (pipeviewer for debugging pipe throughput).
- **Documents**: `marp-cli` for Markdown presentations, `ghostscript` for
  PDF manipulation scripting.
- **Media**: `ffmpeg`, `imagemagick`, `exiftool`, `tesseract`.
- **Network**: `nmap`, `mtr`.

If a tool is not available and requires system-level installation, consult
the user or use a containerised environment — do not pollute the user's
system with ad-hoc installs.

## Git Identity and Attribution

- **NEVER** add AI attribution to commits (no `Co-authored-by`, no
  `Ultraworked with`, no agent signatures in commit bodies or trailers).
  Commits must look like normal developer commits.
- **NEVER** change `user.name`, `user.email`, or any git identity
  configuration. The repository owner's identity must remain on all commits.
- **Exception — unattended workflows**: If the agent must commit in an
  unattended context (e.g. CI, cron, background automation) where the
  owner's signing key is unavailable, it may temporarily set a placeholder
  identity to allow the commit to proceed. In this case:
  1. Clearly inform the user that commits were made with a placeholder identity.
  2. Note that these commits need `git rebase` / `git commit --amend` to
     restore the correct author before pushing to a shared remote.
