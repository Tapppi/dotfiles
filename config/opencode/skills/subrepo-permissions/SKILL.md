---
name: subrepo-permissions
description: Generate git -C permission rules in .claude/settings.local.json for nested git repos in a project directory
---

# Subrepo Permissions Generator

Generates `git -C <subrepo>` permission entries for all nested git repositories
in a project directory and merges them into `.claude/settings.local.json`.

## Usage

Run the script with the target project directory as the argument. If called
without arguments, use the current working directory.

```sh
bash ~/.claude/skills/subrepo-permissions/subrepo-permissions.sh <project-dir>
```

The script lives in the Claude Code skills directory but works standalone.

The script:
- Finds immediate subdirectories that are git repos (`.git` dir or gitlink)
- Generates **allow** entries for all standard git read/write commands with
  `-C <subrepo-name>` (status, log, diff, add, commit, branch, etc.)
- Generates **ask** entries for `git push` (requires user approval)
- Merges into `.claude/settings.local.json` using `jq`, replacing any
  existing `-C` entries
- Is idempotent — safe to run repeatedly

After running, show the user the resulting file.
