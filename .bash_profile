#!/usr/bin/env bash

# Add `~/bin` to the `$PATH`
export PATH="$HOME/bin:$PATH";

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,credentials,bash_prompt,exports,aliases,functions,extra}; do
	[ -r "$file" ] && [ -f "$file" ] && echo "bash_profile: execute $file..." && time source "$file";
done;
unset file;

# Set alias 'fuck' for 'thefuck'
if which thefuck &> /dev/null 2>&1; then
    eval "$(thefuck --alias fuck)"
fi

# Increase max open file descriptors
ulimit -S -n 10000

# Extended glob pattern matching
shopt -s extglob

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob;

# Append to the Bash history file, rather than overwriting it
shopt -s histappend;

# Autocorrect typos in path names when using `cd`
shopt -s cdspell;

# Remove need for `cd` when switching dir
shopt -s autocd;

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
	shopt -s "$option" 2> /dev/null;
done;

# Load node version manager
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# Enable pyenv shell integration
if which pyenv &> /dev/null 2>&1; then
    eval "$(pyenv init -)"
fi

# Add tab completion for many Bash commands
if which brew &> /dev/null && [ -r "$(brew --prefix)/etc/profile.d/bash_completion.sh" ]; then
    # Ensure existing Homebrew v1 completions continue to work
    export BASH_COMPLETION_COMPAT_DIR="$(brew --prefix)/etc/bash_completion.d"
    time source "$(brew --prefix)/etc/profile.d/bash_completion.sh"
elif [ -f /etc/bash_completion ]; then
	source /etc/bash_completion;
fi;

# Enable google-cloud-sdk and completion
if [ -d "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk" ]; then
    source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc"
    source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc"
fi;

# Enable tab completion for `g` by marking it as an alias for `git`
if type _git &> /dev/null; then
	complete -o default -o nospace -F _git g;
fi;

# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2- | tr ' ' '\n')" scp sftp ssh;

# Add tab completion for `defaults read|write NSGlobalDomain`
# You could just use `-g` instead, but I like being explicit
complete -W "NSGlobalDomain" defaults;

# Add `killall` tab completion for common apps
complete -o "nospace" -W "Contacts Calendar Dock Finder Mail Safari iTunes SystemUIServer Terminal Twitter" killall;

# Turn on kubectl autocomplete.
if which kubectl &> /dev/null; then
  if which brew &> /dev/null && [ -d "$(brew --prefix)/share/bash-completion/completions" ]; then
		kubectl completion bash > "$(brew --prefix)/share/bash-completion/completions/kubectl"
	else
	  source <(kubectl completion bash)
	fi
	# Add aliases
	complete -o default -o nospace -F __start_kubectl k kc ks kp kl kd
fi;

# Add tab completion for node version manager
if [ -s "$NVM_DIR/bash_completion" ]; then
	if which brew &> /dev/null && [ -d "$(brew --prefix)/share/bash-completion/completions" ]; then
		cp -f "$NVM_DIR/bash_completion" "$(brew --prefix)/share/bash-completion/completions/nvm"
	else
		\. "$NVM_DIR/bash_completion"
	fi;
fi;

# Enable tab completion for `psql` aliases
if type _psql &> /dev/null; then
	complete -F _psql psqp psqs psqd;
fi;

# Tab completion for rustup
if which rustup &> /dev/null && [ -d "$(brew --prefix)/etc/bash_completion.d"]; then
	rustup completions bash > $(brew --prefix)/etc/bash_completion.d/rustup.bash-completion
fi;

