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
#
# A vendor may also list paths that must never be vendored: upstream
# content this public repo has no right to redistribute — either a
# licence that forbids it, or no licence at all, since absence of a
# grant is not permission. Such a vendor is pulled through
# subtree_pull_excluding
# below, which builds the squash commit from a filtered tree so the
# excluded paths never enter the worktree *or* reachable history. Each
# exclusion is explained in the vendor's CUSTOMISATION.md.

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
#   <prefix>|<upstream-url>|<branch>|<adopted-skills>|<excluded-paths>
# Adopted-skills and excluded paths are space-separated, relative to the
# vendor prefix. Excluded paths are dropped from the upstream tree before
# it is squashed and merged, and every one of them must still exist
# upstream: a path that matches nothing refuses the pull rather than
# being skipped, since it most likely means a rename, and the content
# would otherwise ride in under its new name. Never `git subtree pull`
# such a vendor by hand: a stock pull squashes the whole upstream tree,
# which puts the excluded content back into history even if the merge
# then drops it from the worktree. Do not remove a path from the list
# without reading the vendor's CUSTOMISATION.md — it says why it is there.
vendors=(
	"config/agent-skills/anthropics|https://github.com/anthropics/skills|main|skills/skill-creator|skills/docx skills/pdf skills/pptx skills/xlsx skills/doc-coauthoring .claude-plugin"
	"config/agent-skills/google|https://github.com/google/skills|main|skills/cloud/cloud-run-basics skills/cloud/cloud-sql-basics skills/cloud/gke-basics skills/cloud/google-cloud-waf-cost-optimization skills/cloud/google-cloud-waf-reliability skills/cloud/google-cloud-waf-security skills/cloud/bigquery-basics skills/cloud/google-cloud-networking-observability skills/cloud/google-cloud-recipe-auth|"
)

# Sparse vendors: single-skill copies (not full subtrees) for upstream repos
# where we want just one skill out of a large collection. Refreshed by a
# shallow sparse checkout + rsync rather than `git subtree pull`.
#   <dest-prefix>|<upstream-url>|<branch>|<upstream-subpath>
sparse_vendors=(
	"config/agent-skills/softaworks/jira|https://github.com/softaworks/agent-toolkit|main|skills/jira"
)

# Mirror of git-subtree's find_latest_squash. Prints "<squash-commit>
# <upstream-commit>" for the most recent squash of <prefix> reachable from
# HEAD, located via the git-subtree-dir / git-subtree-split trailers that
# git subtree writes into every squash commit. A `git subtree add` merge
# commit carries a git-subtree-mainline trailer as well; its squash is its
# second parent.
latest_squash() {
	local prefix=$1 key val sq="" main="" split=""
	while read -r key val; do
		case "${key}" in
			START) sq="${val}"; main=""; split="" ;;
			git-subtree-mainline:) main="${val}" ;;
			git-subtree-split:) split="${val}" ;;
			END)
				if [[ -n "${split}" ]]; then
					if [[ -n "${main}" ]]; then
						sq="$(git rev-parse "${sq}^2")"
					fi
					printf '%s %s\n' "${sq}" "${split}"
					return 0
				fi
				;;
		esac
	done < <(git log --grep="^git-subtree-dir: ${prefix}/*\$" --no-show-signature --pretty=format:'START %H%n%B%nEND%n' HEAD)
	return 1
}

# `git subtree pull --squash`, minus the excluded paths.
#
# A stock pull writes a squash commit whose tree is the *whole* upstream
# tree, so content removed for licence reasons would re-enter reachable
# history on every pull and be published again by the next push, even
# if the merge then dropped it from the worktree. This does what git
# subtree does, with one extra step: it reads the upstream commit into a
# scratch index, drops the excluded paths, and squashes and merges *that*
# tree. Same parent chain and trailers as git subtree, so the next pull
# still finds the chain and merges three-way against the right base.
#
# Every step checks its own status, and returns before anything is merged
# when it fails. errexit is no help here: the call site runs this under
# `if !`, which switches errexit off for the whole function. Unchecked,
# the steps compose into a silent disaster — a failed fetch leaves a
# stale or empty FETCH_HEAD, a failed read-tree leaves an empty scratch
# index, `git write-tree` then happily writes the empty tree, and the
# "squash" built from it merges cleanly as the deletion of the entire
# vendor, reported as an upstream change.
subtree_pull_excluding() {
	local prefix=$1 upstream=$2 branch=$3
	shift 3
	local excluded=("$@")
	local old_squash old_split new_split scratch tree squash path

	if ! git fetch --quiet "${upstream}" "${branch}"; then
		warn "git fetch ${upstream} ${branch} failed for ${prefix}; nothing merged."
		return 1
	fi
	# Read FETCH_HEAD only after a fetch that succeeded: a failed one leaves
	# whatever the previous fetch wrote, which may be another repo's tip.
	# ^{commit} rejects an empty or non-commit answer as well.
	if ! new_split="$(git rev-parse --verify --quiet 'FETCH_HEAD^{commit}')" || [[ -z "${new_split}" ]]; then
		warn "FETCH_HEAD does not name a commit after fetching ${upstream} ${branch}; nothing merged."
		return 1
	fi

	if ! read -r old_squash old_split < <(latest_squash "${prefix}"); then
		warn "No earlier squash commit found for ${prefix}; cannot pull."
		return 1
	fi
	if [[ "${old_split}" == "${new_split}" ]]; then
		return 0
	fi

	# The exclusion list is a licence guard, so an entry that matches nothing
	# is an error, not a no-op. It means upstream moved or renamed the path
	# (or the vendor table has a typo), and skipping it would carry the
	# content into the squash under its new name, where the post-merge check
	# on the old path would never see it. Git cannot tell a deliberate
	# upstream removal from a rename, so a human has to look either way; the
	# upstream commits touching the path are listed to start that search.
	for path in "${excluded[@]}"; do
		if ! git rev-parse --verify --quiet "${new_split}:${path}" >/dev/null; then
			warn "Excluded path '${path}' is not in upstream ${new_split:0:7} (${upstream} ${branch}); nothing merged."
			warn "Find where it went, update the vendor table and ${prefix}/CUSTOMISATION.md, then re-run. Upstream commits touching it:"
			# old_split is a squash trailer, not a ref: its object may have been
			# pruned and upstream may have rewritten history past it, so the
			# range can be invalid. Fall back to the path's recent history.
			git --no-pager log --no-show-signature --pretty=tformat:'     %h %s' "${old_split}..${new_split}" -- "${path}" >&2 2>/dev/null \
				|| git --no-pager log --no-show-signature -5 --pretty=tformat:'     %h %s' "${new_split}" -- "${path}" >&2 2>/dev/null \
				|| true
			return 1
		fi
	done

	# Filtered tree, built in a scratch index so the repo's own index is
	# never touched.
	if ! scratch="$(mktemp -d)"; then
		warn "mktemp failed; nothing merged."
		return 1
	fi
	if ! GIT_INDEX_FILE="${scratch}/index" git read-tree "${new_split}"; then
		warn "git read-tree ${new_split:0:7} failed; nothing merged."
		rm -rf "${scratch}"
		return 1
	fi
	# No --ignore-unmatch: every path was verified present above, so a miss
	# here is a real error and must stay one. -f skips git rm's up-to-date
	# check, which would otherwise compare this scratch index against the
	# dotfiles worktree and HEAD and refuse an excluded path that happens to
	# share a name with a file at the dotfiles root.
	if ! GIT_INDEX_FILE="${scratch}/index" git rm -r -q -f --cached -- "${excluded[@]}"; then
		warn "git rm --cached of the excluded paths failed; nothing merged."
		rm -rf "${scratch}"
		return 1
	fi
	if ! tree="$(GIT_INDEX_FILE="${scratch}/index" git write-tree)" || [[ -z "${tree}" ]]; then
		warn "git write-tree failed; nothing merged."
		rm -rf "${scratch}"
		return 1
	fi
	rm -rf "${scratch}"

	# write-tree returns the empty tree (4b825dc… under SHA-1) for an empty
	# index, and the empty tree merges cleanly — as the deletion of
	# everything under the prefix. Nothing legitimate produces it here.
	# Tested structurally rather than against a hash constant, so it holds
	# under either object format; an unreadable tree fails the same way.
	if [[ -z "$(git ls-tree "${tree}" 2>/dev/null)" ]]; then
		warn "Filtered tree for ${prefix} is empty — the exclusions cover everything upstream ${new_split:0:7} has; nothing merged."
		return 1
	fi

	if ! squash="$(
		{
			printf "Squashed '%s/' changes from %s..%s\n\n" "${prefix}" "${old_split:0:7}" "${new_split:0:7}"
			git log --no-show-signature --pretty=tformat:'%h %s' "${old_split}..${new_split}" 2>/dev/null || true
			printf '\nExcluded from the squashed tree: %s\n' "${excluded[*]}"
			printf '\ngit-subtree-dir: %s\ngit-subtree-split: %s\n' "${prefix}" "${new_split}"
		} | git commit-tree "${tree}" -p "${old_squash}"
	)" || [[ -z "${squash}" ]]; then
		warn "git commit-tree failed for ${prefix}; nothing merged."
		return 1
	fi
	if ! git merge --no-ff -Xsubtree="${prefix}" -m "Merge commit '${squash}'" "${squash}"; then
		warn "git merge of ${squash:0:7} into ${prefix} failed."
		return 1
	fi
}

# Refuse to run on a dirty tree — subtree pulls require clean state
if ! git diff --quiet || ! git diff --cached --quiet; then
	warn "Working tree is dirty. Commit or stash before running sync-upstream.sh."
	exit 1
fi

# Set when a vendor is refused before anything is merged; the run carries on
# with the other vendors and exits non-zero at the end.
sync_failed=0

for entry in "${vendors[@]}"; do
	IFS="|" read -r prefix upstream branch skills_str excluded_str <<< "${entry}"
	read -ra skills <<< "${skills_str}"
	read -ra excluded <<< "${excluded_str}"
	vendor="$(basename "${prefix}")"

	p1 "Syncing ${vendor} (${upstream} ${branch})"
	pre_sha="$(git rev-parse HEAD)"

	if [[ "${#excluded[@]}" -gt 0 ]]; then
		p2 "Excluding ${excluded[*]} (see ${prefix}/CUSTOMISATION.md)"
		if ! subtree_pull_excluding "${prefix}" "${upstream}" "${branch}" "${excluded[@]}"; then
			if git rev-parse --quiet --verify MERGE_HEAD >/dev/null; then
				warn "Filtered subtree pull left a conflicted merge for ${vendor}. Resolve conflicts, commit the merge, then re-run."
				exit 1
			fi
			# Refused before anything was merged, so the tree is clean: say
			# so, sync the remaining vendors, and fail the run at the end.
			warn "Filtered subtree pull refused for ${vendor}; nothing merged. Fix the cause above, then re-run."
			sync_failed=1
			continue
		fi
	else
		# git subtree pull writes a merge commit even when up-to-date in some
		# git versions; suppress noise but capture failures.
		if ! git subtree pull --prefix="${prefix}" "${upstream}" "${branch}" --squash; then
			warn "Subtree pull failed for ${vendor}. Resolve conflicts then re-run."
			exit 1
		fi
	fi

	# The merge cannot add an excluded path (neither side has it), so one on
	# disk here was re-added locally. Say so before it gets pushed.
	for path in "${excluded[@]}"; do
		if [[ -e "${prefix}/${path}" ]]; then
			warn "${prefix}/${path} is excluded but present — remove it before pushing (see ${prefix}/CUSTOMISATION.md)."
		fi
	done

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

if [[ "${sync_failed}" -ne 0 ]]; then
	warn "At least one vendor was refused (see above); nothing from it was merged. Review the rest before pushing."
	exit 1
fi
p1 "Done. Review the diff output above before pushing."
