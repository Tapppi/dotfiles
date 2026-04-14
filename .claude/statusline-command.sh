#!/usr/bin/env bash
# Claude Code status line command
# Receives JSON via stdin; outputs a single status line string.

input=$(cat)

model=$(echo "${input}" | jq -r '.model.display_name // "unknown"')
cwd=$(echo "${input}" | jq -r '.workspace.current_dir // .cwd // ""')
used_pct=$(echo "${input}" | jq -r '.context_window.used_percentage // empty')
remaining_pct=$(echo "${input}" | jq -r '.context_window.remaining_percentage // empty')

# Solarized-inspired ANSI colors (will render dimmed in the status bar)
orange='\033[38;5;166m'
green='\033[38;5;64m'
violet='\033[38;5;61m'
yellow='\033[38;5;136m'
white='\033[38;5;15m'
red='\033[38;5;124m'
reset='\033[0m'

# Model
printf "${orange}%s${reset}" "${model}"

# Current directory (basename only, for brevity)
if [[ -n "${cwd}" ]]; then
	dir=$(basename "${cwd}")
	printf "${white} in ${green}%s${reset}" "${dir}"
fi

# Context window usage (prominently shown)
if [[ -n "${used_pct}" ]] && [[ -n "${remaining_pct}" ]]; then
	used_int=$(printf '%.0f' "${used_pct}")
	remaining_int=$(printf '%.0f' "${remaining_pct}")

	# Color the context indicator based on how much is used
	if [[ "${used_int}" -ge 80 ]]; then
		ctx_color="${red}"
	elif [[ "${used_int}" -ge 50 ]]; then
		ctx_color="${yellow}"
	else
		ctx_color="${green}"
	fi

	printf " ${white}ctx${reset} ${ctx_color}%d%%${reset}${white} used${reset} ${white}(${violet}%d%%${white} left)${reset}" \
		"${used_int}" "${remaining_int}"
fi

# Rate limits (5-hour and 7-day), shown only when available
five_pct=$(echo "${input}" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "${input}" | jq -r '.rate_limits.seven_day.used_percentage // empty')

if [[ -n "${five_pct}" ]] || [[ -n "${week_pct}" ]]; then
	printf " ${white}|${reset}"
	[[ -n "${five_pct}" ]] && printf " ${white}5h${reset} ${yellow}%d%%${reset}" "$(printf '%.0f' "${five_pct}")"
	[[ -n "${week_pct}" ]] && printf " ${white}7d${reset} ${yellow}%d%%${reset}" "$(printf '%.0f' "${week_pct}")"
fi
