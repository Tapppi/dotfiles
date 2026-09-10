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
  vendors) and prints per-skill diffs for review. Honours each vendor's
  excluded-paths list: upstream content this public repo has no right to
  redistribute — `anthropics/skills/{docx,pdf,pptx,xlsx}` (proprietary
  licence) and `anthropics/skills/doc-coauthoring` (no licence file at
  all, upstream included; absence of a grant is not permission) — is
  filtered out of the squash commit itself, so a pull can never re-add
  it. See `anthropics/CUSTOMISATION.md`. Never `git subtree pull` such a
  vendor by hand.
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
- Per-vendor `CUSTOMISATION.md` lists adopted skills, excluded paths,
  upstream licence provenance and local patches. A vendored copy carries
  the upstream licence: `google/LICENSE` and `anthropics/skills/*/LICENSE.txt`
  arrive with the subtree, and `softaworks/LICENSE` is copied in by hand
  because the sparse vendor takes only `skills/jira` while upstream keeps
  its MIT licence at the repo root.

Plugins can be enabled **globally** (`claude plugin install
<name>@tapppi-skills --scope user`, e.g. `skill-creator`,
`subrepo-permissions`) or **per-project** (enabled at
local scope by the parent `macos-setup` repo's `./setup.sh projects` task,
driven by a gitignored `.tapppi-project.json` workspace manifest's
`plugins` block — e.g. `jira` and the Google Cloud skills; see
`tasks/projects.sh`). Unlike raw skills, Claude Code has no `enabledSkills`
toggle, so this per-project scoping only works once a skill is packaged
as a plugin — that's why every skill here is, even ones that stay global.

## Reaching a skill without vendoring it

Not everything wanted has to live in this tree. A skill this public repo
may not carry is reached instead by *naming* its upstream marketplace in
the tracked `home/.claude/settings.json`: an `extraKnownMarketplaces`
entry plus an `enabledPlugins` key. Claude Code fetches the plugin itself
at use time.

That is how Anthropic's document skills come back after being dropped
from the vendored tree — `extraKnownMarketplaces.anthropic-agent-skills`
(source `github`, repo `anthropics/skills`) and
`"document-skills@anthropic-agent-skills": true`. A plugin namespaces its
skills under the *plugin* name, so these arrive as `document-skills:docx`,
`:pdf`, `:pptx`, `:xlsx`. The retired `tapppi-skills` entries were one
plugin per skill, so the same four used to appear as `docx:docx`,
`pdf:pdf`, `pptx:pptx`, `xlsx:xlsx` — anything referring to them by those
old names needs updating.

Naming a marketplace and enabling a plugin copies nothing into this repo,
which is precisely why it is legitimate where vendoring was not. Two
consequences worth holding onto:

- It is **machine-local and sync-gated**. The setting is committed, but it
  reaches a machine only on the next `bootstrap.sh` run, and the plugin
  itself is fetched from GitHub at use time.
- It is **Claude-Code-only**. OpenCode does not read `enabledPlugins`, so
  a skill delivered this way is unavailable there (see AGENTS.md). Do not
  answer that gap by vendoring the skill.

Prefer this route over vendoring for any upstream content whose licence
does not clearly permit redistribution.

See [README.md](README.md) for the full layout, adoption workflow,
upstream-sync process, and customisation guidance.
