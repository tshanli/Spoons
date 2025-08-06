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

---Run batched command
---@param cmd string|table
---@return boolean
local function _cmd(cmd)
	local type = type(cmd)

	if type == "table" then
		for _, v in ipairs(cmd) do
			_cmd(v)
		end
	elseif type == "string" then
		local _, ok = hs.execute(cmd, true)
		if not ok then
			return false
		end
	elseif type == "function" then
		return cmd() and true or false
	else
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

---Focus space
---@param sp string|integer
---|"next"
---|"prev"
---|"recent"
---@return boolean
local function _focus_space(sp)
	local cmd = "yabai -m space --focus " .. sp
	local _, ok = hs.execute(cmd, true)
	return ok ~= nil
end

---Focus window
---@param direction string
---|"north"
---|"east"
---|"south"
---|"west"
---|"recent"
---@return boolean
local function _focus_window(direction)
	if CURRENT_LAYOUT == "stack" then
		if direction == "north" then
			direction = "stack.prev"
		elseif direction == "south" then
			direction = "stack.next"
		end
	end
	local cmd = "yabai -m window --focus " .. direction
	local _, ok = hs.execute(cmd, true)
	return ok ~= nil
end

---Swap window
---@param direction string
---|"north"
---|"east"
---|"south"
---|"west"
---|"recent"
---@return boolean
local function _swap_window(direction)
	if CURRENT_LAYOUT == "stack" then
		if direction == "north" then
			direction = "stack.prev"
		elseif direction == "south" then
			direction = "stack.next"
		end
	end
	local cmd = "yabai -m window --swap " .. direction
	local _, ok = hs.execute(cmd, true)
	return ok ~= nil
end

---Warp window
---@param direction string
---|"north"
---|"east"
---|"south"
---|"west"
---|"recent"
---@return boolean
local function _warp_window(direction)
	if CURRENT_LAYOUT == "stack" then
		if direction == "north" then
			direction = "stack.prev"
		elseif direction == "south" then
			direction = "stack.next"
		end
	end
	local cmd = "yabai -m window --warp " .. direction
	local _, ok = hs.execute(cmd, true)
	return ok ~= nil
end

---Center current window
---@return boolean
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

---Toggle scratchpad for current window if set, otherwise toggles the most recently used scratchpad.
---@return boolean
local function _toggle_recent_scratchpad_or_hide()
	local name = _query("yabai -m query --windows --window", "scratchpad")
	local is_pad = (type(name) == "string" and name ~= "") and true or false

	if is_pad then
		---@diagnostic disable-next-line
		return _toggle_scratchpad(name)
	end

	if not CURRENT_SCRATCHPAD then
		return false
	end
	return _toggle_scratchpad(CURRENT_SCRATCHPAD)
end

local obj = {}
obj.__index = obj
obj.name = "Yabai"
obj.version = "1.0"
obj.author = "Tshan Li"
obj.homepage = "https://www.hammerspoon.org"
obj.description = "Yabai wrapper"

function obj:minimizeWindow()
	hs.execute("yabai -m window --minimize", true)
end

function obj:toggleWindowFullscreen()
	hs.execute("yabai -m window --toggle zoom-fullscreen", true)
end

function obj:toggleWindowZoomParent()
	hs.execute("yabai -m window --toggle zoom-parent", true)
end

function obj:toggleWindowFloat()
	hs.execute("yabai -m window --toggle float", true)
end

function obj:closeWindow()
	hs.execute("yabai -m window --close", true)
end

function obj:focusWindow(direction)
	_focus_window(direction)
end

function obj:swapWindow(direction)
	_swap_window(direction)
end

function obj:warpWindow(direction)
	_warp_window(direction)
end

function obj:shrinkWindowWidth()
	_cmd({ "yabai -m window --resize left:-50:0", "yabai -m window --resize right:-50:0" })
end

function obj:expandWindowWidth()
	_cmd({ "yabai -m window --resize left:50:0", "yabai -m window --resize right:50:0" })
end

function obj:expandWindowHeight()
	_cmd({ "yabai -m window --resize top:0:50", "yabai -m window --resize bottom:0:50" })
end

function obj:shrinkWindowHeight()
	_cmd({ "yabai -m window --resize top:0:-50 ", "yabai -m window --resize bottom:0:-50" })
end

function obj:centerResizeWindow()
	_resize_and_center_window()
end

function obj:centerWindow()
	_center_window()
end

function obj:toggleWindowSticky()
	hs.execute("yabai -m window --toggle sticky", true)
end

function obj:toggleWindowTopmost()
	hs.execute("yabai -m window --toggle topmost", true)
end

function obj:toggleWindowPIP()
	hs.execute("yabai -m window --toggle pip", true)
end

function obj:equalizeSpace()
	hs.execute("yabai -m space --equalize", true)
end

function obj:setLayoutStack()
	_toggle_stack()
end

function obj:setLayoutBsp()
	_toggle_bsp()
end

function obj:focusSpace(sp)
	_focus_space(sp)
end

function obj:moveWindowToSpaceAndFocus(sp)
	_cmd({ "yabai -m window --space " .. sp, "yabai -m space --focus " .. sp })
end

function obj:moveWindowToSpace(sp)
	hs.execute("yabai -m window --space %d" .. sp, true)
end

function obj:toggleRecentScratchpadOrHide()
	_toggle_recent_scratchpad_or_hide()
end

function obj:unsetScratchpad()
	hs.execute("yabai -m window --scratchpad", true)
end

function obj:toggleScratchpad(name)
	_toggle_scratchpad(name)
end

function obj:setScratchpad(name)
	_set_scratchpad(name)
end

function obj:restartYabai()
	hs.execute("yabai --restart-service", true)
end

function obj:restartBorders()
	hs.execute("brew services restart borders", true)
end

function obj:toggleMouseAutofocusOff()
	hs.execute("yabai -m config focus_follows_mouse off", true)
end

function obj:toggleMouseAutofocusOn()
	hs.execute("yabai -m config focus_follows_mouse on", true)
end

function obj:dumpWindowData(editor)
	hs.execute(
		string.format(
			"yabai -m query --windows --window > /tmp/yabai-cur-win.json | %s /tmp/yabai-cur-win.json; exit",
			editor
		),
		true
	)
end

--- Yabai:init()
--- Spoon constructor
function obj:init() end

--- Yabai:start()
--- Starts the Spoon
function obj:start()
	-- Init global vars
	CURRENT_LAYOUT = _query("yabai -m query --spaces --space", "type") or "bsp"
end

--- Yabai:stop()
function obj:stop() end

return obj
