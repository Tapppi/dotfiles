# Claude Code user-level config

Source of truth for `~/.claude/`. Synced from `dotfiles/home/.claude/` by
`bootstrap.sh` in the parent dotfiles repo.

## Files

| File                    | Purpose                                                            |
| ----------------------- | ------------------------------------------------------------------ |
| `settings.json`         | User-level Claude Code settings (model, effort, env, status line). |
| `keybindings.json`      | Customized keyboard bindings.                                      |
| `statusline-command.sh` | Status line script (model, dir, ctx tokens, rate-limit countdown). |
| `CLAUDE.md`             | User-level instructions, generated from dotfiles `agents/`; edit there. |

The status line shows the model, directory, session start time, context tokens (coloured by
token-count thresholds), rate-limit percentages and the countdown to reset, in Solarized Dark
colours.

## Notable `settings.json` choices

### `env` block — telemetry vs `/remote-control`

The four granular `DISABLE_*` vars covered by the
`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` umbrella are:
`DISABLE_AUTOUPDATER`, `DISABLE_ERROR_REPORTING`, `DISABLE_TELEMETRY`,
`DISABLE_FEEDBACK_COMMAND`.

We set three of them. `DISABLE_TELEMETRY` is intentionally **omitted**
because it gates `/remote-control` eligibility — with telemetry disabled
the slash command is hidden and the bridge to `claude.ai/code` is blocked.

To go fully telemetry-off (and give up `/remote-control`), replace the
granular vars with a single `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`.

`CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1` is set independently — outside the
umbrella, separate concern.

### `statusLine.refreshInterval: 300`

Re-runs the status line script every 5 minutes so the rate-limit
countdown and session clock keep ticking even when no tool calls happen.
