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

-- whatever ill just leave it

networking = {
    receive = {
        ready = function(lobby, message, user, data)
            local username = steam.friends.getFriendPersonaName(user)

            if(message[1])then
                data.players[tostring(user)].ready = true

                if(not message[2])then
                    GamePrint(tostring(username) .. " is ready.")
                end

                if(steamutils.IsOwner(lobby))then
                    print(tostring(user).."_ready: "..tostring(message[1]))
                    steam.matchmaking.setLobbyData(lobby, tostring(user).."_ready", "true")
                end
            else
                data.players[tostring(user)].ready = false

                if(not message[2])then
                    GamePrint(tostring(username) .. " is no longer ready.")
                end
    
                if(steamutils.IsOwner(lobby))then
                    steam.matchmaking.setLobbyData(lobby, tostring(user).."_ready", "false")
                end
            end
        end,
        arena_loaded = function(lobby, message, user, data)

            local username = steam.friends.getFriendPersonaName(user)

            data.players[tostring(user)].loaded = true

            GamePrint(username .. " has loaded the arena.")

            if(steamutils.IsOwner(lobby))then
                steam.matchmaking.setLobbyData(lobby, tostring(user).."_loaded", "true")
            end
        end,
        enter_arena = function(lobby, message, user, data)
            gameplay_handler.LoadArena(lobby, data, true)
        end,
        start_countdown = function(lobby, message, user, data)
            GamePrint("Starting countdown...")
            data.players_loaded = true
            gameplay_handler.FightCountdown(lobby, data)
        end,
        unlock = function(lobby, message, user, data)
            player.Immortal(false)
            gameplay_handler.AllowFiring(data)
            message_handler.send.RequestWandUpdate(lobby, data)
            data.countdown:cleanup()
            data.countdown = nil
        end,
    },
    send = {
        ready = function(lobby, is_ready, silent)
            silent = silent or false
            steamutils.send("ready", {is_ready, silent},  steamutils.messageTypes.OtherPlayers, lobby, true)
        end,
        arena_loaded = function(lobby)
            steamutils.send("arena_loaded", {},  steamutils.messageTypes.OtherPlayers, lobby, true)
        end,
        enter_arena = function(lobby)
            steamutils.send("enter_arena", {},  steamutils.messageTypes.OtherPlayers, lobby, true)
        end,
        start_countdown = function(lobby)
            steamutils.send("start_countdown", {},  steamutils.messageTypes.OtherPlayers, lobby, true)
        end,
        unlock = function(lobby)
            steamutils.send("unlock", {},  steamutils.messageTypes.OtherPlayers, lobby, true)
        end,
    },
}

return networking