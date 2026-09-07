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

OpenCode 1.15.12 reads a repo's `.claude/skills/` and `.agents/skills/`
natively and recursively, so per-project delivery does work there — a skill
committed in a repo is picked up with no symlink and no config. It also has its
own JS/TS plugin system under `.opencode/plugins/`, though that is an
event-hook module format, not a skill bundle.

The symlinks in `config/opencode/skills/` therefore make a skill *globally*
available in every OpenCode session; they are not the only way to reach it.
`jira` and the Google Cloud skills carry no such symlink, so they are not global
in OpenCode — but a repo that commits them reaches OpenCode like any other
harness.

See [README.md](README.md) for the full layout, adoption workflow,
upstream-sync process, and customisation guidance.
