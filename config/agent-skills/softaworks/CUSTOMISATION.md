# softaworks — vendored skills

Unlike `anthropics/` and `google/` (full `git subtree` mirrors), this vendor
holds only a **sparse** copy of selected skills from
[`softaworks/agent-toolkit`](https://github.com/softaworks/agent-toolkit) — the
upstream repo is a 40+ skill collection and we want just one. The sparse copy is
refreshed by `sync-upstream.sh` (see its `sparse_vendors` table), not by
`git subtree pull`.

## Adopted skills

- `jira/` — Jira via the `ankitpokhrel/jira-cli` (`jira`) CLI, with an Atlassian
  MCP fallback. Upstream path: `skills/jira`.

  **Project-scoped, not global.** Not symlinked anywhere (not exposed to
  OpenCode). For Claude Code it's listed as a plugin in the `tapppi-skills`
  marketplace (`config/agent-skills/.claude-plugin/marketplace.json`) and
  enabled per repo by the parent `macos-setup` repo's `./setup.sh projects`
  task, driven by a gitignored `.tapppi-project.json` workspace manifest's
  `plugins` block. The Jira instance and API token are provisioned per
  workspace via a generated, gitignored `mise.local.toml` that loads a local
  0600 dotenv file.

## Provenance

- Source: `https://github.com/softaworks/agent-toolkit`
- Branch: `main`
- Last synced commit: `3027f20f3181758385a1bb8c022d4041dfb4de84`
- License: MIT — upstream repo-root `LICENSE`, "Copyright (c) 2026 Leonardo
  Flores", copied here verbatim as `softaworks/LICENSE` (byte-identical to
  the upstream blob `fc473440ee9ae27aa3d774bcd3888496ef0fad2d`).

## Licence

MIT's only condition is a notice one: "The above copyright notice and this
permission notice shall be included in all copies or substantial portions of
the Software." This repo is public, so vendoring `skills/jira` here *is* a
copy that has to carry the notice — and it did not, because the sparse copy
takes only `skills/jira` and upstream keeps `LICENSE` at the repo root.
Hence `softaworks/LICENSE`.

**It sits at vendor level, not inside `jira/`, and that placement matters.**
`sync-upstream.sh` refreshes a sparse vendor with
`rsync -a --delete … "${tmp}/repo/${subpath}/" "${dest}/"`, where `${dest}`
is `softaworks/jira`. Anything in that directory with no counterpart under
upstream's `skills/jira` is deleted on the next sync — so a
`softaworks/jira/LICENSE` would silently vanish the first time the skill was
refreshed, putting the repo back out of compliance with no signal. One level
up, next to this file, is outside the mirror and survives.

The corollary: every skill sparse-vendored into `softaworks/` must come from
this same MIT-licensed upstream. A skill from a different repo, or from an
upstream that relicenses, needs its own vendor directory with its own
`LICENSE` — do not let a second provenance shelter under this one.

## Local patches

(none — `LICENSE` is not a patch to upstream content; it is upstream's own
repo-root file, carried alongside the sparse copy rather than inside it.)
