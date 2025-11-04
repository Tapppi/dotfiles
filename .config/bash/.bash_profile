#!/usr/bin/env bash

# Log and time all loads
DEBUG=

TIMEFORMAT="Done: real %2R (user %2U | system %2S)"

# Debug function that only logs and times if DEBUG is set, or if first arg is 1
debug_exec() {
	local force_debug_or_func_name="$1"

	if [ "$force_debug_or_func_name" = "1" ] || [ "$force_debug_or_func_name" = "0" ]; then
		local func_name="$2"
		shift 2
		if [ "$force_debug_or_func_name" = "1" ]; then
			echo "==> $func_name | $@"
			time "$func_name" "$@"
		else
			"$func_name" "$@"
		fi
	elif [ -n "$DEBUG" ]; then
		shift
		echo "==> $force_debug_or_func_name | $@"
		time "$force_debug_or_func_name" "$@"
	else
		shift
		"$force_debug_or_func_name" "$@"
	fi
}

# Load the shell dotfiles, and then some:
# * ~/.extra can be used for other settings you don't want to commit.
# * ~/.path can be used to extend `$PATH`. Loaded last in order to have .exports & co. available
for file in ~/.config/bash/.{credentials,exports,functions,nnn,aliases,bash_prompt,extra,path}; do
	[ -r "$file" ] && [ -f "$file" ] && debug_exec source "$file"
done
unset file

# Set alias 'fck' for 'thefuck'
if which thefuck &>/dev/null 2>&1; then
	eval "$(thefuck --alias fck)"
fi

# Increase max open file descriptors
ulimit -S -n 10000

# Disable history expansion
set +H

# Extended glob pattern matching
shopt -s extglob

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob

# Append to the Bash history file, rather than overwriting it
shopt -s histappend

# Autocorrect typos in path names when using `cd`
shopt -s cdspell

# Remove need for `cd` when switching dir
shopt -s autocd

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
	shopt -s "$option" 2>/dev/null
done

# Activate mise for all the runtimes
activate_mise() {
	if which brew &>/dev/null 2>&1; then
		eval "$($(brew --prefix mise)/bin/mise activate bash)"
	fi
}

activate_zoxide() {
	eval "$(zoxide init bash)"
}

# Add tab completion for many Bash commands
load_compat_completions() {
	if which brew &>/dev/null && [ -r "$(brew --prefix)/etc/profile.d/bash_completion.sh" ]; then
		# Ensure existing Homebrew v1 completions continue to work
		export BASH_COMPLETION_COMPAT_DIR="$(brew --prefix)/etc/bash_completion.d"
		source "$(brew --prefix)/etc/profile.d/bash_completion.sh"
	elif [ -f /etc/bash_completion ]; then
		source /etc/bash_completion
	fi
}

load_alias_completions() {
	# Enable tab completion for `g` by marking it as an alias for `git`
	if type _git &>/dev/null; then
		complete -o default -o nospace -F _git g
	fi

	# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
	[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2- | tr ' ' '\n')" scp sftp ssh

	# Add tab completion for `defaults read|write NSGlobalDomain`
	# You could just use `-g` instead, but I like being explicit
	complete -W "NSGlobalDomain" defaults

	# Enable tab completion for `psql` aliases
	if type _psql &>/dev/null; then
		complete -F _psql psqp psqs psqd
	fi

	# Add `killall` tab completion for common apps
	complete -o "nospace" -W "Contacts Calendar Dock Finder Mail Safari iTunes SystemUIServer Terminal Twitter node" killall
}

load_brew_completions() {
	# Enable google-cloud-sdk and completion
	if [ -d "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk" ]; then
		source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc"
		source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc"
	fi

	# Turn on kubectl autocomplete.
	if which kubectl &>/dev/null; then
		if which brew &>/dev/null && [ -d "$(brew --prefix)/share/bash-completion/completions" ]; then
			kubectl completion bash >"$(brew --prefix)/share/bash-completion/completions/kubectl"
		else
			source <(kubectl completion bash)
		fi
		# Add aliases
		complete -o default -o nospace -F __start_kubectl k kc ks kp kl kd
	fi
}

debug_exec 1 activate_mise
debug_exec 0 activate_zoxide
debug_exec 1 load_compat_completions
debug_exec 0 load_alias_completions
debug_exec 1 load_brew_completions
