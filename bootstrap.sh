#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")" || exit

git pull origin

# First non-zero rsync status of this run, and this script's own exit status.
# It is the *rsync* code, not a generic 1, so the caller can name the failure:
# macos-setup's install_dotfiles reports the code rsync gave (23 for a
# partial transfer, say). Without this every run exited 0 and that failure
# was invisible.
#
# Deliberately not `set -e`, on three counts: a failing sync step must not skip
# the steps after it (aborting halfway leaves ~ *more* half-synced, not less); the
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
		[[ "${sync_status}" -eq 0 ]] && sync_status="${status}"
	fi

	return "${status}"
}

doIt() {
	# --force lets rsync replace a destination directory with a file or symlink
	# (or vice versa) when the source and destination types diverge; without it
	# rsync errors with "cannot delete non-empty directory" and skips the entry.
	# The tree carries no symlinks today, so this is a general guard, not a
	# case it needs.
	# Sync home-level dotfiles to ~/
	run_rsync "home/ -> ~" \
		--exclude ".DS_Store" \
		-avh --no-perms --force home/ ~

	# Sync config to ~/.config/
	run_rsync "config/ -> ~/.config/" \
		--exclude ".DS_Store" \
		-avh --no-perms --force config/ ~/.config/

	# Nothing is mirrored with --delete: a plain rsync only ever adds, and a
	# --delete on home/ or config/ would wipe every untracked file in ~ and
	# ~/.config. ~/.claude/skills/ and ~/.claude/hooks/ are likewise left alone:
	# dotfiles owns neither, and the tools that write them do.

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
# and either doIt path exits with the first rsync failure it recorded.
exit "${sync_status}"
