#!/usr/bin/env bash
# Claude Code status line command
# Receives JSON via stdin; outputs a single status line string.
# Format: Model in dir | HH:MM | 21.4K (2%) | 5h 23% 7d 41% ~2h13m

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
	tokens_k=$(awk "BEGIN { printf \"%.1f\", ${ctx_size} * ${used_pct} / 100 / 1000 }")
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

	printf ' %b|%b %b%sK (%d%%)%b' "${white}" "${reset}" "${ctx_color}" "${tokens_k}" "${used_int}" "${reset}"
fi

# Rate limits with countdown to reset
five_pct=$(echo "${input}" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "${input}" | jq -r '.rate_limits.seven_day.used_percentage // empty')
five_reset=$(echo "${input}" | jq -r '.rate_limits.five_hour.resets_at // empty')

if [[ -n "${five_pct}" ]] || [[ -n "${week_pct}" ]]; then
	printf ' %b|%b' "${white}" "${reset}"
	[[ -n "${five_pct}" ]] && printf ' %b5h%b %b%d%%%b' "${white}" "${reset}" "${yellow}" "$(printf '%.0f' "${five_pct}")" "${reset}"
	[[ -n "${week_pct}" ]] && printf ' %b7d%b %b%d%%%b' "${white}" "${reset}" "${yellow}" "$(printf '%.0f' "${week_pct}")" "${reset}"

	# Countdown to 5-hour window reset
	if [[ -n "${five_reset}" ]]; then
		now=$(date +%s)
		if [[ "${five_reset}" -gt "${now}" ]]; then
			remaining=$((five_reset - now))
			hours=$((remaining / 3600))
			mins=$(( (remaining % 3600) / 60 ))
			if [[ "${hours}" -gt 0 ]]; then
				countdown="${hours}h${mins}m"
			else
				countdown="${mins}m"
			fi
			printf ' %b~%b%s%b' "${white}" "${violet}" "${countdown}" "${reset}"
		fi
	fi
fi
