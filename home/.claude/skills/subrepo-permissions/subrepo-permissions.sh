#!/usr/bin/env bash
# subrepo-permissions.sh — Generate git -C permissions for nested git repos
# Usage: subrepo-permissions.sh [project-dir]
#
# Finds immediate subdirectories that are git repos and adds git -C <name>
# permission entries to .claude/settings.local.json in the project directory.
# Idempotent: replaces existing git -C entries on each run.

set -euo pipefail

project_dir="${1:-.}"
project_dir="$(cd "${project_dir}" && pwd)"
settings_file="${project_dir}/.claude/settings.local.json"

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

# Build permission entries as newline-separated strings
allow_lines=""
ask_lines=""

for repo in "${subrepos[@]}"; do
	for tmpl in "${allow_templates[@]}"; do
		allow_lines+="Bash(git -C ${repo} ${tmpl})"$'\n'
	done
	for tmpl in "${ask_templates[@]}"; do
		ask_lines+="Bash(git -C ${repo} ${tmpl})"$'\n'
	done
done

# Convert to JSON arrays
allow_json=$(printf '%s' "${allow_lines}" | jq -R -s 'split("\n") | map(select(. != ""))')
ask_json=$(printf '%s' "${ask_lines}" | jq -R -s 'split("\n") | map(select(. != ""))')

# Ensure .claude directory and settings file exist
mkdir -p "${project_dir}/.claude"
if [[ ! -f "${settings_file}" ]]; then
	echo '{}' > "${settings_file}"
fi

# Merge: strip existing git -C entries (idempotent), then append new ones
jq --argjson new_allow "${allow_json}" \
   --argjson new_ask "${ask_json}" '
	.permissions.allow = (
		[(.permissions.allow // [])[] | select(test("^Bash\\(git -C ") | not)]
		+ $new_allow
	)
	| .permissions.ask = (
		[(.permissions.ask // [])[] | select(test("^Bash\\(git -C ") | not)]
		+ $new_ask
	)
' "${settings_file}" > "${settings_file}.tmp" \
	&& mv "${settings_file}.tmp" "${settings_file}"

echo "Updated ${settings_file}"
