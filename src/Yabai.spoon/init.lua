--[[
Spoon: Yabai
Author: Tshan Li (Original Karabiner config), AI Conversion
Version: 1.0
License: MIT
Description: Provides yabai window manager keybindings, converted from a Karabiner-Elements JSON file.
--]]

CURRENT_SCRATCHPAD = nil
CURRENT_LAYOUT = "bsp"
DEBUG_MODE = false

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
		local _, status = hs.execute(cmd, true)
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
---@diagnostic disable-next-line:unused-function
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
---@diagnostic disable-next-line:unused-function, unused-local
local function _query_current_space()
	return _query("yabai -m query --spaces --space")
end

---Focus window
---@param win string
---@return boolean
local function _focus_window(win)
	local cmd = "yabai -m window --focus " .. win
	local _, ok = hs.execute(cmd, true)
	return ok and true or false
end

---Focus window. When in bsp, it goes north/south; when in stack, it goes next/prev
---@param order string
---| "'prev'"
---| "'next'"
---@return boolean
local function _focus_window_order(order)
	order = CURRENT_LAYOUT == "bsp" and order or "stack." .. order
	local ok = _focus_window(order)
	if not ok then
		order = order == "prev" and "last" or "first"
		order = CURRENT_LAYOUT == "bsp" and order or "stack." .. order
		ok = _focus_window(order)
	end

	if not ok then
		local err_msg = "Error: focus window: " .. order
		hs.printf(err_msg)
		return false
	end
	return true
end

local function _focus_window_prev()
	return _focus_window_order("prev")
end

local function _focus_window_next()
	return _focus_window_order("next")
end

---Focus window with direction
---@param direction string
---|"north"
---|"east"
---|"south"
---|"west"
---@return boolean
local function _focus_window_direction(direction)
	local ok = true
	if CURRENT_LAYOUT == "bsp" then
		ok = _focus_window(direction)
	end
	return ok
end

---Wrapper for focus window with direction
---@param direction string
---|"north"
---|"east"
---|"south"
---|"west"
---@return function
local function _focus_window_direction_wrapper(direction)
	return function()
		-- local ok = _focus_window_direction(direction)
		-- if not ok then
		-- 	hs.printf("Error: focus window with direction: %s", direction)
		-- end
		-- return ok
		return _focus_window_direction(direction)
	end
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

---Toggle layout for current space
---@param layout string
---| "'bsp'"
---| "'stack'"
---@return boolean
local function _toggle_layout(layout)
	local _, ok = hs.execute("yabai -m space --layout " .. layout, true)

	if not ok then
		return false
	end
	CURRENT_LAYOUT = layout
	return true
end

---Toggle layout bsp for current space
---@return boolean
local function _toggle_bsp()
	local ok = _toggle_layout("bsp")
	if not ok then
		hs.printf("Error: toggle layout bsp")
	end
	return true
end

---Toggle layout stack for current space
---@return boolean
local function _toggle_stack()
	local ok = _toggle_layout("stack")
	if not ok then
		hs.printf("Error: toggle layout stack")
	end
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
obj.__index = obj
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
	{ mods = { "alt", "ctrl" }, key = "m", cmd = "yabai -m window --minimize", description = "Yabai: Minimize window" },
	{
		mods = { "alt" },
		key = "s",
		cmd = "yabai -m window --toggle zoom-fullscreen",
		description = "Yabai: Toggle zoom-fullscreen",
	},
	{
		mods = { "alt", "ctrl" },
		key = "z",
		cmd = "yabai -m window --toggle zoom-parent",
		description = "Yabai: Toggle zoom-parent",
	},
	{
		mods = { "alt", "shift" },
		key = "f",
		cmd = "yabai -m window --toggle float",
		description = "Yabai: Toggle float",
	},
	{
		mods = { "alt" },
		key = "q",
		cmd = "yabai -m window --close",
		description = "Yabai: Close window",
	},

	-- =================================================================================
	-- Window Focus (VIM-like)
	-- =================================================================================
	-- { mods = { "alt" }, key = "h", cmd = "yabai -m window --focus west", description = "Yabai: Focus west" },
	-- { mods = { "alt" }, key = "l", cmd = "yabai -m window --focus east", description = "Yabai: Focus east" },
	-- This command intelligently handles focus for both BSP and Stack layouts.
	{
		mods = { "alt" },
		key = "h",
		cmd = _focus_window_direction_wrapper("west"),
		description = "Yabai: Focus west window",
	},
	{
		mods = { "alt" },
		key = "l",
		cmd = _focus_window_direction_wrapper("east"),
		description = "Yabai: Focus east window",
	},
	{
		mods = { "alt" },
		key = "j",
		cmd = _focus_window_direction_wrapper("south"),
		description = "Yabai: Focus south window",
	},
	{
		mods = { "alt" },
		key = "k",
		cmd = _focus_window_direction_wrapper("north"),
		description = "Yabai: Focus north window",
	},
	{
		mods = { "alt" },
		key = "w",
		cmd = "yabai -m window --focus recent",
		description = "Yabai: Focus recent window",
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
	{
		mods = { "alt", "shift" },
		key = "w",
		cmd = "yabai -m window --swap recent",
		description = "Yabai: Swap recent window",
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
	{
		mods = { "alt", "ctrl", "shift" },
		key = "w",
		cmd = "yabai -m window --warp recent",
		description = "Yabai: Swap recent window",
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
		mods = { "alt", "ctrl" },
		key = "c",
		cmd = _center_window,
		description = "Yabai: Center window",
	},

	-- =================================================================================
	-- Window Properties (Sticky, Topmost, PiP)
	-- =================================================================================
	{
		mods = { "alt", "ctrl" },
		key = "p",
		cmd = "yabai -m window --toggle sticky",
		description = "Yabai: Toggle sticky",
	},
	{
		mods = { "alt", "shift" },
		key = "p",
		cmd = "yabai -m window --toggle topmost",
		description = "Yabai: Toggle topmost",
	},
	{
		mods = { "alt", "ctrl", "shift" },
		key = "p",
		cmd = "yabai -m window --toggle pip",
		description = "Yabai: Toggle picture-in-picture",
	},

	-- =================================================================================
	-- Space Layout Management
	-- =================================================================================
	{ mods = { "alt" }, key = "/", cmd = "yabai -m space --equalize", description = "Yabai: Equalize space" },
	{
		mods = { "alt", "shift" },
		key = "/",
		cmd = _toggle_stack,
		description = "Yabai: Set layout to stack",
	},
	{
		mods = { "alt", "ctrl" },
		key = "/",
		cmd = _toggle_bsp,
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
	{
		mods = { "alt" },
		key = "=",
		cmd = "yabai -m space --focus next",
		description = "Yabai: Focus next space",
	},

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
		key = "e",
		cmd = _toggle_scratchpad_wrapper("terminal"),
		description = "Yabai: Toggle 't[e]rminal' scratchpad",
	},
	{
		mods = { "alt", "shift" },
		key = "e",
		cmd = _set_scratchpad_wrapper("terminal"),
		description = "Yabai: Set 't[e]rminal' scratchpad",
	},
	{
		mods = { "alt" },
		key = "a",
		cmd = _toggle_scratchpad_wrapper("ai"),
		description = "Yabai: Toggle 'ai' scratchpad",
	},
	{
		mods = { "alt", "shift" },
		key = "a",
		cmd = _set_scratchpad_wrapper("ai"),
		description = "Yabai: Set 'ai' scratchpad",
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
		key = "d",
		cmd = _toggle_scratchpad_wrapper("todo-list"),
		description = "Yabai: Toggle 'to[d]o-l[i]st' scratchpad",
	},
	{
		mods = { "alt", "shift" },
		key = "d",
		cmd = _set_scratchpad_wrapper("todo-list"),
		description = "Yabai: Set 'to[d]o-list' scratchpad",
	},
	{
		mods = { "alt" },
		key = "b",
		cmd = _toggle_scratchpad_wrapper("browser"),
		description = "Yabai: Toggle 'br[o]wser' scratchpad",
	},
	{
		mods = { "alt", "shift" },
		key = "b",
		cmd = _set_scratchpad_wrapper("browser"),
		description = "Yabai: Set 'br[o]wser' scratchpad",
	},
	{
		mods = { "alt" },
		key = "m",
		cmd = _toggle_scratchpad_wrapper("mail"),
		description = "Yabai: Toggle 'mail' scratchpad",
	},
	{
		mods = { "alt", "shift" },
		key = "m",
		cmd = _set_scratchpad_wrapper("mail"),
		description = "Yabai: Set 'mail' scratchpad",
	},
	{
		mods = { "alt" },
		key = "i",
		cmd = _toggle_scratchpad_wrapper("instant-messaging"),
		description = "Yabai: Toggle 'instant-messaging' scratchpad",
	},
	{
		mods = { "alt", "shift" },
		key = "i",
		cmd = _set_scratchpad_wrapper("instant-messaging"),
		description = "Yabai: Set 'instant-messaging' scratchpad",
	},

	-- =================================================================================
	-- System / Debugging
	-- =================================================================================
	{
		mods = { "alt", "ctrl" },
		key = "'",
		cmd = "yabai --restart-service",
		description = "Yabai: Restart service",
	},
	{
		mods = { "alt", "shift" },
		key = "'",
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
		key = ";",
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

	-- Init global vars
	CURRENT_LAYOUT = _query("yabai -m query --spaces --space", "type") or "bsp"

	for _, hotkeyDef in ipairs(self.hotkeys) do
		local mods = hotkeyDef.mods
		local key = hotkeyDef.key
		local cmd = hotkeyDef.cmd
		local description = hotkeyDef.description or "Yabai command"

		local hotkey = hs.hotkey.bind(mods, key, function()
			-- hs.execute runs commands in /bin/sh -c, which handles $HOME, &&, etc.
			local status = _cmd(cmd)
			if not status and DEBUG_MODE then
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
