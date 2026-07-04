#!/usr/bin/env bash
# collect.sh — gather update candidates for the tool-update-review skill.
# Usage: collect.sh [path-to-Brewfile]
# Emits one JSON object on stdout:
#   { machine: {...}, brew: [...], mise: [...], standalone: [...] }
# Network use is limited to version lookups for standalone tools; every
# lookup is best-effort with a timeout so the script works offline
# (latest_version is then null and research must fill it in).
set -euo pipefail

brewfile="${1:-Brewfile}"

# Machine context — arch gates compatibility findings (e.g. ARM-only deps)
arch="$(uname -m)"
os_name="macOS $(sw_vers -productVersion 2>/dev/null || echo '?')"
hostname="$(hostname -s 2>/dev/null || echo '?')"

# Names manifested in the Brewfile, so transitive deps don't pollute the report
brewfile_formulae="[]"
brewfile_casks="[]"
if [[ -f "${brewfile}" ]]; then
	brewfile_formulae="$(grep -E '^brew "' "${brewfile}" | sed -E 's/^brew "([^"]+)".*/\1/' | sed -E 's|.*/||' | jq -R . | jq -s .)"
	brewfile_casks="$(grep -E '^cask "' "${brewfile}" | sed -E 's/^cask "([^"]+)".*/\1/' | jq -R . | jq -s .)"
else
	echo "warning: Brewfile not found at ${brewfile}; brew section will be empty" >&2
fi

# brew outdated intersected with Brewfile entries; keeps pin state.
# `brew outdated` matches on the short name even when the Brewfile taps
# a qualified name (e.g. hashicorp/tap/terraform), hence the `sed s|.*/||`.
brew_json="$(brew outdated --json=v2 2>/dev/null | jq \
	--argjson formulae "${brewfile_formulae}" \
	--argjson casks "${brewfile_casks}" '
	[ (.formulae[] | select(.name as $n | $formulae | index($n)) | {
			id: ("brew:" + .name), name: .name, source: "brew",
			current_version: (.installed_versions | last),
			latest_version: .current_version,
			pinned: .pinned
		}),
		(.casks[] | select(.name as $n | $casks | index($n)) | {
			id: ("cask:" + .name), name: .name, source: "cask",
			current_version: .installed_versions[-1],
			latest_version: .current_version,
			pinned: false
		}) ]')"

# Pinned formulae are hidden from `brew outdated` by default; surface them
# explicitly so a pinned-but-behind tool (the whole point of a pin) shows up.
pinned_json="[]"
pinned_names="$(brew list --pinned 2>/dev/null || true)"
if [[ -n "${pinned_names}" ]]; then
	pinned_json="$(while IFS= read -r name; do
		info="$(brew info --json=v2 "${name}" 2>/dev/null)" || continue
		printf '%s' "${info}" | jq --arg name "${name}" '
			.formulae[0] | {
				id: ("brew:" + $name), name: $name, source: "brew",
				current_version: (.installed | last | .version),
				latest_version: .versions.stable,
				pinned: true
			}'
	done <<< "${pinned_names}" | jq -s .)"
fi

# mise runtimes
mise_json="$(mise outdated --json 2>/dev/null | jq '
	[ to_entries[] | {
			id: ("mise:" + .key), name: .key, source: "mise",
			current_version: .value.current,
			latest_version: .value.latest,
			pinned: false
		} ]' || echo '[]')"

# Standalone CLIs installed outside brew. Latest versions are best-effort:
# null when offline or the lookup fails — research fills the gap.
claude_current="$(claude --version 2>/dev/null | awk '{print $1}' || true)"
claude_latest="$(curl -fsS --max-time 10 https://registry.npmjs.org/@anthropic-ai/claude-code/latest 2>/dev/null | jq -r .version || true)"
codex_current="$(codex --version 2>/dev/null | awk '{print $2}' || true)"
codex_latest="$(curl -fsS --max-time 10 https://api.github.com/repos/openai/codex/releases/latest 2>/dev/null | jq -r '.tag_name // empty' | sed 's/^rust-v//; s/^v//' || true)"

standalone_json="$(jq -n \
	--arg cc "${claude_current}" --arg cl "${claude_latest}" \
	--arg xc "${codex_current}" --arg xl "${codex_latest}" '
	[ { id: "standalone:claude-code", name: "claude-code", source: "standalone",
			current_version: ($cc | select(. != "")),
			latest_version: ($cl | select(. != "")), pinned: false },
		{ id: "standalone:codex", name: "codex", source: "standalone",
			current_version: ($xc | select(. != "")),
			latest_version: ($xl | select(. != "")), pinned: false }
	] | map(select(.current_version != null)) ]' 2>/dev/null || echo '[]')"

jq -n \
	--arg arch "${arch}" --arg os "${os_name}" --arg host "${hostname}" \
	--argjson brew "${brew_json}" --argjson pinned "${pinned_json}" \
	--argjson mise "${mise_json}" --argjson standalone "${standalone_json}" '
	{
		machine: { arch: $arch, os: $os, hostname: $host },
		brew: (($brew + $pinned) | unique_by(.id)
			| map(select(.current_version != .latest_version))),
		mise: ($mise | map(select(.current_version != .latest_version))),
		standalone: ($standalone
			| map(select(.latest_version == null or .current_version != .latest_version)))
	}'
