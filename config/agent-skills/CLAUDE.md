# agent-skills (Claude Code)

Canonical tree for agent skills, synced to `~/.config/agent-skills/`.
For OpenCode, `~/.config/opencode/skills/<skill>` symlinks into here (see
AGENTS.md). For Claude Code, skills are delivered as plugins instead of
symlinks — see below.

- `tapppi/` — my own skills (source of truth for `browser`,
  `subrepo-permissions`, etc.)
- `anthropics/`, `google/` — `git subtree` of upstream skill repos.
  Adopted skills are listed as plugins in `.claude-plugin/marketplace.json`
  (see below); non-adopted upstream content stays on disk but isn't exposed.
- `softaworks/` — sparse vendor (single `jira` skill, not a full subtree).
- `sync-upstream.sh` — pulls upstream subtrees (and refreshes sparse
  vendors) and prints per-skill diffs for review.
- `.claude-plugin/marketplace.json` — the `tapppi-skills` local plugin
  marketplace (registered via `claude plugin marketplace add
  ~/.config/agent-skills`). Every adopted skill (own + upstream) is listed
  here as an individually-enableable plugin, without touching the vendored
  upstream content itself: marketplace entries use `"strict": false` to
  supply name/description inline, except `browser`, which has its own
  `.claude-plugin/plugin.json` + `.mcp.json` bundling the Playwright and
  Chrome DevTools MCP servers it depends on (namespaced as
  `browser-playwright` / `browser-chrome-devtools` so they don't collide
  with any other plugin's identically-purposed server).
- Per-vendor `CUSTOMISATION.md` lists adopted skills and local patches.

Plugins can be enabled **globally** (`claude plugin install
<name>@tapppi-skills --scope user`, e.g. `docx`, `pdf`, `pptx`, `xlsx`,
`skill-creator`, `subrepo-permissions`) or **per-project** (enabled at
local scope by the parent `macos-setup` repo's `./setup.sh projects` task,
driven by a gitignored `.tapppi-project.json` workspace manifest's
`plugins` block — e.g. `jira` and the Google Cloud skills; see
`tasks/projects.sh`). Unlike raw skills, Claude Code has no `enabledSkills`
toggle, so this per-project scoping only works once a skill is packaged
as a plugin — that's why every skill here is, even ones that stay global.

See [README.md](README.md) for the full layout, adoption workflow,
upstream-sync process, and customisation guidance.
