#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE}")"

git pull origin

function doIt() {
	rsync --exclude ".git/" \
		--exclude ".git" \
		--exclude ".gitattributes" \
		--exclude ".DS_Store" \
		--exclude ".osx" \
		--exclude ".editorconfig" \
		--exclude "bootstrap.sh" \
		--exclude "README.md" \
		--exclude "brew.sh" \
		--exclude "LICENSE-MIT.txt" \
		-avh --no-perms . ~
	# Lazygit is looking in Application Support because we do not yet use XDG_CONFIG_HOME
	mkdir -p "~/Library/Application Support/lazygit/"
	cp -f ~/.config/lazygit/config.yml ~/Library/Application\ Support/lazygit/config.yml
	source ~/.bash_profile
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
	doIt
else
	read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1
	echo ""
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt
	fi
fi
unset doIt

cd - >/dev/null 2>&1
