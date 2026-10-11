---
description: This machine's environment and the owner's working baseline, for every session.
alwaysApply: true
---

# Cursor: user-level rules

Generated from dotfiles `agents/`; a hand edit here is lost at the next sync.

## Cursor

- Cursor ignores Claude Code's `skillOverrides`, so it lists the synced claude.ai skills that
  Claude Code hides. They depend on claude.ai's app or connectors; do not load them here.
- Never copy the live `cli-config.json` back into dotfiles: Cursor writes account details into it.
- Machine specifics: the `my-machine-configs` skill, `references/cursor.md`.
