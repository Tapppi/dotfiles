# User-level Claude Code configuration

## Claude Code config ownership

- `settings.json` is the synced entrypoint for Claude Code user-level settings
  (effort level, status line).
- `keybindings.json` is the customized keyboard binding configuration.
- `statusline-command.sh` is the status line script showing model, directory,
  session start time, context tokens (with token-count-based color thresholds),
  rate limit percentages, and countdown to reset, in Solarized Dark colors.
- User-level MCP servers (e.g. context7) are managed via `claude mcp add
  --scope user` and stored in `~/.claude.json`; that file is not tracked because
  it contains auto-generated state. The `macos-setup` repo configures these
  via `tasks/config.sh`.
- This repo does not keep MCP servers that duplicate Claude Code built-in
  capabilities (git, tmux, SSH, web search, file operations all work natively
  via the Bash tool).

## Long-running Processes and tmux

- For multi-step workflows, persistent processes, dev servers, database sessions,
  or long-lived scripts: **create a new tmux window** in the user's existing
  project session instead of running them in the background or spawning new
  sessions. Name the window descriptively (e.g. `tmux new-window -n devserver`).
- For containerised workloads: attach to the container, stream logs, or exec
  into it as appropriate for the task — don't just fire-and-forget.
- Prefer keeping long-running output visible and accessible over hiding it.

## Agent Context Files (CLAUDE.md / AGENTS.md)

- Projects may have both `CLAUDE.md` (for Claude Code) and `AGENTS.md` (for
  OpenCode and other agents), plus `.local.md` variants (`CLAUDE.local.md`,
  `AGENTS.local.md`) for machine-specific overrides that are gitignored.
- When editing agent context files, always check whether the counterpart
  file also exists in the same directory and update both to keep them in
  sync. This applies to the base files and to `.local.md` variants.

## Git Workflow

- If the project has no `CLAUDE.md` with commit/branch conventions, check
  `git log --oneline -20` for commit message style before committing and
  `git branch -a` for branch naming patterns before creating branches.
- **Only commit changes from the current agent session.** Do not stage
  unrelated edits or pre-existing unstaged changes unless explicitly told to.
- When work is complete and no further user input is needed, commit it
  (but do not push) so the user can review with git-based tools.
- Prefer atomic commits: one logical change per commit. Split large changes
  into meaningful pieces.

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
  requests, issues, checks, and releases. Prefer `gh` over WebFetch or
  web scraping for GitHub operations. Always pass explicit flags (`--repo`,
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
