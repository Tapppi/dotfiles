# agent-skills (OpenCode and other agents)

Canonical tree for agent skills, synced to `~/.config/agent-skills/`.
Both `~/.claude/skills/<skill>` and `~/.config/opencode/skills/<skill>`
are symlinks into here.

- `tapppi/` — my own skills (source of truth for `browser`,
  `subrepo-permissions`, etc.)
- `anthropics/`, `google/` — `git subtree` of upstream skill repos.
  Adopted skills are symlinked into the agent skill dirs; non-adopted
  upstream content stays on disk but isn't exposed.
- `softaworks/` — sparse vendor (single `jira` skill, not a full subtree).
- `sync-upstream.sh` — pulls upstream subtrees (and refreshes sparse
  vendors) and prints per-skill diffs for review.
- Per-vendor `CUSTOMISATION.md` lists adopted skills and local patches.

Skills can be **global** (symlinked from `home/.claude/skills/` +
`config/opencode/skills/`) or **per-project** (linked into a specific
repo's `.claude/skills/` by the parent `macos-setup` repo's
`./setup.sh projects` task, driven by a gitignored `.tapppi-project.json`
workspace manifest). `jira` and the Google Cloud skills are project-scoped,
not global. See [README.md](README.md).

See [README.md](README.md) for the full layout, adoption workflow,
upstream-sync process, and customisation guidance.
