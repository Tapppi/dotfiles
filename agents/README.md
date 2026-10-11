# agents/

The sources of the user-level agent instructions, the script that renders them, and the
user-level `my-machine-configs` skill. Nothing here is synced by `bootstrap.sh`; the rendered
outputs are.

## Rendering

`core.md` is the shared core, and one header per harness adds what differs in that harness.
`render.sh` writes header plus core into each output: the header's frontmatter (if it has any), a
one-line banner naming the sources, the rest of the header, a blank line, then `core.md`. The
outputs are committed and deployed by the ordinary sync.

| Header | Output | Deployed to |
| --- | --- | --- |
| `claude-code.md` | `home/.claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `codex.md` | `home/.codex/AGENTS.md` | `~/.codex/AGENTS.md` |
| `opencode.md` | `config/opencode/AGENTS.md` | `~/.config/opencode/AGENTS.md` |
| `cursor.md` | `home/.cursor/rules/00-environment.mdc` | `~/.cursor/rules/00-environment.mdc` |
| `pi.md` | `home/.pi/agent/AGENTS.md` | `~/.pi/agent/AGENTS.md` |

- Edit here, run `agents/render.sh`, and commit the sources and outputs together. Never edit an
  output by hand: `agents/render.sh --check` fails on a hand edit or a stale render.
- The ChatGPT/Codex app's custom-instructions pane writes `~/.codex/AGENTS.md`, and the next sync
  overwrites that edit; carry a wanted change in here. A `~/.codex/AGENTS.override.md` would
  replace the file; none is used.
- While `~/.config/opencode/AGENTS.md` exists, OpenCode does not read `~/.claude/CLAUDE.md`, and
  Cursor never reads it, hence their own outputs.
- Pi reads one user-level context file, `AGENTS.override.md`, `AGENTS.md` or `CLAUDE.md` (first
  match) in `~/.pi/agent/` (or `$PI_CODING_AGENT_DIR`), then one per directory from the
  filesystem root down to the working directory, all concatenated. It never reads
  `~/.claude/CLAUDE.md` or follows `@` imports, `--no-context-files` turns discovery off, and
  `/reload` re-reads the files in a running session. Do not render `SYSTEM.md` or
  `APPEND_SYSTEM.md`, which replace or extend Pi's own system prompt.

## What goes where

The instructions are always loaded, so they hold only how the agent should act, plus pointers:

- `core.md`: the working baseline (platform, tools, secrets, git, signing, untrusted input), a
  short map of the repos that configure the machine, the rules for changing config, and the
  pointer to `my-machine-configs`.
- The headers: what the harness is, the lines an agent acts on in that harness, and a pointer to
  the harness's reference in `my-machine-configs`.
- `skills/my-machine-configs/`: the machine specifics an agent needs only when it changes the
  machine's configuration: where each harness keeps its config, what is tracked and what tools
  own, how changes deploy, PATH and credentials. It links into the repos' docs for depth.

Name a concrete config value in the instructions only where the agent must act on it; anything
else duplicates the config and drifts. Harness permissions, for one, live in harness config
(`settings.json`, `cli-config.json`, `opencode.json`, Codex's layers): the instructions and the
skill say where they are configured, never what the rules are. Rules (every "never", secret
handling, signing, approvals, untrusted input, changing config at its source, re-running the
owning tool) stay always-on, never in the skill, and so does the agent-skills section of
`core.md`.

## The `my-machine-configs` skill

`skills/my-machine-configs/` is a plain skill directory: `SKILL.md` and `references/`. macos-setup
installs it for each harness from this checkout, always through macos-setup's main worktree:

- Claude Code (which OpenCode and Cursor also read): an absolute link at
  `${CLAUDE_CONFIG_DIR:-~/.claude}/skills/my-machine-configs`;
- Codex: an absolute link at `${CODEX_HOME:-~/.codex}/skills/my-machine-configs`;
- Pi: `pi install <dotfiles>/agents`, which loads `agents/skills/` as a package.

So an edit here is live as soon as it is on the main checkout's branch; nothing renders it. Keep
`SKILL.md` and each reference at or under about 200 lines and 2000 tokens, and keep everything in
it fit for a public repo.
