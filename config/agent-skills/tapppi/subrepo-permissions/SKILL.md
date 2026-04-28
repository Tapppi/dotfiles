---
name: subrepo-permissions
description: Generate git -C permission rules in .claude/settings.json (and opencode.json if present) for nested git repos in a project directory
disable-model-invocation: true
allowed-tools:
  - Bash(bash ~/.config/agent-skills/tapppi/subrepo-permissions/subrepo-permissions.sh *)
  - Bash(bash ~/.config/agent-skills/tapppi/subrepo-permissions/subrepo-permissions.sh)
  - Bash(cat */.claude/settings.json)
  - Bash(cat */opencode.json)
  - Bash(cat */.opencode/opencode.json)
---

# Subrepo Permissions Generator

Generates `git -C <subrepo>` permission entries for all nested git repositories
in a project directory and merges them into the project's agent settings:

- Always updates `.claude/settings.json` (created if missing).
- Also updates OpenCode permissions in `opencode.json` (or
  `.opencode/opencode.json`) **only if that file already exists** at the
  repo — the script does not opt the project into OpenCode.

These are repo-level settings (committed alongside the project), not local
overrides — `.claude/settings.json` is the right home for them, and
OpenCode's `permission.bash` section is the equivalent.

## Usage

Run the script with the target project directory as the argument. If called
without arguments or with `$ARGUMENTS`, use the argument as the project path
(default: current working directory).

```sh
bash ~/.config/agent-skills/tapppi/subrepo-permissions/subrepo-permissions.sh <project-dir>
```

The script:
- Finds immediate subdirectories that are git repos (`.git` dir or gitlink)
- For Claude Code (`.claude/settings.json`):
  - **allow** entries for all standard git read/write commands with
    `-C <subrepo-name>` (status, log, diff, add, commit, branch, etc.)
  - **ask** entries for `git push`
- For OpenCode (`opencode.json` or `.opencode/opencode.json`, if present):
  - Same patterns mapped under `permission.bash` as
    `"git -C <subrepo> <cmd>": "allow"` / `"ask"`. OpenCode evaluates
    rules with last-match-wins, so the script appends after existing
    entries.
- Merges idempotently — existing `git -C` entries (Claude allow/ask
  arrays, OpenCode bash keys) are stripped before re-adding.

After running, show the user the resulting file(s).

$ARGUMENTS
