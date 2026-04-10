-- Force US keyboard layout when these apps gain focus.
-- Ghostty/Neovide lack iTerm2's native ForceKeyboard; iTerm2 included as backup.

local usLayout = "com.apple.keylayout.US"

local forceUSApps = {
	["Ghostty"] = true,
	["Neovide"] = true,
	["iTerm2"] = true,
	["Cursor"] = true,
}

local previousSourceID = nil

local inputSourceWatcher = hs.application.watcher.new(function(appName, eventType)
	if eventType == hs.application.watcher.activated then
		if forceUSApps[appName] then
			local current = hs.keycodes.currentSourceID()
			if current ~= usLayout then
				previousSourceID = current
			end
			hs.keycodes.currentSourceID(usLayout)
		elseif previousSourceID then
			hs.keycodes.currentSourceID(previousSourceID)
			previousSourceID = nil
		end
	end
end)

inputSourceWatcher:start()

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
