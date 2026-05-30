# agent-skills (Claude Code)

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
`config/opencode/skills/`) or **repo-level** (linked into a specific
repo's `.claude/skills/` via a gitignored `.local-skills.json` manifest
and the parent repo's `./setup.sh skills` task). `jira` and the Google
Cloud skills are repo-level only. See [README.md](README.md).

See [README.md](README.md) for the full layout, adoption workflow,
upstream-sync process, and customisation guidance.
