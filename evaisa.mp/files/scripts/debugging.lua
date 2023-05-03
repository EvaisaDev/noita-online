mp_log:print("debugging.lua loaded.")

--[[
local OldModSettingSet = ModSettingSet
ModSettingSet = function(a, b)
    local source = debug.getinfo(2).short_src
    local line = debug.getinfo(2).currentline

    if(a == nil or b == nil)then
        mp_log:print("ModSettingSet: " .. source .. ":" .. line)
    end
    -- pcall old function
    if(pcall(OldModSettingSet, a, b) == false)then
        mp_log:print("ModSettingSet: " .. source .. ":" .. line .. " failed")
    end
end

local oldGameKillInventoryItem = GameKillInventoryItem

GameKillInventoryItem = function(a, b)
    local source = debug.getinfo(2).short_src
    local line = debug.getinfo(2).currentline

    if(a == nil or not EntityGetIsAlive(a) or b == nil or not EntityGetIsAlive(b))then
        mp_log:print("GameKillInventoryItem: " .. source .. ":" .. line)
    end

    -- pcall old function
    if(pcall(oldGameKillInventoryItem, a, b) == false)then
        mp_log:print("GameKillInventoryItem: " .. source .. ":" .. line .. " failed")
    end
end

local oldGuiImage = GuiImage

GuiImage = function(...)
    local source = debug.getinfo(2).short_src
    local line = debug.getinfo(2).currentline

    mp_log:print("GuiImage: " .. source .. ":" .. line)

    -- pcall old function
    if(pcall(oldGuiImage, ...) == false)then
        mp_log:print("GuiImage: " .. source .. ":" .. line .. " failed")
    end
end]]