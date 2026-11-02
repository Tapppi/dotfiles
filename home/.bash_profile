[ -n "$PS1" ] && source ~/.config/bash/.bash_profile;

# Inside a devenv environment (a devenv shell, or a herdr pane, Claude Code
# session or nested shell started from one), put the devenv profile back in
# front of PATH. Login shells lose it: /etc/profile's path_helper moves the
# inherited PATH behind /etc/paths, and the config sourced above prepends
# Homebrew, ~/.local/bin and mise. This runs after all of that, and outside the
# PS1 guard so `bash -l -c` gets it too. mise's prompt hook keeps entries
# prepended after its activation in front; devenv's own shell restores its
# PATH after ~/.bashrc, so there this changes nothing. A DEVENV_PROFILE whose
# store path is gone (collected after a rebuild) is skipped.
if [[ -n "${DEVENV_PROFILE:-}" && -d "${DEVENV_PROFILE}/bin" ]]; then
	devenv_bin="${DEVENV_PROFILE}/bin"
	path_rest=":${PATH}:"
	while [[ "${path_rest}" == *":${devenv_bin}:"* ]]; do
		path_rest="${path_rest/:${devenv_bin}:/:}"
	done
	path_rest="${path_rest#:}"
	path_rest="${path_rest%:}"
	export PATH="${devenv_bin}${path_rest:+:${path_rest}}"
	unset devenv_bin path_rest
fi
