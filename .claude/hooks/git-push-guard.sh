#!/usr/bin/env bash
# PreToolUse guard for `git push`.
#
# Approves only the sanctioned "agentic branch" push forms, and only in repos
# that opt in; every other push is handed back to the user as a prompt.
#
# This exists because permission rules cannot express the required shape: a
# branch-name wildcard such as `Bash(git push origin fix/*)` also swallows any
# trailing arguments (so `--force` slips in), and ask/deny rules cannot carry
# allowlist exceptions, so `--force` cannot be refused while `--force-with-lease`
# stays approved.
#
# Invariants:
#   - "allow" is emitted only for a single, unquoted `git push` whose flags are
#     all on the allowlist, whose remote is the configured one, and whose every
#     destination ref lives under a configured branch prefix.
#   - "allow" is also emitted for `cd <dir> && git push ...`, the one compound
#     shape this script normalizes rather than refuses. Note that the approval
#     then covers the whole Bash call, the `cd` included.
#   - Anything else recognisable as a `git push` that fails any of those checks
#     yields "ask" — including one wrapped in quoting, chained onto any other
#     command, or preceded by a global option the walk below cannot account for,
#     none of which this script will parse and therefore cannot vouch for.
#   - Only a command that runs no `git push` produces no output, leaving the
#     normal permission rules in charge. A push that is not the command's first
#     word — behind an environment assignment, an absolute path, a subshell or
#     another command — is refused rather than ignored; a push named inside
#     quotes is not a push and is left alone, and neither is `git stash push`,
#     quoted or not, when the call provably runs that one git stash push and
#     nothing else. Withholding a decision hands the command back to those
#     rules, and under a permissive default mode they may still approve it, so
#     silence is a fallback, not a guarantee, and is never what an actual push
#     receives.
#   - Never emits "deny": the user always keeps the option to approve by hand.
#
# Branch naming is a per-repo convention, not a global one, so the built-in
# prefix list is deliberately permissive — agent/, the conventional-commit types,
# plus debug/ and backup/ — and each repo narrows it through `branchPrefixes`.
# Keep this comment in step with the default list below; a repo that omits
# `branchPrefixes` is governed by that list and by nothing else.
#
# A --force-with-lease push is approved only while nobody has reviewed the
# branch: if an open PR on the destination carries any review or comment, it
# prompts instead. Cleaning up your own history is fine; rewriting what someone
# has already read is not. Only force-pushes pay for that forge lookup.
#
# Repo opt-in, first source that yields an object wins:
#   .claude/push-guard.json      -> the whole file is the config object
#   .claude/settings.local.json  -> .pushGuard
#   .claude/settings.json        -> .pushGuard   (commit this to opt in a team)
#
#   { "allowAgenticPush": true,
#     "remote": "origin",
#     "branchPrefixes": ["agent"],     // omit to accept the permissive default
#     "requireWorktree": false }

set -uo pipefail

decide() { # decision, reason
	jq -nc --arg d "$1" --arg r "$2" \
		'{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:$d,permissionDecisionReason:$r}}'
	exit 0
}
ask()   { decide ask   "push guard: $1"; }
allow() { decide allow "push guard: $1"; }

# Read stdin with a builtin rather than `cat`: a guard whose job is to degrade
# safely must not need a healthy PATH to reach its own fallback.
IFS= read -r -d '' payload || true

# jq is both how this script reads its input and how it writes its verdict, so
# without it the guard cannot function at all. Every git command reaches this
# hook, so stay quiet unless the payload plausibly carries a push — but never let
# a push through unexamined and unexplained just because a dependency is absent.
# This match is on raw text, so it over-prompts: `git commit -m push` trips it. A
# tighter pattern would have to assume `push` follows only option words, which
# would miss `git --git-dir <path> push` — the very shape most worth catching.
# Prompting for a commit beats staying silent for a redirected push.
if ! command -v jq >/dev/null 2>&1; then
	[[ $payload =~ \"command\"[[:space:]]*:[[:space:]]*\"[^\"]*git[[:space:]][^\"]*push ]] || exit 0
	printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"push guard: jq is not installed, so this push cannot be checked against the repo policy — install jq to restore pre-approved pushes"}}'
	exit 0
fi
cmd=$(jq -r '.tool_input.command // ""' <<<"$payload")
cwd=$(jq -r '.cwd // ""' <<<"$payload")
# The Bash call exactly as sent; `cmd` may be narrowed to its git part below.
call=$cmd

# Loose pre-filter. Anything not plausibly a `git push` is none of this script's
# business and must pass through without a decision — but "not plausibly a push"
# is decided on the command's first word and on text outside quotes, so a
# heredoc, grep pattern or jq argument that merely mentions a push is never
# mistaken for one, while a push hidden behind an environment assignment, an
# absolute path or a preceding command still gets a verdict.
# `cd <dir> && git push …` is a routine shape here, so normalize it instead of
# leaving it unparseable: the push is evaluated as the push it is, resolved
# against the directory the cd moves to.
if [[ $cmd =~ ^[[:space:]]*cd[[:space:]]+([A-Za-z0-9_./-]+)[[:space:]]*\&\&[[:space:]]*(git[[:space:]].*)$ ]]; then
	cd_target=${BASH_REMATCH[1]}
	cmd=${BASH_REMATCH[2]}
	[[ $cd_target == /* ]] && cwd=$cd_target || cwd=$cwd/$cd_target
fi

# `probe` drops everything from the first quote or redirection onward, and
# `first` additionally drops everything past a command separator. Asking "is
# this a push?" of `first` rather than of the whole string keeps
# `git commit -m "do not push to main"` and `git log | grep push` out of the
# guard's way: their push token lives past the cut, so they never reach it.
probe=${cmd%%[\"\'\<\>]*}
first=${probe%%[|;\&]*}

# Held in variables: bash mis-parses a bracket expression containing `(` when
# the regex is written inline.
re_push='[[:blank:]]push([[:blank:]]|$)'
re_git_word='(^|[[:blank:]]|[/=(])git[[:blank:]]'

if [[ $cmd =~ ^[[:blank:]]*git[[:blank:]] ]]; then
	[[ $first =~ $re_push ]] || exit 0
else
	# A push that is not the first thing the command runs is still a push, and
	# ignoring it hands it to the ordinary rules, which may approve it. An
	# environment assignment, an absolute path, a subshell or a preceding command
	# all land here. Matching on `probe` keeps a quoted mention of a push — a
	# heredoc, a grep pattern, an echo — outside this entirely.
	if [[ $probe =~ $re_git_word ]] && [[ $probe =~ $re_push ]]; then
		ask "this runs a git push that is not the command's first word, so the guard cannot vouch for it"
	fi
	exit 0
fi

# split_single_command <string>: succeed, with the words in the global array
# `words`, only when the string is one simple command made of nothing but plain
# words drawn from the alphabet of the gate below, '…' strings, and "…" strings
# holding nothing that expands inside double quotes. That grammar has no
# separator, newline, redirection, substitution, expansion, glob or escape
# anywhere in it, so the shell runs exactly one command and splits it into
# exactly these words. Every other string fails, however harmless.
# The blanks are the shell's own two, spelled out, because some locales class
# Unicode spaces as [:blank:] and the shell never splits on those. The C locale
# keeps [:alnum:] and [:cntrl:] to ASCII and makes the scan byte by byte, so no
# multibyte character passes for a word character. Past 4096 bytes, far beyond
# any stash message, the string fails too: this scan is quadratic in bash, and a
# hook that runs out its time budget hands the call back undecided.
split_single_command() {
	local LC_ALL=C s=$1 w="" in_word=0 q
	words=()
	(( ${#s} <= 4096 )) || return 1
	while [[ -n $s ]]; do
		case ${s:0:1} in
			' '|$'\t')
				(( in_word )) && words+=("$w")
				w="" in_word=0 s=${s:1} ;;
			[[:alnum:]_./:=@+-])
				w+=${s:0:1} in_word=1 s=${s:1} ;;
			"'")
				s=${s:1}
				[[ $s == *"'"* ]] || return 1
				q=${s%%"'"*}
				case $q in *[[:cntrl:]]*) return 1 ;; esac
				w+=$q in_word=1 s=${s#*"'"} ;;
			'"')
				s=${s:1}
				[[ $s == *'"'* ]] || return 1
				q=${s%%'"'*}
				case $q in *[[:cntrl:]]*|*'$'*|*'`'*|*"\\"*|*'!'*) return 1 ;; esac
				w+=$q in_word=1 s=${s#*'"'} ;;
			*) return 1 ;;
		esac
	done
	(( in_word )) && words+=("$w")
	return 0
}

# runs_only_git_stash <string>: succeed only when the string provably runs one
# git command, `git stash push`, and nothing makes git start another program
# for it. Before the subcommand only -C and its value and the value-less
# options that neither page nor redirect are stepped over; -p and --paginate
# start a pager, and anything this guard does not know may swallow the word
# after it. After `stash push` only its non-interactive options are accepted:
# --help (and `stash --help`) starts man and a pager, and --patch is an
# interactive session. Short options are accepted one to a word, and the value
# of -m is stepped over whatever it looks like.
runs_only_git_stash() {
	local i=1
	split_single_command "$1" || return 1
	[[ ${words[0]:-} == git ]] || return 1
	while [[ ${words[$i]:-} == -* ]]; do
		case ${words[$i]} in
			-C) i=$((i+2)) ;;
			--no-pager|--literal-pathspecs|--no-replace-objects|--no-optional-locks)
				i=$((i+1)) ;;
			*) return 1 ;;
		esac
	done
	[[ ${words[$i]:-} == stash && ${words[$((i+1))]:-} == push ]] || return 1
	for ((i += 2; i < ${#words[@]}; i++)); do
		case ${words[$i]} in
			--) return 0 ;;
			-m|--message) i=$((i+1)) ;;
			-m?*|--message=*) ;;
			-u|--include-untracked|-a|--all|-k|--keep-index|--no-keep-index) ;;
			-S|--staged|-q|--quiet) ;;
			-*) return 1 ;;
		esac
	done
	return 0
}

# Parse, don't validate: go on only with a flat list of plain words. Shell
# operators, quoting, expansion and globbing all land here. By this point the
# command is known to be a git invocation carrying a `push` token, so it fails
# closed with a prompt rather than passing through — the fall-through would
# otherwise reach a permissive default mode. That is also what keeps a compound
# like `git push … && rm -rf /` off the approval path, since a single "allow"
# would have covered the whole Bash call.
# [:blank:], never [:space:]: a newline is a command separator, and `read -ra`
# below consumes only the first line, so admitting one here would approve a
# second command sight unseen.
# The one way past this gate without a prompt is silence for a quoted
# `git stash push -m "…"`: its push token is only a stash subcommand, and it is
# let through only when the whole call as sent — so nothing chained on, the cd
# shape included — provably runs that single git stash push and nothing else.
# Stash alone, because other subcommands that carry a push token can run one:
# `git submodule foreach git push …` is a push.
if ! [[ $cmd =~ ^[A-Za-z0-9_./:=@+[:blank:]-]+$ ]]; then
	runs_only_git_stash "$call" && exit 0
	ask "this push is wrapped in shell syntax the guard cannot parse"
fi

read -ra tok <<<"$cmd"
[[ ${tok[0]:-} == git ]] || exit 0

# Everything between `git` and its subcommand is a global option, and several of
# them redirect which repository, config or worktree the push acts on. Walk them
# explicitly: an option that moves the target is only ever allowed to reach a
# prompt, and one this guard does not recognise stops it dead rather than being
# skipped over.
i=1
repo_dir=$cwd
indirect=""
# Keep the FIRST redirection seen. Overwriting it lets a later, resolvable
# option stand in for an earlier unresolvable one — `-c core.hooksPath=... -C .`
# would otherwise read as a plain `-C` push and be approved, with git then
# running a hook of the caller's choosing.
note_indirect() { [[ -n $indirect ]] || indirect=$1; }
while [[ ${tok[$i]:-} == -* ]]; do
	case ${tok[$i]} in
		# -C is the one redirection this guard can follow, so it records no
		# indirection — but it must be resolved exactly as git resolves it:
		# relative to what came before, which starts at the payload's cwd.
		-C)                 t_dir=${tok[$((i+1))]:-}
		                    [[ $t_dir == /* ]] && repo_dir=$t_dir || repo_dir=$repo_dir/$t_dir
		                    i=$((i+2)) ;;
		-c)                 note_indirect "${tok[$i]}";  i=$((i+2)) ;;
		--git-dir=*|--work-tree=*|--namespace=*|--exec-path=*|--bare)
		                    note_indirect "${tok[$i]%%=*}"; i=$((i+1)) ;;
		# The same options spelled with a space take their value as a separate word.
		# Stepping over only the option would leave its value where the subcommand
		# should be, and the check below would then read a path as "not a push".
		--git-dir|--work-tree|--namespace|--exec-path|--super-prefix|--config-env|--attr-source)
		                    note_indirect "${tok[$i]}";  i=$((i+2)) ;;
		--no-pager|--paginate|-p|--literal-pathspecs|--no-replace-objects|--no-optional-locks)
		                    i=$((i+1)) ;;
		*)                  note_indirect "${tok[$i]}";  i=$((i+1)) ;;
	esac
done

# Not landing on `push` means one of two things. If no global option was consumed
# this is an ordinary git command that merely carries the word somewhere, and it
# is none of this script's business. If options *were* consumed, the walk lost
# track of the subcommand — an unknown option that swallows a value looks exactly
# like this — and a push whose position cannot be established is a push that
# cannot be vouched for, so it goes to the user rather than to silence.
if [[ ${tok[$i]:-} != push ]]; then
	[[ -n $indirect ]] ||
		exit 0
	ask "the global options before 'push' are not ones the guard can account for"
fi
((i++))

# A push reached through an indirection is not the push it appears to be: the
# repository, the config or the worktree it lands in comes from somewhere this
# guard cannot verify. Those always go to the user.
[[ -z $indirect ]] ||
	ask "'$indirect' redirects where this push lands, so it needs approval"

positional=()
rewrites_history=0
saw_if_includes=0
for ((; i < ${#tok[@]}; i++)); do
	t=${tok[$i]}
	case $t in
		--force-with-lease) rewrites_history=1 ;;
		--force-with-lease=*)
			# `--force-with-lease=<ref>:<expect>` supplies the expected value itself,
			# which reduces the lease to a plain force and makes --force-if-includes a
			# no-op. Only the ref-only form keeps the protection.
			[[ ${t#--force-with-lease=} == *:* ]] &&
				ask "'$t' names its own expected value, which is a plain force in disguise"
			rewrites_history=1 ;;
		--force-if-includes) saw_if_includes=1 ;;
		-u|--set-upstream) ;;
		--dry-run|--atomic|--no-tags|--porcelain|--progress|--no-progress|-q|--quiet|-v|--verbose) ;;
		-*) ask "flag '$t' is not on the allowlist" ;;
		*)  positional+=("$t") ;;
	esac
done

# A bare lease compares against the remote-tracking ref, which any background
# fetch refreshes — after which the lease passes and silently discards whatever
# the other side had pushed. --force-if-includes restores the protection.
(( rewrites_history && ! saw_if_includes )) &&
	ask "--force-with-lease without --force-if-includes: a background fetch can degrade the lease into a plain force"

(( ${#positional[@]} >= 2 )) || ask "push must name a remote and at least one refspec"
remote=${positional[0]}
refspecs=("${positional[@]:1}")

root=$(git -C "$repo_dir" rev-parse --show-toplevel 2>/dev/null) ||
	ask "'$repo_dir' is not inside a git repository"

config=""
for candidate in "$root/.claude/push-guard.json:." \
                 "$root/.claude/settings.local.json:.pushGuard" \
                 "$root/.claude/settings.json:.pushGuard"; do
	file=${candidate%:*}
	filter=${candidate##*:}
	[[ -f $file ]] || continue
	config=$(jq -c "$filter // empty" "$file" 2>/dev/null) || config=""
	[[ -n $config && $config != null ]] && break
	config=""
done
[[ -n $config ]] || ask "no pushGuard config in $(basename "$root")/.claude/"

[[ $(jq -r '.allowAgenticPush // false' <<<"$config") == true ]] ||
	ask "$(basename "$root") has not enabled agentic pushes"

want_remote=$(jq -r '.remote // "origin"' <<<"$config")
[[ $remote == "$want_remote" ]] || ask "remote '$remote' is not the approved remote '$want_remote'"

prefixes=()
while IFS= read -r p; do
	[[ -n $p ]] && prefixes+=("$p")
done < <(jq -r '(.branchPrefixes // ["agent","build","chore","ci","debug","docs","feat","fix","perf","refactor","revert","style","test","backup"])[]?' <<<"$config")
(( ${#prefixes[@]} )) || ask "config lists no branch prefixes"

if [[ $(jq -r '.requireWorktree // false' <<<"$config") == true ]]; then
	# In the main checkout both resolve to the same directory; in a linked
	# worktree --git-dir points at .git/worktrees/<name> instead.
	[[ "$(git -C "$repo_dir" rev-parse --git-dir)" != \
	   "$(git -C "$repo_dir" rev-parse --git-common-dir)" ]] ||
		ask "not running from a linked worktree"
fi

dsts=()
for spec in "${refspecs[@]}"; do
	# A leading + forces the update without the lease check --force-with-lease adds.
	[[ $spec == +* ]] && ask "'$spec' is a forced refspec"
	src=$spec
	dst=$spec
	if [[ $spec == *:* ]]; then
		src=${spec%%:*}
		dst=${spec#*:}
	fi
	[[ -n $src ]] || ask "'$spec' deletes a remote branch"
	[[ -n $dst ]] || ask "'$spec' has no destination ref"
	if [[ $dst == HEAD ]]; then
		dst=$(git -C "$repo_dir" symbolic-ref --quiet --short HEAD) ||
			ask "HEAD is detached, so its destination branch is unknown"
	fi
	dst=${dst#refs/heads/}
	matched=""
	for p in "${prefixes[@]}"; do
		[[ $dst == "$p"/?* ]] && { matched=1; break; }
	done
	[[ -n $matched ]] || ask "destination branch '$dst' is not an agentic branch"

	dsts+=("$dst")
done

# Rewriting your own un-reviewed branch is cleanup; rewriting one somebody has
# read destroys what they reviewed. Only a force-push pays for this lookup, and
# only once per distinct destination. Unknown answers fail closed.
if (( rewrites_history )); then
	checked=""
	for dst in "${dsts[@]}"; do
		[[ $checked == *"|$dst|"* ]] && continue
		checked+="|$dst|"
		prs=$(cd "$repo_dir" && timeout 5 gh pr list --head "$dst" --state open --json number 2>/dev/null) ||
			ask "cannot reach the forge to check whether '$dst' has been reviewed"
		total=0
		while IFS= read -r num; do
			[[ -n $num ]] || continue
			seen=$(cd "$repo_dir" && timeout 5 gh pr view "$num" --json reviews,comments \
			       --jq '[(.reviews//[]|length),(.comments//[]|length)]|add' 2>/dev/null) ||
				ask "cannot read review state of PR #$num for '$dst'"
			[[ $seen =~ ^[0-9]+$ ]] || ask "unreadable review state for PR #$num"
			total=$(( total + seen ))
		done < <(jq -r 'if type=="array" then .[].number else empty end' <<<"$prs" 2>/dev/null)
		(( total == 0 )) ||
			ask "'$dst' carries $total review(s)/comment(s) across its open PR(s) — rewriting reviewed history needs approval"
	done
fi

allow "${#refspecs[@]} ref(s) under an agentic prefix on '$remote'"
