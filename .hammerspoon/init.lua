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
