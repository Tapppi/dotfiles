#!/usr/bin/env bash
# Claude Code status line command
# Receives JSON via stdin; outputs a single status line string.
# Format: Model in dir | HH:MM | 21K/2% | 5h/23%/2h 7d/41%/3d

input=$(cat)

model=$(echo "${input}" | jq -r '.model.display_name // "unknown"')
cwd=$(echo "${input}" | jq -r '.workspace.current_dir // .cwd // ""')
used_pct=$(echo "${input}" | jq -r '.context_window.used_percentage // empty')
ctx_size=$(echo "${input}" | jq -r '.context_window.context_window_size // empty')
duration_ms=$(echo "${input}" | jq -r '.cost.total_duration_ms // empty')

# Solarized-inspired ANSI colors (render dimmed in the status bar)
orange='\033[38;5;166m'
green='\033[38;5;64m'
violet='\033[38;5;61m'
yellow='\033[38;5;136m'
white='\033[38;5;15m'
red='\033[38;5;124m'
reset='\033[0m'

# Model
printf '%b%s%b' "${orange}" "${model}" "${reset}"

# Current directory (basename only)
if [[ -n "${cwd}" ]]; then
	dir=$(basename "${cwd}")
	printf '%b in %b%s%b' "${white}" "${green}" "${dir}" "${reset}"
fi

# Session start time (derived from wall-clock duration)
if [[ -n "${duration_ms}" ]] && [[ "${duration_ms}" != "0" ]]; then
	duration_int=${duration_ms%%.*}
	if [[ "${duration_int}" =~ ^[0-9]+$ ]] && [[ "${duration_int}" -gt 0 ]]; then
		start_epoch=$(( $(date +%s) - duration_int / 1000 ))
		# GNU date uses -d @EPOCH, BSD/macOS date uses -r EPOCH
		start_time=$(date -d "@${start_epoch}" +"%H:%M" 2>/dev/null || /bin/date -r "${start_epoch}" +"%H:%M" 2>/dev/null)
		if [[ -n "${start_time}" ]]; then
			printf ' %b|%b %b%s%b' "${white}" "${reset}" "${violet}" "${start_time}" "${reset}"
		fi
	fi
fi

# Context window: tokens in thousands and percentage
if [[ -n "${used_pct}" ]] && [[ -n "${ctx_size}" ]]; then
	tokens_k=$(awk "BEGIN { printf \"%.0f\", ${ctx_size} * ${used_pct} / 100 / 1000 }")
	used_int=$(printf '%.0f' "${used_pct}")
	tokens=$(awk "BEGIN { printf \"%.0f\", ${ctx_size} * ${used_pct} / 100 }")

	# Color based on token count: <130K green, <200K yellow, >=200K red
	if [[ "${tokens}" -ge 200000 ]]; then
		ctx_color="${red}"
	elif [[ "${tokens}" -ge 130000 ]]; then
		ctx_color="${yellow}"
	else
		ctx_color="${green}"
	fi

	printf ' %b|%b %b%sK/%d%%%b' "${white}" "${reset}" "${ctx_color}" "${tokens_k}" "${used_int}" "${reset}"
fi

# Format remaining seconds: >1d → "2d", 1h–1d → "3h", <1h → "42m"
format_remaining() {
	local secs=$1
	local days=$((secs / 86400))
	local hours=$(( (secs % 86400) / 3600 ))
	local mins=$(( (secs % 3600) / 60 ))
	if [[ "${days}" -gt 0 ]]; then
		printf '%dd' "${days}"
	elif [[ "${hours}" -gt 0 ]]; then
		printf '%dh' "${hours}"
	else
		printf '%dm' "${mins}"
	fi
}

# Color a percentage: <66 green, 66–85 yellow, >85 red
pct_color() {
	local pct
	pct=$(printf '%.0f' "$1")
	if [[ "${pct}" -gt 85 ]]; then
		printf '%s' "${red}"
	elif [[ "${pct}" -ge 66 ]]; then
		printf '%s' "${yellow}"
	else
		printf '%s' "${green}"
	fi
}

# Rate limits: 5h/x%/countdown 7d/x%/countdown
five_pct=$(echo "${input}" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "${input}" | jq -r '.rate_limits.seven_day.used_percentage // empty')
five_reset=$(echo "${input}" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_reset=$(echo "${input}" | jq -r '.rate_limits.seven_day.resets_at // empty')

if [[ -n "${five_pct}" ]] || [[ -n "${week_pct}" ]]; then
	now=$(date +%s)
	printf ' %b|%b' "${white}" "${reset}"

	if [[ -n "${five_pct}" ]]; then
		printf ' %b5h%b/%b%d%%%b' "${white}" "${reset}" "$(pct_color "${five_pct}")" "$(printf '%.0f' "${five_pct}")" "${reset}"
		if [[ -n "${five_reset}" ]] && [[ "${five_reset}" -gt "${now}" ]]; then
			printf '/%b%s%b' "${violet}" "$(format_remaining $((five_reset - now)))" "${reset}"
		fi
	fi

	if [[ -n "${week_pct}" ]]; then
		printf ' %b7d%b/%b%d%%%b' "${white}" "${reset}" "$(pct_color "${week_pct}")" "$(printf '%.0f' "${week_pct}")" "${reset}"
		if [[ -n "${week_reset}" ]] && [[ "${week_reset}" -gt "${now}" ]]; then
			printf '/%b%s%b' "${violet}" "$(format_remaining $((week_reset - now)))" "${reset}"
		fi
	fi
fi
