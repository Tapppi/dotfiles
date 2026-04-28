#!/usr/bin/env bash
# subrepo-permissions.sh — Generate git -C permissions for nested git repos
# Usage: subrepo-permissions.sh [project-dir]
#
# Finds immediate subdirectories that are git repos and adds git -C <name>
# permission entries to the project's agent settings:
#
#   - .claude/settings.json (always; created if missing)
#   - opencode.json or .opencode/opencode.json (only if one already exists)
#
# Settings are repo-level (committed), not local overrides.
# Idempotent: replaces existing git -C entries on each run.

set -euo pipefail

project_dir="${1:-.}"
project_dir="$(cd "${project_dir}" && pwd)"
claude_settings="${project_dir}/.claude/settings.json"

# Detect OpenCode config (only update if one exists; don't create)
opencode_settings=""
if [[ -f "${project_dir}/opencode.json" ]]; then
	opencode_settings="${project_dir}/opencode.json"
elif [[ -f "${project_dir}/.opencode/opencode.json" ]]; then
	opencode_settings="${project_dir}/.opencode/opencode.json"
fi

# Find immediate subdirectories that are git repos
# Checks for both .git directory (standalone) and .git file (submodule gitlink)
subrepos=()
for dir in "${project_dir}"/*/; do
	[[ -e "${dir}.git" ]] || continue
	subrepos+=("$(basename "${dir}")")
done

if [[ ${#subrepos[@]} -eq 0 ]]; then
	echo "No nested git repos found in ${project_dir}"
	exit 0
fi

echo "Found subrepos: ${subrepos[*]}"

# Git subcommand templates — mirrors the user-level settings.json allow list
allow_templates=(
	'status'
	'status *'
	'log'
	'log *'
	'diff'
	'diff *'
	'grep *'
	'ls-tree *'
	'show *'
	'add *'
	'commit *'
	'merge *'
	'checkout *'
	'switch *'
	'restore *'
	'blame *'
	'rev-parse *'
	'stash *'
	'stash list'
	'stash list *'
	'shortlog'
	'shortlog *'
	'branch'
	'branch -a'
	'branch -a *'
	'branch -r'
	'branch -r *'
	'branch -v'
	'branch -v *'
	'branch -vv'
	'branch -vv *'
	'branch --list *'
	'branch --contains *'
	'branch --merged *'
	'branch --no-merged *'
	'branch -d *'
	'branch -m *'
	'remote'
	'remote -v'
	'remote show *'
	'fetch'
	'fetch *'
	'tag'
	'tag -l'
	'tag -l *'
	'tag --list'
	'tag --list *'
)

# Push requires explicit user approval
ask_templates=(
	'push'
	'push *'
)

# Build Claude permission entries (Bash(...) format) as newline-separated strings
claude_allow_lines=""
claude_ask_lines=""

# Build OpenCode permission entries as JSON object key-value pairs
opencode_pairs=""

for repo in "${subrepos[@]}"; do
	for tmpl in "${allow_templates[@]}"; do
		claude_allow_lines+="Bash(git -C ${repo} ${tmpl})"$'\n'
		opencode_pairs+="git -C ${repo} ${tmpl}\tallow"$'\n'
	done
	for tmpl in "${ask_templates[@]}"; do
		claude_ask_lines+="Bash(git -C ${repo} ${tmpl})"$'\n'
		opencode_pairs+="git -C ${repo} ${tmpl}\task"$'\n'
	done
done

# --- Claude Code merge ---

claude_allow_json=$(printf '%s' "${claude_allow_lines}" | jq -R -s 'split("\n") | map(select(. != ""))')
claude_ask_json=$(printf '%s' "${claude_ask_lines}" | jq -R -s 'split("\n") | map(select(. != ""))')

mkdir -p "${project_dir}/.claude"
if [[ ! -f "${claude_settings}" ]]; then
	echo '{}' > "${claude_settings}"
fi

jq --argjson new_allow "${claude_allow_json}" \
   --argjson new_ask "${claude_ask_json}" '
	.permissions.allow = (
		[(.permissions.allow // [])[] | select(test("^Bash\\(git -C ") | not)]
		+ $new_allow
	)
	| .permissions.ask = (
		[(.permissions.ask // [])[] | select(test("^Bash\\(git -C ") | not)]
		+ $new_ask
	)
' "${claude_settings}" > "${claude_settings}.tmp" \
	&& mv "${claude_settings}.tmp" "${claude_settings}"

echo "Updated ${claude_settings}"

# --- OpenCode merge (only if config exists) ---

if [[ -z "${opencode_settings}" ]]; then
	echo "No OpenCode config found; skipping OpenCode permissions"
	exit 0
fi

# Convert tab-separated pairs into a JSON object
opencode_obj=$(printf '%b' "${opencode_pairs}" | jq -R -s '
	split("\n")
	| map(select(. != "") | split("\t") | {(.[0]): .[1]})
	| add // {}
')

# Strip existing "git -C ..." keys, then merge new ones (later keys win in OpenCode)
jq --argjson new_bash "${opencode_obj}" '
	.permission = (.permission // {})
	| .permission.bash = (
		((.permission.bash // {}) | with_entries(select(.key | startswith("git -C ") | not)))
		+ $new_bash
	)
' "${opencode_settings}" > "${opencode_settings}.tmp" \
	&& mv "${opencode_settings}.tmp" "${opencode_settings}"

echo "Updated ${opencode_settings}"
