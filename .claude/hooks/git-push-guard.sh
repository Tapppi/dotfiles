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
#   - Anything recognisable as a `git push` that fails any of those checks yields
#     "ask" — including one wrapped in quoting or chained onto another command,
#     which this script will not parse and therefore cannot vouch for.
#   - Only a command that is not a `git push` at all produces no output, leaving
#     the normal permission rules in charge. Withholding a decision hands the
#     command back to those rules — under a permissive default mode they may
#     still approve it, so silence is a fallback, not a guarantee, and is never
#     what a push receives.
#   - Never emits "deny": the user always keeps the option to approve by hand.
#
# Branch naming is a per-repo convention, not a global one, so the built-in
# prefix list is deliberately permissive (agent/ plus the conventional-commit
# types) and each repo narrows it through `branchPrefixes`.
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
if ! command -v jq >/dev/null 2>&1; then
  [[ $payload =~ \"command\"[[:space:]]*:[[:space:]]*\"git[[:space:]][^\"]*push ]] || exit 0
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"push guard: jq is not installed, so this push cannot be checked against the repo policy — install jq to restore pre-approved pushes"}}'
  exit 0
fi
cmd=$(jq -r '.tool_input.command // ""' <<<"$payload")
cwd=$(jq -r '.cwd // ""' <<<"$payload")

# Loose pre-filter. Anything not plausibly a `git push` is none of this script's
# business and must pass through without a decision. The command has to *start*
# with git, so a heredoc, grep pattern or jq argument that merely mentions a push
# is never mistaken for one.
# `cd <dir> && git push …` is a routine shape here, so normalize it instead of
# leaving it unparseable: the push is evaluated as the push it is, resolved
# against the directory the cd moves to.
if [[ $cmd =~ ^[[:space:]]*cd[[:space:]]+([A-Za-z0-9_./-]+)[[:space:]]*\&\&[[:space:]]*(git[[:space:]].*)$ ]]; then
  cd_target=${BASH_REMATCH[1]}
  cmd=${BASH_REMATCH[2]}
  [[ $cd_target == /* ]] && cwd=$cd_target || cwd=$cwd/$cd_target
fi

[[ $cmd =~ ^[[:space:]]*git[[:space:]] ]]      || exit 0
[[ $cmd =~ [[:space:]]push([[:space:]]|$) ]]   || exit 0

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
[[ $cmd =~ ^[A-Za-z0-9_./:=@+[:blank:]-]+$ ]] ||
  ask "this push is wrapped in shell syntax the guard cannot parse"

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
while [[ ${tok[$i]:-} == -* ]]; do
  case ${tok[$i]} in
    -C)                 repo_dir=${tok[$((i+1))]:-}; indirect="-C"; i=$((i+2)) ;;
    -c)                 indirect=${tok[$i]};         i=$((i+2)) ;;
    --git-dir=*|--work-tree=*|--namespace=*|--exec-path=*|--bare)
                        indirect=${tok[$i]%%=*};     i=$((i+1)) ;;
    --no-pager|--paginate|-p|--literal-pathspecs|--no-replace-objects|--no-optional-locks)
                        i=$((i+1)) ;;
    *)                  indirect=${tok[$i]};         i=$((i+1)) ;;
  esac
done
[[ ${tok[$i]:-} == push ]] || exit 0
((i++))

# A push reached through an indirection is not the push it appears to be: the
# repository, the config or the worktree it lands in comes from somewhere this
# guard cannot verify. Those always go to the user.
[[ -z $indirect || $indirect == "-C" ]] ||
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
