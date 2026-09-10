# Anthropics Skills — Customisation

Upstream: <https://github.com/anthropics/skills> (branch `main`).

Vendored as a `git subtree` at `config/agent-skills/anthropics/`. See
`config/agent-skills/README.md` for the sync workflow. **Sync this vendor
only through `sync-upstream.sh`, never with a bare `git subtree pull`** —
see "Excluded upstream content" below for why.

## Adopted skills

For OpenCode, symlinks live in `dotfiles/config/opencode/skills/<name>`
pointing at `anthropics/skills/<name>`. For Claude Code, each is listed
as a plugin in the `tapppi-skills` marketplace
(`config/agent-skills/.claude-plugin/marketplace.json`) and enabled
globally via `claude plugin install <name>@tapppi-skills --scope user`
— no symlink or local patch to this vendored tree required:

- `skill-creator`

## Excluded upstream content — do not re-add

`skills/docx`, `skills/pdf`, `skills/pptx` and `skills/xlsx` are
deliberately absent from this tree, and `sync-upstream.sh` keeps them out
(the excluded-paths field of its vendor table). They are **not** open
source. Each ships a `LICENSE.txt` reading "© 2025 Anthropic, PBC. All
rights reserved." whose additional restrictions say users may not:

> Extract these materials from the Services or retain copies of these
> materials outside the Services; Reproduce or copy these materials;
> Create derivative works based on these materials; Distribute,
> sublicense, or transfer these materials to any third party.

(Full text: <https://github.com/anthropics/skills/blob/main/skills/docx/LICENSE.txt>;
the other three are identical. Upstream's README calls them
"source-available, not open source".) The `dotfiles` repo is public, so
carrying them here redistributes them to every reader — the one thing that
licence forbids outright. Every other skill under `skills/` carries an
Apache-2.0 `LICENSE.txt` and is fine to vendor.

Why the sync script has to know, rather than this just being a `git rm`:
a stock `git subtree pull --squash` writes a squash commit whose tree is
the *entire* upstream tree. Even if the merge then dropped these four from
the worktree, every pull would re-add them to reachable history and the
next push would publish them again. `sync-upstream.sh` therefore builds
the squash commit from a filtered tree (`subtree_pull_excluding`): the
paths never enter the squash commit or the merge, and the squash commit
message records what was excluded. That is also why this vendor must not
be pulled by hand.

Want the document skills back? Install them from Anthropic's own
marketplace instead of vendoring them, which is what upstream's README
tells users to do and keeps the copy machine-local:
`claude plugin marketplace add anthropics/skills`, then
`claude plugin install document-skills@anthropic-agent-skills --scope user`.
That is a config change (`enabledPlugins` + `extraKnownMarketplaces` in
`home/.claude/settings.json`), not a vendoring one.

`skills/doc-coauthoring` carries no licence file at all (upstream too, as
of 2026-09). It is not adopted or exposed, and it is not on the excluded
list either. Absence of a licence is not a grant, so treat it as a
candidate for that list rather than for adoption.

## Local patches

- `skills/skill-creator/references/agent-skills-spec.md` (added) +
  `skills/skill-creator/SKILL.md` (references-section bullet added) —
  Surface <https://agentskills.io/specification> from inside the skill
  so authors don't have to discover the URL via the repo-root
  `spec/agent-skills-spec.md` pointer. Could be upstreamed.
- `.claude-plugin/marketplace.json` — upstream's `document-skills` plugin
  entry removed, since it pointed at the excluded `skills/{docx,pdf,pptx,xlsx}`
  paths. Expect a conflict here whenever upstream edits that file; resolve
  it by dropping the entry again. Not for upstreaming.

When adding a local patch, append a bullet here noting:
- File(s) touched
- Reason for the patch
- Whether it should be upstreamed

This list drives conflict checks on `sync-upstream.sh` runs.
