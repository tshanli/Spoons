local obj = {}
obj.__index = obj

-- User config
obj.picgo_path = "/Users/jiang2ji/.local/share/pnpm/picgo"

-- Alert styles for different types
local alertStyles = {
    info = { fillColor = { blue = 0.8, green = 0.8, red = 1, alpha = 0.85 }, strokeColor = { white = 1, alpha = 0.7 } },
    success = { fillColor = { green = 0.8, red = 0.2, blue = 0.2, alpha = 0.85 }, strokeColor = { white = 1, alpha = 0.7 } },
    warning = { fillColor = { red = 1, green = 0.8, blue = 0.2, alpha = 0.85 }, strokeColor = { white = 1, alpha = 0.7 } },
    error = { fillColor = { red = 1, green = 0.2, blue = 0.2, alpha = 0.85 }, strokeColor = { white = 1, alpha = 0.7 } },
}

-- Show alert at bottom, centered horizontally, 40px from bottom
local function showAlert(msg, type)
    local style = hs.fnutils.copy(hs.alert.defaultStyle)
    style["textSize"] = 16
    style["radius"] = 12
    style["atScreenEdge"] = 2
    if alertStyles[type] then
        for k, v in pairs(alertStyles[type]) do
            style[k] = v
        end
    end
    local screen = hs.screen.mainScreen()
    hs.alert.show(msg, style, screen, 2)
end

function obj:uploadAfterClipboardChange()
    local lastChangeCount = hs.pasteboard.changeCount()
    local watcher
    local timeoutTimer
    local escListener

    local function cleanup()
        if watcher then
            watcher:stop()
            watcher = nil
        end
        if timeoutTimer then
            timeoutTimer:stop()
            timeoutTimer = nil
        end
        if escListener then
            escListener:stop()
            escListener = nil
        end
    end

    watcher = hs.timer.doEvery(0.2, function()
        local newChangeCount = hs.pasteboard.changeCount()
        if newChangeCount ~= lastChangeCount then
            lastChangeCount = newChangeCount
            cleanup()
            local output, status, _, _ = hs.execute(self.picgo_path .. " upload", true)
            if output == "" or output == nil or status == nil then
                showAlert("Error: Failed to upload, maybe image not in clipboard", "error")
                return false
            end
            local url
            for line in output:gmatch("[^\r\n]+") do
                if line:match("^https?://") then
                    url = line
                end
            end
            if url then
                local md = string.format("![](%s)", url)
                showAlert("URL (markdown) copied", "success")
                hs.pasteboard.setContents(md)
            else
                showAlert("Error: No URL found in output!", "error")
                return false
            end
        end
        return true
    end)

    timeoutTimer = hs.timer.doAfter(5, function()
        cleanup()
        showAlert("Timeout: No changes in clipboard", "warning")
        return false
    end)

    escListener = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
        if event:getKeyCode() == hs.keycodes.map.escape then
            cleanup()
            showAlert("Screenshot canceled", "warning")
            return false
        end
        return false
    end)
    escListener:start()
end

function obj:bindHotkeys(mapping)
    hs.printf("mapping: " .. hs.inspect(mapping))

    -- mods
    local mods = { table.unpack(mapping, 1, #mapping - 1) }
    local key = mapping[#mapping]
    hs.printf("mods: " .. hs.inspect(mods))
    hs.printf("key: " .. hs.inspect(key))

    hs.hotkey.bind(mods, key, function()
        hs.eventtap.keyStroke({ "alt" }, "x")
        self:uploadAfterClipboardChange()
    end)
end

return obj
