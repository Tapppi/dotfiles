local whu = require("window-hotkey-utils")

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
	if current ~= whu.us then
		previousSourceID = current
	end
	whu.setInputSource(whu.us)
end

local function restorePreviousLayout()
	if previousSourceID then
		whu.setInputSource(previousSourceID)
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

-- ─── Custom layouts ────────────────────────────────────────────────

-- Chat: laptop fullscreen when lid open, else right side of active
-- screen (35% on widescreen, 50% on regular).
local function chatLayout(screen)
	local builtIn = whu.builtInScreen()
	if builtIn then
		return whu.fullFrame(builtIn)
	end
	if whu.isWidescreen(screen) then
		return whu.rightFrame(screen, 0.35, 3)
	end
	return whu.rightFrame(screen, 0.5, 3)
end

-- ─── App hotkeys ───────────────────────────────────────────────────

-- Ghostty (hyper+s) — US layout via forceUSApps, auto-position new windows
whu.bindToggle("s", "com.mitchellh.ghostty", whu.sidebar("left", 0.6), {
	inputSource = whu.us,
	watchCreate = true,
})

-- Brave (hyper+b)
whu.bindToggle("b", "com.brave.Browser", whu.sidebar("right", 0.4))

-- Safari (hyper+v)
whu.bindToggle("v", "com.apple.Safari", whu.sidebar("right", 0.4))

-- Slack (hyper+k)
whu.bindToggle("k", "com.tinyspeck.slackmacgap", chatLayout)

-- Teams (hyper+i)
whu.bindToggle("i", "com.microsoft.teams2", chatLayout)

-- Finder (hyper+f)
whu.bindToggle("f", "com.apple.finder", whu.corner("topleft", 800, 600, 10))

-- Calendar (hyper+c) — no resize, just center on active screen
whu.bindToggle("c", "com.apple.iCal", whu.center())

-- Obsidian (hyper+j) — US layout via forceUSApps
whu.bindToggle("j", "md.obsidian", whu.sidebar("right", 0.4), {
	inputSource = whu.us,
})

-- Spotify (hyper+m)
whu.bindToggle("m", "com.spotify.client", whu.corner("topleft", 800, 600, 10))
