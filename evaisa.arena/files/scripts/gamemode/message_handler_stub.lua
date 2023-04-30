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



ArenaMessageHandler = {
    receive = {
        ready = function(lobby, message, user, data, username)
        end,
        unready = function(lobby, message, user, data, username)
        end,
        arena_loaded = function(lobby, message, user, data, username)
        end,
        enter_arena = function(lobby, message, user, data)
        end,
        health_info = function(lobby, message, user, data)
        end,
        update_hp = function(lobby, message, user, data)
        end,
        start_countdown = function(lobby, message, user, data)
        end,
        unlock = function(lobby, message, user, data)
        end,
        death = function(lobby, message, user, data, username)
        end,
        wand_fired = function(lobby, message, user, data)
        end,
        character_update = function(lobby, message, user, data)
        end,
        wand_update = function(lobby, message, user, data)
        end,
        switch_item = function(lobby, message, user, data)
        end,
        animation_update = function(lobby, message, user, data)
        end,
        perk_info = function(lobby, message, user, data)
        end,
        sync_controls = function(lobby, message, user, data)
        end,
        sync_wand_stats = function(lobby, message, user, data)
        end,
        handshake = function(lobby, message, user, data)
        end,
        handshake_confirmed = function(lobby, message, user, data)
        end,
        request_wand_update = function(lobby, message, user, data)
        end,
        zone_update = function(lobby, message, user, data)
        end,
    },
    send = {
        ZoneUpdate = function(lobby, zone_size, shrink_time)
        end,
        Handshake = function(lobby)
        end,
        Ready = function(lobby)
        end,
        Unready = function(lobby, no_message)
        end,
        RequestWandUpdate = function(lobby)
        end,
        EnterArena = function(lobby)
        end,
        Loaded = function(lobby)
        end,
        StartCountdown = function(lobby)
        end,
        Health = function(lobby)
        end,
        Unlock = function(lobby)
        end,
        Death = function(lobby, killer)
        end,
        WandFired = function(lobby, rng, special_seed, cast_state)
        end,
        CharacterUpdate = function(lobby, data)
        end,
        WandUpdate = function(lobby, data, user)
        end,
        SwitchItem = function(lobby, data)
        end,
        AnimationUpdate = function(lobby, data)
        end,
        SyncControls = function(lobby, data)
        end,
        SendPerks = function(lobby)
        end,
        UpdateHp = function(lobby, data)
        end,
        SyncWandStats = function(lobby, data)
        end,
    },
    handle = function(lobby, message, user, data)

    end,
    update = function(lobby, data)

    end
}

return ArenaMessageHandler