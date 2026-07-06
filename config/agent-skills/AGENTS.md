# agent-skills (OpenCode and other agents)

Canonical tree for agent skills, synced to `~/.config/agent-skills/`.
`~/.config/opencode/skills/<skill>` symlinks into here. (Claude Code no
longer uses these symlinks for its own skills — it delivers them as
plugins instead; see CLAUDE.md. `home/.claude/skills/` stays empty.)

- `tapppi/` — my own skills (source of truth for `browser`,
  `subrepo-permissions`, etc.)
- `anthropics/`, `google/` — `git subtree` of upstream skill repos.
  Adopted skills are symlinked into the agent skill dirs; non-adopted
  upstream content stays on disk but isn't exposed.
- `softaworks/` — sparse vendor (single `jira` skill, not a full subtree).
- `sync-upstream.sh` — pulls upstream subtrees (and refreshes sparse
  vendors) and prints per-skill diffs for review.
- Per-vendor `CUSTOMISATION.md` lists adopted skills and local patches.

OpenCode has no per-project scoping or plugin system, so a skill is either
symlinked into `config/opencode/skills/` (globally available in every
OpenCode session) or not exposed to OpenCode at all. `jira` and the
Google Cloud skills are in the latter camp — they're only reachable from
Claude Code, where they're enabled per-project as plugins (see CLAUDE.md).

See [README.md](README.md) for the full layout, adoption workflow,
upstream-sync process, and customisation guidance.
