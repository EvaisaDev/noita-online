local steamutils = dofile_once("mods/evaisa.mp/lib/steamutils.lua")
game_funcs = dofile("mods/evaisa.mp/files/scripts/game_functions.lua")

local data_holder = dofile("mods/evaisa.arena/files/scripts/gamemode/data.lua")
local data = nil

local player = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/player.lua")
local entity = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/entity.lua")

message_handler = dofile("mods/evaisa.arena/files/scripts/gamemode/message_handler.lua")
gameplay_handler = dofile("mods/evaisa.arena/files/scripts/gamemode/gameplay.lua")

local playerinfo_menu = dofile("mods/evaisa.arena/files/scripts/utilities/playerinfo_menu.lua")

dofile_once( "data/scripts/perks/perk_list.lua" )

perk_sprites = {}
for k, perk in pairs(perk_list)do
    perk_sprites[perk.id] = perk.ui_icon
end

playermenu = nil

ArenaMode = {
    id = "arena",
    name = "Arena",
    version = 0.3,
    settings = {
        {
            id = "damage_cap",
            name = "Damage Cap",
            type = "enum",
            options = {{"0.25", "25% of max"}, {"0.5", "50% of max"}, {"0.75", "75% of max"}, {"disabled", "Disabled"}},
            default = "0.25"
        }
    },
    default_data = {
        total_gold = "0",
        holyMountainCount = "0",
        ready_players = "null",
    },
    refresh = function(lobby)
        local damage_cap = tonumber(steam.matchmaking.getLobbyData(lobby, "setting_damage_cap"))
        if(damage_cap == nil)then
            damage_cap = 0.25
        end
        GlobalsSetValue("damage_cap", tostring(damage_cap))

        print("Lobby data refreshed")
    end,
    enter = function(lobby)
        GlobalsSetValue("holyMountainCount", "0")
        GameAddFlagRun("player_unloaded")

        local player = player.Get()
        if(player ~= nil)then
            EntityKill(player)
        end

        print("WE GOOD???")

        local game_in_progress = steam.matchmaking.getLobbyData(lobby, "in_progress") == "true"
        if(game_in_progress)then
            ArenaMode.start(lobby)
        end
        steamutils.sendData({type = "handshake"}, steamutils.messageTypes.OtherPlayers, lobby)
    end,
    start = function(lobby)

        local player_entity = player.Get()

        local damage_cap = tonumber(steam.matchmaking.getLobbyData(lobby, "setting_damage_cap"))
        if(damage_cap == nil)then
            damage_cap = 0.25
        end
        GlobalsSetValue("damage_cap", tostring(damage_cap))

        data = data_holder:New()
        data.state = "lobby"
        data:DefinePlayers(lobby)


        gameplay_handler.GetGameData(lobby, data)

        if(player_entity == nil)then
            gameplay_handler.LoadPlayer(lobby, data)
        end


        steamutils.sendData({type = "handshake"}, steamutils.messageTypes.OtherPlayers, lobby)

        gameplay_handler.LoadLobby(lobby, data, true, true)

        if(playermenu ~= nil)then
            playermenu:Destroy() 
        end
                
        playermenu = playerinfo_menu:New()

        message_handler.send.Handshake(lobby)
    end,
    update = function(lobby)
        --print(debug.traceback())
        gameplay_handler.Update(lobby, data)
        if(not IsPaused())then
            playermenu:Update(data, lobby)
        end
        --print("Did something go wrong?")
    end,
    late_update = function(lobby)
        gameplay_handler.LateUpdate(lobby, data)
    end,
    leave = function(lobby)
        local player = player.Get()
        if(player ~= nil)then
            EntityKill(player)
        end
    end,
    message = function(lobby, message, user)
        message_handler.handle(lobby, message, user, data)
    end,
    on_projectile_fired = function(lobby, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message)
        if(EntityHasTag(shooter_id, "client"))then
            EntityAddTag(shooter_id, "player_unit")
        end

        gameplay_handler.OnProjectileFired(lobby, data, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message)
    end,
    on_projectile_fired_post = function(lobby, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message)
        if(EntityHasTag(shooter_id, "client"))then
            EntityRemoveTag(shooter_id, "player_unit")
        end

        gameplay_handler.OnProjectileFiredPost(lobby, data, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message)
    end
}

table.insert(gamemodes, ArenaMode)