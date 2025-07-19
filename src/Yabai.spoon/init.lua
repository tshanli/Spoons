--[[
Spoon: Yabai
Author: Tshan Li (Original Karabiner config), AI Conversion
Version: 1.0
License: MIT
Description: Provides yabai window manager keybindings, converted from a Karabiner-Elements JSON file.
--]]

CURRENT_SCRATCHPAD = nil

---Run command, used in hotkey bindings
---@param cmd any
---@return boolean
local function _cmd(cmd)
	local type = type(cmd)

	if type == "table" then
		for _, v in ipairs(cmd) do
			_cmd(v)
		end
	elseif type == "string" then
		local status = hs.execute(cmd, true)
		if not status then
			hs.printf("Error: command: ", cmd)
			return false
		end
	elseif type == "function" then
		return cmd() and true or false
	else
		hs.printf("Error: unsupported command type: ", type)
		return false
	end
	return true
end

---Execute yabai query command. If failed, return nil; if succeed, return decoded json
---@param cmd string
---@param key? string
---@return string|nil
local function _query(cmd, key)
	local output, status = hs.execute(cmd, true)
	if not status then
		return nil
	end

	local res = hs.json.decode(output)
	if not res then
		hs.printf("Error: decode json")
		return nil
	end
	if not key then
		return res
	else
		return res[key]
	end
end

---Query cuurent space
---@return string|nil
local function _query_current_space()
	return _query("yabai -m query --spaces --space")
end

---Focus window
---@param direction string
---@return boolean
local function _focus_window(direction)
	local cmd = "yabai -m window --fcous " .. direction
	local status = hs.execute(cmd, true)
	return status and true or false
end

local function _is_current_win_stack_last()
	local stack_last = _query("yabai -m query --windows --window stack.last --space", "id")
	local current = _query("yabai -m query --windows --window", "id")
	return stack_last == current
end

local function _is_current_win_stack_first()
	local stack_last = _query("yabai -m query --windows --window stack.first --space", "id")
	local current = _query("yabai -m query --windows --window", "id")
	return stack_last == current
end

---Focus window. When in bsp, it goes north/south; when in stack, it goes next/prev
---@param direction string
---| "'up'"
---| "'down'"
---@return boolean
local function _focus_vertical_window(direction)
	local space_info = _query_current_space()
	if not space_info then
		hs.printf("Error: Can't get current space information")
		return false
	end
	local dt = nil
	local type = space_info["type"]

	if type == "bsp" then
		dt = direction == "up" and "north" or "south"
	else
		if direction == "up" then
			dt = _is_current_win_stack_first() and "last" or "prev"
		else
			dt = _is_current_win_stack_last() and "first" or "next"
		end
	end

	local res = _focus_window(dt)
	local err_msg = "Error: focus window: " .. direction
	if not res then
		hs.printf(err_msg)
		return false
	end
	return true
end

local function _focus_window_up()
	_focus_vertical_window("up")
end

local function _focus_window_down()
	_focus_vertical_window("down")
end

local function _center_window()
	local win = hs.window.focusedWindow()
	if not win then
		hs.printf("Error: no focused window to center")
		return false
	end
	local frame = win:frame()
	local screenFrame = win:screen():frame()
	frame.x = screenFrame.x + (screenFrame.w - frame.w) / 2
	frame.y = screenFrame.y + (screenFrame.h - frame.h) / 2
	win:setFrame(frame)
	return true
end

---Resize focused window to 70% of screen, max 1440x900, and center it
---@return boolean
local function _resize_and_center_window()
	local win = hs.window.focusedWindow()
	if not win then
		hs.printf("No focused window to resize and center")
		return false
	end
	local screenFrame = win:screen():frame()
	local targetWidth = math.floor(screenFrame.w * 0.7)
	local targetHeight = math.floor(screenFrame.h * 0.7)
	if targetWidth > 1440 then
		targetWidth = 1440
	end
	if targetHeight > 900 then
		targetHeight = 900
	end
	local newFrame = {
		x = screenFrame.x + (screenFrame.w - targetWidth) / 2,
		y = screenFrame.y + (screenFrame.h - targetHeight) / 2,
		w = targetWidth,
		h = targetHeight,
	}
	win:setFrame(newFrame)
	return true
end

---Toggle scratchpad
---@param name string
---@return boolean
local function _toggle_scratchpad(name)
	local cmd = "yabai -m window --toggle " .. name
	local status = hs.execute(cmd, true)
	if not status then
		return false
	end
	CURRENT_SCRATCHPAD = name
	return true
end

local function _toggle_scratchpad_wrapper(name)
	return function()
		return _toggle_scratchpad(name)
	end
end

---Set scratchpad
---@param name string
---@return boolean
local function _set_scratchpad(name)
	local cmd = "yabai -m window --scratchpad " .. name
	local status = hs.execute(cmd, true)
	if not status then
		return false
	end
	CURRENT_SCRATCHPAD = name
	return true
end

local function _set_scratchpad_wrapper(name)
	return function()
		return _set_scratchpad(name)
	end
end

---Toggle current scratchpad
---@return boolean
local function _toggle_current_scratchpad()
	if not CURRENT_SCRATCHPAD then
		return false
	end

	return _toggle_scratchpad(CURRENT_SCRATCHPAD)
end

local obj = {}
obj.name = "Yabai"
obj.version = "1.0"
obj.author = "Tshan Li (Original), AI Conversion"
obj.license = "MIT - https://opensource.org/licenses/MIT"
obj.homepage = "https://www.hammerspoon.org"
obj.description = "Yabai keybindings converted from Karabiner-Elements JSON."

-- A table to hold the hotkey objects, allowing them to be stopped later.
obj.boundHotkeys = {}

-- Define all hotkey mappings here.
-- The 'description' field is optional but helpful for debugging.
obj.hotkeys = {
	-- =================================================================================
	-- General Window Management
	-- =================================================================================
	{ mods = { "alt" }, key = "m", cmd = "yabai -m window --minimize", description = "Yabai: Minimize window" },
	{
		mods = { "alt" },
		key = "s",
		cmd = "yabai -m window --toggle zoom-fullscreen",
		description = "Yabai: Toggle zoom-fullscreen",
	},
	{
		mods = { "alt", "shift" },
		key = "s",
		cmd = "yabai -m window --toggle zoom-parent",
		description = "Yabai: Toggle zoom-parent",
	},
	{ mods = { "alt" }, key = "f", cmd = "yabai -m window --toggle float", description = "Yabai: Toggle float" },
	{ mods = { "alt" }, key = "w", cmd = "yabai -m window --close", description = "Yabai: Close window" },

	-- =================================================================================
	-- Window Focus (VIM-like)
	-- =================================================================================
	{ mods = { "alt" }, key = "h", cmd = "yabai -m window --focus west", description = "Yabai: Focus west" },
	{ mods = { "alt" }, key = "l", cmd = "yabai -m window --focus east", description = "Yabai: Focus east" },
	-- This command intelligently handles focus for both BSP and Stack layouts.
	{
		mods = { "alt" },
		key = "j",
		-- cmd = "[[if [[ $(yabai -m query --spaces --space | jq '.type') == '\"stack\"' ]]; then (if [[ $(yabai -m query --windows --window stack.last --space | jq '.id') -ne $(yabai -m query --windows --window | jq '.id') ]]; then yabai -m window --focus stack.next ; else yabai -m window --focus stack.first; fi); else yabai -m window --focus south ; fi]]",
		cmd = _focus_window_down,
		description = "Yabai: Focus south/next",
	},
	{
		mods = { "alt" },
		key = "k",
		-- cmd = "[[if [[ $(yabai -m query --spaces --space | jq '.type') == '\"stack\"' ]]; then (if [[ $(yabai -m query --windows --window stack.first --space | jq '.id') -ne $(yabai -m query --windows --window | jq '.id') ]]; then yabai -m window --focus stack.prev ; else yabai -m window --focus stack.last; fi); else yabai -m window --focus north ; fi]]",
		cmd = _focus_window_up,
		description = "Yabai: Focus north/prev",
	},

	-- =================================================================================
	-- Window Swapping (Move window position)
	-- =================================================================================
	{
		mods = { "alt", "shift" },
		key = "h",
		cmd = "yabai -m window --swap west",
		description = "Yabai: Swap window west",
	},
	{
		mods = { "alt", "shift" },
		key = "j",
		cmd = "yabai -m window --swap south",
		description = "Yabai: Swap window south",
	},
	{
		mods = { "alt", "shift" },
		key = "k",
		cmd = "yabai -m window --swap north",
		description = "Yabai: Swap window north",
	},
	{
		mods = { "alt", "shift" },
		key = "l",
		cmd = "yabai -m window --swap east",
		description = "Yabai: Swap window east",
	},

	-- =================================================================================
	-- Window Warping (Move focus without moving window)
	-- =================================================================================
	{
		mods = { "alt", "ctrl", "shift" },
		key = "h",
		cmd = "yabai -m window --warp west",
		description = "Yabai: Warp to window west",
	},
	{
		mods = { "alt", "ctrl", "shift" },
		key = "j",
		cmd = "yabai -m window --warp south",
		description = "Yabai: Warp to window south",
	},
	{
		mods = { "alt", "ctrl", "shift" },
		key = "k",
		cmd = "yabai -m window --warp north",
		description = "Yabai: Warp to window north",
	},
	{
		mods = { "alt", "ctrl", "shift" },
		key = "l",
		cmd = "yabai -m window --warp east",
		description = "Yabai: Warp to window east",
	},

	-- =================================================================================
	-- Window Resizing
	-- =================================================================================
	{
		mods = { "alt", "ctrl" },
		key = "h",
		cmd = { "yabai -m window --resize left:-50:0", "yabai -m window --resize right:-50:0" },
		description = "Yabai: Resize shrink width",
	},
	{
		mods = { "alt", "ctrl" },
		key = "l",
		cmd = { "yabai -m window --resize left:50:0", "yabai -m window --resize right:50:0" },
		description = "Yabai: Resize expand width",
	},
	{
		mods = { "alt", "ctrl" },
		key = "j",
		cmd = { "yabai -m window --resize top:0:50", "yabai -m window --resize bottom:0:50" },
		description = "Yabai: Resize expand height",
	},
	{
		mods = { "alt", "ctrl" },
		key = "k",
		cmd = { "yabai -m window --resize top:0:-50 ", "yabai -m window --resize bottom:0:-50" },
		description = "Yabai: Resize shrink height",
	},

	-- =================================================================================
	-- Window Centering (via script)
	-- =================================================================================
	{
		mods = { "alt", "shift" },
		key = "c",
		cmd = _resize_and_center_window,
		description = "Yabai: Center window (relative)",
	},
	{
		mods = { "alt" },
		key = "c",
		cmd = _center_window,
		description = "Yabai: Center window",
	},

	-- =================================================================================
	-- Window Properties (Sticky, Topmost, PiP)
	-- =================================================================================
	{
		mods = { "alt", "shift" },
		key = "p",
		cmd = "yabai -m window --toggle sticky",
		description = "Yabai: Toggle sticky",
	},
	{
		mods = { "alt" },
		key = "p",
		cmd = "yabai -m window --toggle topmost",
		description = "Yabai: Toggle topmost",
	},
	{
		mods = { "alt", "ctrl" },
		key = "p",
		cmd = "yabai -m window --toggle pip",
		description = "Yabai: Toggle picture-in-picture",
	},

	-- =================================================================================
	-- Space Layout Management
	-- =================================================================================
	{ mods = { "alt" }, key = "z", cmd = "yabai -m space --equalize", description = "Yabai: Equalize space" },
	{
		mods = { "alt", "shift" },
		key = "z",
		cmd = "yabai -m space --layout stack",
		description = "Yabai: Set layout to stack",
	},
	{
		mods = { "alt", "ctrl" },
		key = "z",
		cmd = "yabai -m space --layout bsp",
		description = "Yabai: Set layout to bsp",
	},

	-- =================================================================================
	-- Space Focus
	-- =================================================================================
	{
		mods = { "alt" },
		key = "`",
		cmd = "yabai -m space --focus recent",
		description = "Yabai: Focus recent space",
	},
	{
		mods = { "alt", "ctrl" },
		key = "left",
		cmd = "yabai -m space --focus prev",
		description = "Yabai: Focus previous space",
	},
	{
		mods = { "alt", "ctrl" },
		key = "right",
		cmd = "yabai -m space --focus next",
		description = "Yabai: Focus next space",
	},
	{ mods = { "alt" }, key = "1", cmd = "yabai -m space --focus 1", description = "Yabai: Focus space 1" },
	{ mods = { "alt" }, key = "2", cmd = "yabai -m space --focus 2", description = "Yabai: Focus space 2" },
	{ mods = { "alt" }, key = "3", cmd = "yabai -m space --focus 3", description = "Yabai: Focus space 3" },
	{ mods = { "alt" }, key = "4", cmd = "yabai -m space --focus 4", description = "Yabai: Focus space 4" },
	{ mods = { "alt" }, key = "5", cmd = "yabai -m space --focus 5", description = "Yabai: Focus space 5" },
	{ mods = { "alt" }, key = "6", cmd = "yabai -m space --focus 6", description = "Yabai: Focus space 6" },
	{ mods = { "alt" }, key = "7", cmd = "yabai -m space --focus 7", description = "Yabai: Focus space 7" },
	{ mods = { "alt" }, key = "8", cmd = "yabai -m space --focus 8", description = "Yabai: Focus space 8" },
	{ mods = { "alt" }, key = "9", cmd = "yabai -m space --focus 9", description = "Yabai: Focus space 9" },
	{ mods = { "alt" }, key = "0", cmd = "yabai -m space --focus 10", description = "Yabai: Focus space 10" },
	{
		mods = { "alt" },
		key = "-",
		cmd = "yabai -m space --focus prev",
		description = "Yabai: Focus previous space",
	},
	{ mods = { "alt" }, key = "=", cmd = "yabai -m space --focus next", description = "Yabai: Focus next space" },

	-- =================================================================================
	-- Move Window to Space
	-- =================================================================================
	{
		mods = { "alt", "shift" },
		key = "`",
		cmd = { "yabai -m window --space recent", "yabai -m space --focus recent" },
		description = "Yabai: Move window to recent space and focus",
	},
	{
		mods = { "alt", "ctrl" },
		key = "`",
		cmd = "yabai -m window --space recent",
		description = "Yabai: Move window to recent space",
	},
	-- Move window to space N and focus
	{ mods = { "alt", "shift" }, key = "1", cmd = { "yabai -m window --space 1", "yabai -m space --focus 1" } },
	{ mods = { "alt", "shift" }, key = "2", cmd = { "yabai -m window --space 2", "yabai -m space --focus 2" } },
	{ mods = { "alt", "shift" }, key = "3", cmd = { "yabai -m window --space 3", "yabai -m space --focus 3" } },
	{ mods = { "alt", "shift" }, key = "4", cmd = { "yabai -m window --space 4", "yabai -m space --focus 4" } },
	{ mods = { "alt", "shift" }, key = "5", cmd = { "yabai -m window --space 5", "yabai -m space --focus 5" } },
	{ mods = { "alt", "shift" }, key = "6", cmd = { "yabai -m window --space 6", "yabai -m space --focus 6" } },
	{ mods = { "alt", "shift" }, key = "7", cmd = { "yabai -m window --space 7", "yabai -m space --focus 7" } },
	{ mods = { "alt", "shift" }, key = "8", cmd = { "yabai -m window --space 8", "yabai -m space --focus 8" } },
	{ mods = { "alt", "shift" }, key = "9", cmd = { "yabai -m window --space 9", "yabai -m space --focus 9" } },
	{ mods = { "alt", "shift" }, key = "0", cmd = { "yabai -m window --space 10", "yabai -m space --focus 10" } },
	{ mods = { "alt", "shift" }, key = "-", cmd = { "yabai -m window --space prev", "yabai -m space --focus prev" } },
	{ mods = { "alt", "shift" }, key = "=", cmd = { "yabai -m window --space next", "yabai -m space --focus next" } },

	-- Move window to space N (no focus change)
	{ mods = { "alt", "ctrl" }, key = "1", cmd = "yabai -m window --space 1" },
	{ mods = { "alt", "ctrl" }, key = "2", cmd = "yabai -m window --space 2" },
	{ mods = { "alt", "ctrl" }, key = "3", cmd = "yabai -m window --space 3" },
	{ mods = { "alt", "ctrl" }, key = "4", cmd = "yabai -m window --space 4" },
	{ mods = { "alt", "ctrl" }, key = "5", cmd = "yabai -m window --space 5" },
	{ mods = { "alt", "ctrl" }, key = "6", cmd = "yabai -m window --space 6" },
	{ mods = { "alt", "ctrl" }, key = "7", cmd = "yabai -m window --space 7" },
	{ mods = { "alt", "ctrl" }, key = "8", cmd = "yabai -m window --space 8" },
	{ mods = { "alt", "ctrl" }, key = "9", cmd = "yabai -m window --space 9" },
	{ mods = { "alt", "ctrl" }, key = "0", cmd = "yabai -m window --space 10" },
	--- CONFLICT: The following hotkeys are defined multiple times. The last one will take effect.
	{ mods = { "alt", "ctrl" }, key = "-", cmd = "yabai -m window --space prev" },
	{ mods = { "alt", "ctrl" }, key = "=", cmd = "yabai -m window --space next" },

	-- =================================================================================
	-- Scratchpads
	-- =================================================================================
	{
		mods = { "alt" },
		key = "escape",
		cmd = _toggle_current_scratchpad,
		description = "Yabai: Toggle current scratchpad",
	},
	{
		mods = { "alt", "shift" },
		key = "escape",
		cmd = "yabai -m window --scratchpad",
		description = "Yabai: Unset scratchpad on current window",
	},

	-- Named Scratchpads
	{
		mods = { "alt" },
		key = "d",
		cmd = _toggle_scratchpad_wrapper("terminal"),
		description = "Yabai: Toggle 'terminal' scratchpad",
	},
	{
		mods = { "alt", "shift" },
		key = "d",
		cmd = _set_scratchpad_wrapper("terminal"),
		description = "Yabai: Set 'terminal' scratchpad",
	},
	{
		mods = { "alt" },
		key = "a",
		cmd = _toggle_scratchpad_wrapper("ai"),
		description = "Yabai: Toggle 'copilot' scratchpad",
	},
	{
		mods = { "alt", "shift" },
		key = "a",
		cmd = _set_scratchpad_wrapper("ai"),
		description = "Yabai: Set 'copilot' scratchpad",
	},
	{
		mods = { "alt" },
		key = "n",
		cmd = _toggle_scratchpad_wrapper("notes"),
		description = "Yabai: Toggle 'notes' scratchpad",
	},
	{
		mods = { "alt", "shift" },
		key = "n",
		cmd = _set_scratchpad_wrapper("notes"),
		description = "Yabai: Set 'notes' scratchpad",
	},
	{
		mods = { "alt" },
		key = "t",
		cmd = _toggle_scratchpad_wrapper("todo"),
		description = "Yabai: Toggle 'todo' scratchpad",
	},
	{
		mods = { "alt", "shift" },
		key = "t",
		cmd = _set_scratchpad_wrapper("todo"),
		description = "Yabai: Set 'todo' scratchpad",
	},
	{
		mods = { "alt" },
		key = "b",
		cmd = _toggle_scratchpad_wrapper("browser"),
		description = "Yabai: Toggle 'browser' scratchpad",
	},
	{
		mods = { "alt", "shift" },
		key = "b",
		cmd = _set_scratchpad_wrapper("browser"),
		description = "Yabai: Set 'browser' scratchpad",
	},

	-- =================================================================================
	-- System / Debugging
	-- =================================================================================
	{
		mods = { "alt", "ctrl" },
		key = "r",
		cmd = "yabai --restart-service",
		description = "Yabai: Restart service",
	},
	{
		mods = { "alt", "shift" },
		key = "r",
		cmd = "brew services restart borders",
		description = "Yabai: Restart borders",
	},
	{
		mods = { "alt", "ctrl" },
		key = ";",
		cmd = "yabai -m config focus_follows_mouse off",
		description = "Yabai: Toggle mouse autofocus",
	},
	{
		mods = { "alt", "shift" },
		key = ";",
		cmd = "yabai -m config focus_follows_mouse on",
		description = "Yabai: Toggle mouse autofocus",
	},
	{
		mods = { "alt" },
		key = "/",
		cmd = "yabai -m query --windows --window > /tmp/yabai-cur-win.json | neovide /tmp/yabai-cur-win.json; exit",
		description = "Yabai: Dump window data to Neovide",
	},
}

--- Yabai:init()
--- Spoon constructor
--- Binds hotkeys for Yabai
function obj:init() end

--- Yabai:start()
--- Starts the Spoon
--- Binds all hotkeys defined in `obj.hotkeys`
function obj:start()
	self:stop() -- Stop any existing bindings to prevent duplicates
	for _, hotkeyDef in ipairs(self.hotkeys) do
		local mods = hotkeyDef.mods
		local key = hotkeyDef.key
		local cmd = hotkeyDef.cmd
		local description = hotkeyDef.description or "Yabai command"

		local hotkey = hs.hotkey.bind(mods, key, function()
			-- hs.execute runs commands in /bin/sh -c, which handles $HOME, &&, etc.
			local status = _cmd(cmd)
			if not status then
				hs.printf("Failed: %s", description)
			end
		end)
		if hotkey then
			table.insert(self.boundHotkeys, hotkey)
			-- else
			--     hs.logger.warn(string.format("Failed to bind hotkey: %s+%s", table.concat(mods, "+"), key))
		end
	end
end

--- Yabai:stop()
--- Stops the Spoon
--- Unbinds all the hotkeys that were created by this Spoon.
function obj:stop()
	for _, hotkey in ipairs(self.boundHotkeys) do
		hotkey:delete()
	end
	self.boundHotkeys = {}
end

return obj
