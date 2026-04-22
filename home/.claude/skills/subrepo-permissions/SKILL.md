---
name: subrepo-permissions
description: Generate git -C permission rules in .claude/settings.local.json for nested git repos in a project directory
disable-model-invocation: true
allowed-tools:
  - Bash(bash ~/.claude/skills/subrepo-permissions/subrepo-permissions.sh *)
  - Bash(bash ~/.claude/skills/subrepo-permissions/subrepo-permissions.sh)
  - Bash(cat */.claude/settings.local.json)
---

# Subrepo Permissions Generator

Generates `git -C <subrepo>` permission entries for all nested git repositories
in a project directory and merges them into `.claude/settings.local.json`.

## Usage

Run the script with the target project directory as the argument. If called
without arguments or with `$ARGUMENTS`, use the argument as the project path
(default: current working directory).

```sh
bash ~/.claude/skills/subrepo-permissions/subrepo-permissions.sh <project-dir>
```

The script:
- Finds immediate subdirectories that are git repos (have `.git`)
- Generates **allow** entries for all standard git read/write commands with
  `-C <subrepo-name>` (status, log, diff, add, commit, branch, etc.)
- Generates **ask** entries for `git push` (requires user approval)
- Merges into `.claude/settings.local.json` using `jq`, replacing any
  existing `-C` entries
- Is idempotent — safe to run repeatedly

After running, show the user the resulting file.

$ARGUMENTS
