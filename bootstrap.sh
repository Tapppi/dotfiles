#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")" || exit

git pull origin

doIt() {
	rsync --exclude ".git/" \
		--exclude ".git" \
		--exclude ".gitattributes" \
		--exclude ".DS_Store" \
		--exclude ".editorconfig" \
		--exclude "bootstrap.sh" \
		--exclude "README.md" \
		--exclude "LICENSE-MIT.txt" \
		--exclude "keyboard-layouts/" \
		--exclude "/AGENTS.md" \
		--exclude "/CLAUDE.md" \
		-avh --no-perms . ~
	# Lazygit is looking in Application Support because we do not yet use XDG_CONFIG_HOME
	mkdir -p ~/Library/Application\ Support/lazygit
	cp -f ~/.config/lazygit/config.yml ~/Library/Application\ Support/lazygit/config.yml

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
