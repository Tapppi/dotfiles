-- Force US keyboard layout when these apps gain focus.
-- Uses hs.window.filter for reliable focus tracking, including programmatic
-- focus changes from the Ghostty toggle hotkey below. The old
-- hs.application.watcher approach missed activations from app:unhide() +
-- win:focus() because those fire NSWorkspaceDidUnhideApplicationNotification,
-- not NSWorkspaceDidActivateApplicationNotification.

local usLayout = "com.apple.keylayout.US"

local forceUSApps = {
	["Ghostty"] = true,
	["Neovide"] = true,
	["iTerm2"] = true,
	["Cursor"] = true,
}

-- Last non-US layout before forcing kicked in. Never set to usLayout so
-- restore always has a valid target (or nil if the user was already in US).
local previousSourceID = nil

-- Retry-aware input source setter.
-- TISSelectInputSource can silently fail to switch the actual layout while
-- reporting success (macOS bug, Hammerspoon #1429). Verify and retry once.
local function forceInputSource(sourceID)
	hs.keycodes.currentSourceID(sourceID)
	hs.timer.doAfter(0.05, function()
		if hs.keycodes.currentSourceID() ~= sourceID then
			hs.keycodes.currentSourceID(sourceID)
		end
	end)
end

local function activateUSLayout()
	local current = hs.keycodes.currentSourceID()
	if current ~= usLayout then
		previousSourceID = current
	end
	forceInputSource(usLayout)
end

local function restorePreviousLayout()
	if previousSourceID then
		forceInputSource(previousSourceID)
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

-- Toggle Ghostty window with hyper+s.

local ghosttyBundleID = "com.mitchellh.ghostty"

local targetFrame = function()
	local screen = hs.mouse.getCurrentScreen() or hs.screen.primaryScreen()
	local f = screen:frame()
	local width = (f.w / f.h > 2.2) and math.floor(f.w / 2) or f.w

	return hs.geometry.rect(f.x, f.y, width, f.h)
end

local ghosttyWindowFilter = hs.window.filter.new("Ghostty")

ghosttyWindowFilter:subscribe(hs.window.filter.windowCreated, function(win)
	win:setFrame(targetFrame())
	win:focus()
end)

hs.hotkey.bind({"cmd", "ctrl", "alt", "shift"}, "s", function()
	local app = hs.application.get(ghosttyBundleID)

	if not app or #app:allWindows() == 0 then
		hs.application.launchOrFocusByBundleID(ghosttyBundleID)
		return
	end

	local win = app:mainWindow()

	if win and win:isVisible() then
		app:hide()
		return
	end

	if win then
		win:setFrame(targetFrame())
		app:unhide()
		win:focus()
	end
end)
