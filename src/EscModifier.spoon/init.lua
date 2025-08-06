--[[
Spoon: EscModifier
Author: AI Conversion
Version: 1.0
License: MIT
Description: Turns the Escape key into a modifier when held, but sends a normal Escape key press when tapped.
--]]

local obj = {}
obj.name = "EscModifier"
obj.version = "1.0"
obj.author = "AI Conversion"
obj.license = "MIT - https://opensource.org/licenses/MIT"
obj.homepage = "https://www.hammerspoon.org"
obj.description = "Turns Escape into a modifier key when held."

-- ==============================================================================
-- Configuration
-- ==============================================================================
-- Define your key mappings here.
-- The format is: { key = "original_key", mods = { "modifier_keys" }, output = "output_key" }
--
--  - `key`: The key to press WHILE holding Escape (e.g., "h", "j", "k", "l").
--  - `mods`: An optional table of modifiers for the output key (e.g., {'ctrl'}).
--  - `output`: The key that should be sent to the system (e.g., "left", "down").
--
-- You can easily add, remove, or change these bindings.
obj.mappings = {
	-- VIM-like motion
	{ key = "h", output = "left" },
	{ key = "j", output = "down" },
	{ key = "k", output = "up" },
	{ key = "l", output = "right" },

	-- Word-wise motion
	{ key = "u", mods = { "ctrl" }, output = "left" }, -- Maps to Ctrl+Left (previous word)
	{ key = "i", mods = { "ctrl" }, output = "right" }, -- Maps to Ctrl+Right (next word)

	-- Line navigation
	{ key = "y", output = "home" }, -- Maps to Home key (start of line)
	{ key = "o", output = "end" }, -- Maps to End key (end of line)
}
-- ==============================================================================

-- Internal state variables
local escKeyDown = false
local escWasModifier = false
local eventTap

-- A lookup table for faster mapping access
local keyMappings = {}

--- EscModifier:init()
--- Spoon constructor
function obj:init()
	-- Pre-process the user-friendly mapping table into a faster lookup table
	for _, mapping in ipairs(obj.mappings) do
		keyMappings[mapping.key] = {
			mods = mapping.mods or {},
			output = mapping.output,
		}
	end
end

--- eventCallback(event)
--- The core logic that handles every keyboard event.
local function eventCallback(event)
	local eventType = event:getType()
	local keyCode = event:getKeyCode()

	-- We only care about the Escape key for our primary logic.
	-- hs.keycodes.map.escape is the numerical keycode for the Escape key.
	if keyCode == hs.keycodes.map.escape then
		if eventType == hs.eventtap.event.types.keyDown then
			-- If Escape is already considered down, this is a key repeat. Ignore it.
			if escKeyDown then
				return true
			end

			escKeyDown = true
			escWasModifier = false -- Reset flag on each new press
			return true -- Swallow the event. We'll decide what to do on keyUp.
		elseif eventType == hs.eventtap.event.types.keyUp then
			escKeyDown = false
			-- If Escape was NOT used as a modifier, it means it was a simple tap.
			-- In this case, we send a "vanilla" Escape key press to the system.
			if not escWasModifier then
				hs.eventtap.keyStroke({}, "escape")
			end
			return true -- Always swallow the original Escape up-event.
		end
	end

	-- If another key is pressed WHILE Escape is being held down...
	if escKeyDown and eventType == hs.eventtap.event.types.keyDown then
		-- Convert the keycode of the pressed key to a character (e.g., 4 -> 'h')
		local key = hs.keycodes.currentLayout()[keyCode]

		if key and keyMappings[key] then
			-- We have a match in our configuration!
			escWasModifier = true -- Mark Escape as having been used as a modifier.
			local mapping = keyMappings[key]
			hs.eventtap.keyStroke(mapping.mods, mapping.output)
			return true -- Swallow the original key (e.g., the 'h' key press)
		end
	end

	-- For all other events, do nothing and let them pass through.
	return false
end

--- EscModifier:start()
--- Starts the Spoon's event tap.
function obj:start()
	self:stop() -- Ensure it's not already running
	eventTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp }, eventCallback)
	eventTap:start()
end

--- EscModifier:stop()
--- Stops the Spoon's event tap.
function obj:stop()
	if eventTap then
		eventTap:stop()
		eventTap = nil
	end
end

return obj
