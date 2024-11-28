local game_config = {}
local nxml = dofile("mods/evaisa.mp/lib/nxml.lua")

local config_xml = os.getenv('APPDATA'):gsub("\\Roaming", "") .. "\\LocalLow\\Nolla_Games_Noita\\save_shared\\config.xml"

-- if file exists, read it
local config_file = io.open(config_xml, "r")

local config_settings = {}

if config_file then
    local config = config_file:read("*all")
    config_file:close()

    config_settings = nxml.parse(config)

    for key, value in pairs(config_settings.attr or {}) do
        config_settings[key] = value
    end
end

game_config.get = function(key)
    return config_settings[key]
end

return game_config