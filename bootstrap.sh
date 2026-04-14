#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")" || exit

git pull origin

doIt() {
	# Sync home-level dotfiles to ~/
	rsync \
		--exclude ".git/" \
		--exclude ".git" \
		--exclude ".DS_Store" \
		-avh --no-perms home/ ~

	# Sync config to ~/.config/
	rsync \
		--exclude ".git/" \
		--exclude ".git" \
		--exclude ".DS_Store" \
		-avh --no-perms config/ ~/.config/

	# Install custom keyboard layout bundles
	mkdir -p ~/Library/Keyboard\ Layouts
	cp -R keyboard-layouts/*.bundle ~/Library/Keyboard\ Layouts/

	# shellcheck source=/dev/null
	source ~/.bash_profile
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
