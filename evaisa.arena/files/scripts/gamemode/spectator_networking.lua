-- why is this all here

local steamutils = dofile_once("mods/evaisa.mp/lib/steamutils.lua")
local player = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/player.lua")
local playerinfo = dofile("mods/evaisa.arena/files/scripts/gamemode/playerinfo.lua")
local healthbar = dofile("mods/evaisa.arena/files/scripts/utilities/health_bar.lua")
local tween = dofile("mods/evaisa.arena/lib/tween.lua")
local Vector = dofile("mods/evaisa.arena/lib/vector.lua")
local json = dofile("mods/evaisa.arena/lib/json.lua")
local EntityHelper = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/entity.lua")
local smallfolk = dofile("mods/evaisa.arena/lib/smallfolk.lua")
dofile_once( "data/scripts/perks/perk_list.lua" )
dofile_once("mods/evaisa.arena/content/data.lua")
local player_helper = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/player.lua")

-- whatever ill just leave it

spectator_networking = {
    receive = {
        ready = function(lobby, message, user, data)
        end,
        arena_loaded = function(lobby, message, user, data)
        end,
        enter_arena = function(lobby, message, user, data)
        end,
        start_countdown = function(lobby, message, user, data)
        end,
        unlock = function(lobby, message, user, data)
        end,
        character_position = function(lobby, message, user, data)
        end,
        handshake = function(lobby, message, user, data)
            steamutils.sendToPlayer("handshake_confirmed", {message[1], message[2]}, user, true)
        end,
        handshake_confirmed = function(lobby, message, user, data)
        end,
        wand_update = function(lobby, message, user, data)
        end,
        request_wand_update = function(lobby, message, user, data)
        end,
        input_update = function(lobby, message, user, data)
        end,
        animation_update = function(lobby, message, user, data)
        end,
        switch_item = function(lobby, message, user, data)
        end,
        sync_wand_stats = function(lobby, message, user, data)
        end,
        health_update = function(lobby, message, user, data)
        end,
        perk_update = function(lobby, message, user, data)
        end,
        fire_wand = function(lobby, message, user, data)
        end,
        death = function(lobby, message, user, data)
        end,
        zone_update = function(lobby, message, user, data)
        end,
        request_perk_update = function(lobby, message, user, data)
        end,
    },
    send = {
    },
}

return networking