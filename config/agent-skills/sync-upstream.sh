#!/usr/bin/env bash
# sync-upstream.sh — Pull upstream subtrees and surface per-skill changes.
#
# Run from the dotfiles repo root:
#   bash config/agent-skills/sync-upstream.sh
#
# For each vendor, captures the pre-pull SHA, runs git subtree pull
# --squash, then prints a stat-level diff for every adopted skill so
# you can spot upstream changes that may need customisation review or
# that affect symlinked skills.

set -euo pipefail

# Run from dotfiles repo root regardless of where invoked
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../.." && pwd)"
cd "${repo_root}"

# Colour helpers (Solarized-ish; degrade gracefully if not a TTY)
if [[ -t 1 ]]; then
	c_blue=$'\033[34m'; c_cyan=$'\033[36m'; c_green=$'\033[32m'
	c_yellow=$'\033[33m'; c_dim=$'\033[2m'; c_reset=$'\033[0m'
else
	c_blue=""; c_cyan=""; c_green=""; c_yellow=""; c_dim=""; c_reset=""
fi

p1() { printf "%s==> %s%s\n" "${c_blue}" "$*" "${c_reset}"; }
p2() { printf "%s  -> %s%s\n" "${c_cyan}" "$*" "${c_reset}"; }
p3() { printf "%s     %s%s\n" "${c_dim}" "$*" "${c_reset}"; }
warn() { printf "%s  !! %s%s\n" "${c_yellow}" "$*" "${c_reset}" >&2; }

# Vendor table:
#   <prefix>|<upstream-url>|<branch>|<adopted-skills-relative-to-prefix>
# Adopted-skills paths are space-separated, relative to the vendor prefix.
vendors=(
	"config/agent-skills/anthropics|https://github.com/anthropics/skills|main|skills/skill-creator skills/pdf skills/pptx skills/docx skills/xlsx"
	"config/agent-skills/google|https://github.com/google/skills|main|skills/cloud/cloud-run-basics skills/cloud/cloud-sql-basics skills/cloud/gke-basics skills/cloud/google-cloud-waf-cost-optimization skills/cloud/google-cloud-waf-reliability skills/cloud/google-cloud-waf-security skills/cloud/bigquery-basics skills/cloud/google-cloud-networking-observability skills/cloud/google-cloud-recipe-auth"
)

# Sparse vendors: single-skill copies (not full subtrees) for upstream repos
# where we want just one skill out of a large collection. Refreshed by a
# shallow sparse checkout + rsync rather than `git subtree pull`.
#   <dest-prefix>|<upstream-url>|<branch>|<upstream-subpath>
sparse_vendors=(
	"config/agent-skills/softaworks/jira|https://github.com/softaworks/agent-toolkit|main|skills/jira"
)

# Refuse to run on a dirty tree — subtree pulls require clean state
if ! git diff --quiet || ! git diff --cached --quiet; then
	warn "Working tree is dirty. Commit or stash before running sync-upstream.sh."
	exit 1
fi

for entry in "${vendors[@]}"; do
	IFS="|" read -r prefix upstream branch skills_str <<< "${entry}"
	read -ra skills <<< "${skills_str}"
	vendor="$(basename "${prefix}")"

	p1 "Syncing ${vendor} (${upstream} ${branch})"
	pre_sha="$(git rev-parse HEAD)"

	# git subtree pull writes a merge commit even when up-to-date in some
	# git versions; suppress noise but capture failures.
	if ! git subtree pull --prefix="${prefix}" "${upstream}" "${branch}" --squash; then
		warn "Subtree pull failed for ${vendor}. Resolve conflicts then re-run."
		exit 1
	fi

	post_sha="$(git rev-parse HEAD)"

	if [[ "${pre_sha}" == "${post_sha}" ]]; then
		p2 "No upstream changes."
		continue
	fi

	# Show overall vendor stat
	p2 "Vendor diff vs pre-pull:"
	git --no-pager diff --stat "${pre_sha}" "${post_sha}" -- "${prefix}" | sed 's/^/     /'

	# Per-adopted-skill diffs
	any_skill_change=0
	for skill_rel in "${skills[@]}"; do
		path="${prefix}/${skill_rel}"
		if ! git diff --quiet "${pre_sha}" "${post_sha}" -- "${path}"; then
			any_skill_change=1
			skill_name="$(basename "${skill_rel}")"
			printf "\n%s  ## %s%s\n" "${c_green}" "${skill_name}" "${c_reset}"
			git --no-pager diff --stat "${pre_sha}" "${post_sha}" -- "${path}" | sed 's/^/     /'
			p3 "Files touched:"
			git --no-pager diff --name-only "${pre_sha}" "${post_sha}" -- "${path}" | sed 's/^/       /'
		fi
	done

	if [[ "${any_skill_change}" -eq 0 ]]; then
		p2 "Upstream changed, but no adopted skills affected."
	fi

	# Customisation reminder
	cust="${prefix}/CUSTOMISATION.md"
	if [[ -f "${cust}" ]]; then
		patches=$(grep -c '^- ' "${cust}" 2>/dev/null || true)
		if [[ "${patches:-0}" -gt 0 ]]; then
			warn "${vendor} has ${patches} listed local patch(es) in CUSTOMISATION.md — verify they survived the pull."
		fi
	fi
done

for entry in "${sparse_vendors[@]}"; do
	IFS="|" read -r dest upstream branch subpath <<< "${entry}"
	name="$(basename "${dest}")"

	p1 "Syncing ${name} (sparse: ${upstream} ${branch}:${subpath})"

	tmp="$(mktemp -d)"
	if ! git clone --depth 1 --filter=blob:none --sparse "${upstream}" "${tmp}/repo" >/dev/null 2>&1; then
		warn "Sparse clone failed for ${name}."
		rm -rf "${tmp}"
		exit 1
	fi
	git -C "${tmp}/repo" sparse-checkout set "${subpath}" >/dev/null 2>&1
	up_sha="$(git -C "${tmp}/repo" rev-parse HEAD)"

	if [[ ! -d "${tmp}/repo/${subpath}" ]]; then
		warn "Upstream path '${subpath}' not found in ${upstream}."
		rm -rf "${tmp}"
		exit 1
	fi

	mkdir -p "${dest}"
	rsync -a --delete --exclude '.git' "${tmp}/repo/${subpath}/" "${dest}/"
	rm -rf "${tmp}"

	if git diff --quiet -- "${dest}"; then
		p2 "No changes (upstream ${up_sha:0:12})."
	else
		p2 "Updated from upstream ${up_sha:0:12} — review the diff and bump the"
		p3 "'Last synced commit' in $(dirname "${dest}")/CUSTOMISATION.md:"
		git --no-pager diff --stat -- "${dest}" | sed 's/^/     /'
	fi
done

p1 "Done. Review the diff output above before pushing."
