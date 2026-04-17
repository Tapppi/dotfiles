#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")" || exit

git pull origin

doIt() {
	# Sync home-level dotfiles to ~/
	rsync \
		--exclude ".DS_Store" \
		-avh --no-perms home/ ~

	# Sync config to ~/.config/
	rsync \
		--exclude ".DS_Store" \
		-avh --no-perms config/ ~/.config/

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
unset doIt
