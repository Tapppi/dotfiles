# Add `~/bin` to the `$PATH`
export PATH="$HOME/bin:$PATH";

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,credentials,bash_prompt,exports,aliases,functions,extra}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

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

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
	shopt -s "$option" 2> /dev/null;
done;

# Load node version manager
export NVM_DIR="${HOME}/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Add tab completion for many Bash commands
if which brew &> /dev/null && [ -r "$(brew --prefix)/etc/profile.d/bash_completion.sh" ]; then
	# Ensure existing Homebrew v1 completions continue to work
	export BASH_COMPLETION_COMPAT_DIR="$(brew --prefix)/etc/bash_completion.d";
	source "$(brew --prefix)/etc/profile.d/bash_completion.sh";
#if which brew &> /dev/null && [ -f "$(brew --prefix)/share/bash-completion/bash_completion" ]; then
#	if [ -d "$(brew --prefix)/etc/bash_completion.d" ]; then
#		export BASH_COMPLETION_COMPAT_DIR="$(brew --prefix)/etc/bash_completion.d"
#	fi
#	source "$(brew --prefix)/share/bash-completion/bash_completion";
elif [ -f /etc/bash_completion ]; then
	source /etc/bash_completion;
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
	complete -o default -o nospace -F __start_kubectl kc ks kp kl kd
fi;

# Add tab completion for node version manager
if [ -s "$NVM_DIR/bash_completion" ]; then
	if which brew &> /dev/null && [ -d "$(brew --prefix)/share/bash-completion/completions" ]; then
		cp "$NVM_DIR/bash_completion" "$(brew --prefix)/share/bash-completion/completions/nvm"
	else
		\. "$NVM_DIR/bash_completion"
	fi;
fi;

# Enable tab completion for `psql` aliases
if type _psql &> /dev/null; then
	complete -F _psql psqp psqs psqd;
fi;
