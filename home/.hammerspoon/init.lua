local utils = require("hotkey-utils")

-- ─── Per-app US keyboard layout forcing ────────────────────────────
-- Forces US layout when these apps gain focus, restores on blur.
-- Uses hs.window.filter for reliable focus tracking, including
-- programmatic focus changes from hotkey toggles.

local forceUSApps = {
	["Ghostty"] = true,
	["Neovide"] = true,
	["iTerm2"] = true,
	["Cursor"] = true,
	["Obsidian"] = true,
}

-- Last non-US layout before forcing kicked in. Never set to US so
-- restore always has a valid target (or nil if the user was already in US).
local previousSourceID = nil

local function activateUSLayout()
	local current = hs.keycodes.currentSourceID()
	if current ~= utils.us then
		previousSourceID = current
	end
	utils.setInputSource(utils.us)
end

local function restorePreviousLayout()
	if previousSourceID then
		utils.setInputSource(previousSourceID)
		previousSourceID = nil
	end
end

-- Primary: track focus changes on all windows.
-- windowFocused fires for both user-initiated (Cmd+Tab, click) and
-- programmatic (win:focus(), app:unhide()) focus changes.
local focusFilter = hs.window.filter.new(nil)

focusFilter:subscribe(hs.window.filter.windowFocused, function(win)
	local app = win:application()
	if not app then return end

	if forceUSApps[app:name()] then
		activateUSLayout()
	else
		restorePreviousLayout()
	end
end)

-- Fallback: restore layout when a forceUS window disappears (hidden,
-- minimised, closed) and no other window immediately gains focus.
local forceUSFilter = hs.window.filter.new(false)
for name in pairs(forceUSApps) do
	forceUSFilter:setAppFilter(name, {})
end

forceUSFilter:subscribe(hs.window.filter.windowNotVisible, function()
	local focused = hs.window.focusedWindow()
	if focused then
		local app = focused:application()
		if app and forceUSApps[app:name()] then
			return
		end
	end
	restorePreviousLayout()
end)

-- ─── Layout functions ──────────────────────────────────────────────

-- Ghostty: left 65% on widescreen, fullscreen on regular.
local function ghosttyLayout(screen)
	if utils.isWidescreen(screen) then
		return utils.leftFrame(screen, 0.65)
	end
	return utils.fullFrame(screen)
end

-- Browser: fullscreen on regular, right 35% on widescreen.
local function browserLayout(screen)
	if utils.isWidescreen(screen) then
		return utils.rightFrame(screen, 0.35)
	end
	return utils.fullFrame(screen)
end

-- Chat: laptop fullscreen when lid open, else right side of active
-- screen (35% on widescreen, 50% on regular).
local function chatLayout(screen)
	local builtIn = utils.builtInScreen()
	if builtIn then
		return utils.fullFrame(builtIn)
	end
	if utils.isWidescreen(screen) then
		return utils.rightFrame(screen, 0.35)
	end
	return utils.rightFrame(screen, 0.5)
end

-- Sidebar: left half, full height, active screen.
local function sidebarLayout(screen)
	return utils.leftFrame(screen, 0.5)
end

-- Center: no resize, center on active screen.
local function centerLayout(screen, win)
	return utils.centerFrame(screen, win)
end

-- ─── App hotkeys ───────────────────────────────────────────────────

-- Ghostty (hyper+s) — US layout via forceUSApps, auto-position new windows
utils.bindToggle("s", "com.mitchellh.ghostty", ghosttyLayout, {
	inputSource = utils.us,
	watchCreate = true,
})

-- Brave (hyper+b)
utils.bindToggle("b", "com.brave.Browser", browserLayout)

-- Safari (hyper+v)
utils.bindToggle("v", "com.apple.Safari", browserLayout)

-- Slack (hyper+k)
utils.bindToggle("k", "com.tinyspeck.slackmacgap", chatLayout)

-- Teams (hyper+i)
utils.bindToggle("i", "com.microsoft.teams2", chatLayout)

-- Finder (hyper+f)
utils.bindToggle("f", "com.apple.finder", sidebarLayout)

-- Calendar (hyper+c) — no resize, just center on active screen
utils.bindToggle("c", "com.apple.iCal", centerLayout)

-- Obsidian (hyper+j) — US layout with reset via forceUSApps
utils.bindToggle("j", "md.obsidian", browserLayout, {
	inputSource = utils.us,
})

-- Spotify (hyper+m)
utils.bindToggle("m", "com.spotify.client", sidebarLayout)
