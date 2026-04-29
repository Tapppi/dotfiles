# agent-skills

Source-of-truth tree for all agent skills used by Claude Code and OpenCode.
Synced to `~/.config/agent-skills/` by `bootstrap.sh`. Both
`~/.claude/skills/<skill>` and `~/.config/opencode/skills/<skill>` are
symlinks pointing here, so a single edit (or upstream pull) updates both
agents.

## Layout

```
agent-skills/
  CLAUDE.md  AGENTS.md  README.md       # this file is the canonical doc
  sync-upstream.sh                      # subtree pull + per-skill diff
  tapppi/                               # my own skills
    browser/  subrepo-permissions/  ...
  anthropics/                           # git subtree of anthropics/skills (squashed)
    CUSTOMISATION.md                    # adopted skills + local patches
    skills/                             # upstream layout preserved
      skill-creator/  pdf/  pptx/  docx/  xlsx/  ...
    spec/  template/  README.md  ...    # other upstream content (not symlinked)
  google/                               # git subtree of google/skills (squashed)
    CUSTOMISATION.md
    skills/cloud/
      cloud-run-basics/  cloud-sql-basics/  gke-basics/  ...
    README.md  LICENSE  ...
```

The vendor directories preserve the upstream repo layout exactly so
`git subtree pull` is conflict-free for unmodified content. Adopted
skills are surfaced via symlinks in `dotfiles/home/.claude/skills/` and
`dotfiles/config/opencode/skills/`; non-adopted upstream content stays
on disk but isn't exposed to either agent.

## Adopting / dropping a skill

Adopt: add a symlink in both `home/.claude/skills/<name>` and
`config/opencode/skills/<name>` pointing into the relevant
`agent-skills/<vendor>/skills/[cloud/]<upstream-name>/`. Use the
upstream skill name verbatim — keeps customisations and upstream
references aligned.

Drop: remove the two symlinks. The upstream content stays in the
subtree so the skill can be re-adopted later without re-fetching.

## Updating upstream subtrees

Run `bash config/agent-skills/sync-upstream.sh` (from the dotfiles repo
root). The script:

1. Records each vendor's HEAD commit before pulling.
2. Runs `git subtree pull --prefix=config/agent-skills/<vendor>
   <upstream-url> main --squash` for each vendor.
3. For every adopted skill (the symlink targets), prints a stat-level
   diff between the pre-pull and post-pull state and lists touched
   files. **Always review this output before committing the pull —
   upstream changes may need customisation updates or break our
   symlinked skills.**

Manual subtree commands (if needed):

```sh
# From dotfiles repo root:
git subtree pull --prefix=config/agent-skills/anthropics \
    https://github.com/anthropics/skills main --squash
git subtree pull --prefix=config/agent-skills/google \
    https://github.com/google/skills main --squash
```

Use `--squash` always: each pull collapses to one commit, keeping the
dotfiles history readable. Last-pull SHA is in the squash commit
message (`git log --grep=git-subtree-dir`).

## Customisation workflow

Local patches are normal commits in `dotfiles`. When you patch an
upstream skill, also add a one-liner to the relevant
`<vendor>/CUSTOMISATION.md` so the patch is discoverable on the next
upstream pull (the next `sync-upstream.sh` run will then know to
re-check the patched files for conflicts/drift).

Conflict resolution on `git subtree pull` uses standard `git
mergetool` — no special tooling.

## Adding a new vendor

```sh
git subtree add --prefix=config/agent-skills/<vendor> \
    <upstream-url> main --squash
```

Then add a `CUSTOMISATION.md` inside the new vendor dir, append the
vendor entry to `sync-upstream.sh`, and update this README.

## Why this lives in `config/`

`bootstrap.sh` rsyncs `config/` → `~/.config/`, so the canonical tree
lands at `~/.config/agent-skills/` automatically. Symlinks under
`home/.claude/skills/` and `config/opencode/skills/` resolve there at
agent runtime — one tree on disk, two agent-facing views.
