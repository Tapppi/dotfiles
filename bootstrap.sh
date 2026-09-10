#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")" || exit

git pull origin

# First non-zero rsync status of this run, and this script's own exit status.
# It is the *rsync* code, not a generic 1, so the caller can name the failure:
# macos-setup's install_dotfiles reports "exited 23", and 23 is exactly what a
# --delete mirror whose source directory no longer exists returns. Without this
# every run exited 0 and that failure was invisible.
#
# Deliberately not `set -e`, on three counts: a failing mirror must not skip the
# mirrors after it (aborting halfway leaves ~ *more* half-synced, not less); the
# `git pull` above is allowed to fail on a flaky network without cancelling a
# local sync; and the `[ … ] && source` idioms at the end of doIt rely on a
# false test being harmless.
sync_status=0

# Define Function =run_rsync= — run one sync, reporting rather than swallowing a failure.
# Args: <label> <rsync args...>. Records the first failure in sync_status and
# returns rsync's own status, so callers may keep going.
run_rsync() {
	local label="${1}"
	shift

	local status=0
	rsync "$@" || status=$?

	# 24 means source files vanished mid-transfer — an editor swap file or a
	# .DS_Store rewritten by Finder while rsync walked the tree. Everything else
	# copied, so it is a warning, not a failed sync. Treating it as a failure
	# would skip the herdr/ctx7 re-assertion that runs after this script and
	# leave exactly the half-configured state the gating exists to prevent.
	if [[ "${status}" -eq 24 ]]; then
		echo "bootstrap: ${label} — some source files vanished during transfer (rsync exit 24); the sync itself completed." >&2
		return 0
	fi

	if [[ "${status}" -ne 0 ]]; then
		echo "bootstrap: FAILED to sync ${label} (rsync exit ${status})" >&2
		if [[ "${status}" -eq 23 ]]; then
			echo "bootstrap:   exit 23 is a partial transfer — most often a source directory that no longer exists." >&2
		fi
		[[ "${sync_status}" -eq 0 ]] && sync_status="${status}"
	fi

	return "${status}"
}

doIt() {
	# --force lets rsync replace a destination directory with a symlink (or
	# vice versa) when the source/destination types diverge — needed when
	# tracked entries flip between a regular dir and a symlink (e.g. skill
	# entries moving into config/agent-skills/). Without --force, rsync
	# errors with "cannot delete non-empty directory" and skips the entry.
	# Sync home-level dotfiles to ~/
	run_rsync "home/ -> ~" \
		--exclude ".DS_Store" \
		-avh --no-perms --force home/ ~

	# Sync config to ~/.config/
	run_rsync "config/ -> ~/.config/" \
		--exclude ".DS_Store" \
		-avh --no-perms --force config/ ~/.config/

	# Mirror the agent-skill trees exactly with --delete so that *dropped*
	# skills and symlinks are pruned from ~ (a plain rsync only ever adds, so
	# de-adopted skills would linger and stay globally active). Scoped to dirs
	# fully owned by dotfiles — a global --delete on home/ or config/ would
	# wipe every untracked file in ~ and ~/.config.
	#
	# There is no `home/.claude/skills/` mirror any more. That directory was
	# emptied when the global skill symlinks were replaced by plugins, and then
	# removed; rsync exits 23 on a missing source, so the mirror had been failing
	# on every run. `~/.claude/skills/` is now left alone — the only thing in it
	# is context7-mcp, which `ctx7 setup --claude` owns and which the mirror had
	# to carry an explicit exclude for anyway.
	run_rsync "config/opencode/skills/ -> ~/.config/opencode/skills/ (--delete mirror)" \
		--exclude ".DS_Store" -avh --no-perms --force --delete \
		config/opencode/skills/ ~/.config/opencode/skills/
	run_rsync "config/agent-skills/ -> ~/.config/agent-skills/ (--delete mirror)" \
		--exclude ".DS_Store" -avh --no-perms --force --delete \
		config/agent-skills/ ~/.config/agent-skills/

	# Install custom keyboard layout bundles
	mkdir -p ~/Library/Keyboard\ Layouts
	cp -R keyboard-layouts/*.bundle ~/Library/Keyboard\ Layouts/

	# Apply git identity and signing key from .extra.
	# This runs git config --global, so it persists beyond this shell.
	# Cannot rely on ~/.bash_profile because it guards on PS1 (interactive only).
	# shellcheck source=/dev/null
	[ -f ~/.config/bash/.extra ] && source ~/.config/bash/.extra

	# Source full profile if running interactively
	# shellcheck source=/dev/null
	[ -n "$PS1" ] && source ~/.bash_profile

	# Explicit, and load-bearing: both `[ … ] && source` lines above are false in
	# a non-interactive run, so falling off the end would return 1 after a clean
	# sync — and 0 after a failed one whenever the profile happened to load.
	return "${sync_status}"
}

if [[ "$1" == "--force" ]] || [[ "$1" == "-f" ]]; then
	doIt
else
	read -rp "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1
	echo ""
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt
	fi
fi
unset -f doIt run_rsync

# Both branches above land here: declining the prompt syncs nothing and exits 0,
# and either doIt path exits with the first mirror failure it recorded.
exit "${sync_status}"
