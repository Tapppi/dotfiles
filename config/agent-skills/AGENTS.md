# agent-skills (OpenCode and other agents)

Canonical tree for agent skills, synced to `~/.config/agent-skills/`.
Both `~/.claude/skills/<skill>` and `~/.config/opencode/skills/<skill>`
are symlinks into here.

- `tapppi/` — my own skills (source of truth for `browser`,
  `subrepo-permissions`, etc.)
- `anthropics/`, `google/` — `git subtree` of upstream skill repos.
  Adopted skills are symlinked into the agent skill dirs; non-adopted
  upstream content stays on disk but isn't exposed.
- `sync-upstream.sh` — pulls upstream subtrees and prints per-skill
  diffs for review.
- Per-vendor `CUSTOMISATION.md` lists adopted skills and local patches.

See [README.md](README.md) for the full layout, adoption workflow,
upstream-sync process, and customisation guidance.
