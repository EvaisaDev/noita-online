local steamutils = dofile_once("mods/evaisa.mp/lib/steamutils.lua")
game_funcs = dofile("mods/evaisa.mp/files/scripts/game_functions.lua")
EZWand = dofile("mods/evaisa.arena/files/scripts/utilities/EZWand.lua")


local data_holder = dofile("mods/evaisa.arena/files/scripts/gamemode/data.lua")
local data = nil

last_player_entity = nil

local player = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/player.lua")
local entity = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/entity.lua")

message_handler = dofile("mods/evaisa.arena/files/scripts/gamemode/message_handler_stub.lua")
networking = dofile("mods/evaisa.arena/files/scripts/gamemode/networking.lua")
gameplay_handler = dofile("mods/evaisa.arena/files/scripts/gamemode/gameplay.lua")

local playerinfo_menu = dofile("mods/evaisa.arena/files/scripts/utilities/playerinfo_menu.lua")

dofile_once( "data/scripts/perks/perk_list.lua" )

perk_sprites = {}
for k, perk in pairs(perk_list)do
    perk_sprites[perk.id] = perk.ui_icon
end

playermenu = nil

playerRunQueue = {}

function RunWhenPlayerExists(func)
    table.insert(playerRunQueue, func)
end

lobby_member_names = {}

ArenaMode = {
    id = "arena",
    name = "Arena",
    version = 0.441,
    settings = {
        {
            id = "damage_cap",
            name = "Damage Cap",
            description = "One shot protection, how much damage can be dealt to a player at once.",
            type = "enum",
            options = {{"0.25", "25% of max"}, {"0.5", "50% of max"}, {"0.75", "75% of max"}, {"disabled", "Disabled"}},
            default = "0.25"
        },
        {
            id = "zone_shrink",
            name = "Zone Mode",
            description = "How the damage zone shrinks over time.",
            type = "enum",
            options = {{"disabled", "Disabled"}, {"static", "Static"}, {"shrinking_Linear", "Linear Shrinking"}, {"shrinking_step", "Stepped Shrinking"}},
            default = "static"
        },
        {
            id = "zone_speed",
            name = "Zone Speed",
            description = "How fast the damage zone shrinks over time. \nPixels per step or pixels per minute.",
            type = "slider",
            min = 1,
            max = 100,
            default = 30,
            display_multiplier = 1,
            formatting_string = " $0",
            width = 100
        },
        {
            id = "zone_step_interval",
            name = "Zone Interval",
            description = "Seconds between zone shrinks. \n(Only used in Stepped Shrinking mode)",
            type = "slider",
            min = 1,
            max = 90,
            default = 30,
            display_multiplier = 1,
            formatting_string = " $0s",
            width = 100
        },
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

        local zone_shrink = steam.matchmaking.getLobbyData(lobby, "setting_zone_shrink")
        if(zone_shrink == nil)then
            zone_shrink = "static"
        end
        GlobalsSetValue("zone_shrink", tostring(zone_shrink))

        local zone_speed = tonumber(steam.matchmaking.getLobbyData(lobby, "setting_zone_speed"))
        if(zone_speed == nil)then
            zone_speed = 30
        end
        GlobalsSetValue("zone_speed", tostring(zone_speed))

        local zone_step_interval = tonumber(steam.matchmaking.getLobbyData(lobby, "setting_zone_step_interval"))
        if(zone_step_interval == nil)then
            zone_step_interval = 30
        end
        GlobalsSetValue("zone_step_interval", tostring(zone_step_interval))

        print("Lobby data refreshed")
    end,
    enter = function(lobby)
        GlobalsSetValue("holyMountainCount", "0")
        GameAddFlagRun("player_unloaded")

        local player = player.Get()
        if(player ~= nil)then
            EntityKill(player)
        end

        --print("WE GOOD???")

        GlobalsSetValue( "TEMPLE_PERK_REROLL_COUNT", "0" )

        local game_in_progress = steam.matchmaking.getLobbyData(lobby, "in_progress") == "true"
        if(game_in_progress)then
            ArenaMode.start(lobby, true)
        end
        --message_handler.send.Handshake(lobby)
    end,
    start = function(lobby, was_in_progress)

        if(not was_in_progress)then
            steamutils.RemoveLocalLobbyData(lobby, "player_data")
            steamutils.RemoveLocalLobbyData(lobby, "reroll_count")
        end

        gameplay_handler.ResetEverything(lobby)

        local unique_game_id_server = steam.matchmaking.getLobbyData(lobby, "unique_game_id") or "0"
        local unique_game_id_client = steamutils.GetLocalLobbyData(lobby, "unique_game_id") or "1523523"

        if(unique_game_id_server ~= unique_game_id_client)then
            print("Unique game id mismatch, removing player data")
            steamutils.RemoveLocalLobbyData(lobby, "player_data")
            steamutils.RemoveLocalLobbyData(lobby, "reroll_count")
        end


        GameAddFlagRun("player_unloaded")

        local seed = tonumber(steam.matchmaking.getLobbyData(lobby, "seed") or 1)

        SetWorldSeed( seed )

        local player_entity = player.Get()

        ArenaMode.refresh(lobby)

        data = data_holder:New()
        data.state = "lobby"
        data:DefinePlayers(lobby)

        
        local local_seed = data.random.range(100, 10000000)

        GlobalsSetValue("local_seed", tostring(local_seed))

        local unique_seed = data.random.range(100, 10000000)
        GlobalsSetValue("unique_seed", tostring(unique_seed))

        if(steamutils.IsOwner(lobby))then
            local unique_game_id = data.random.range(100, 10000000)
            steam.matchmaking.setLobbyData(lobby, "unique_game_id", tostring(unique_game_id))
        end

        gameplay_handler.GetGameData(lobby, data)

        if(player_entity == nil)then
            gameplay_handler.LoadPlayer(lobby, data)
        end

        gameplay_handler.LoadLobby(lobby, data, true, true)

        if(playermenu ~= nil)then
            playermenu:Destroy() 
        end
                
        playermenu = playerinfo_menu:New()



        --message_handler.send.Handshake(lobby)
    end,
    update = function(lobby)



        if(GameGetFrameNum() % 60 == 0)then

            if(data ~= nil)then
                local unique_game_id = steam.matchmaking.getLobbyData(lobby, "unique_game_id") or "0"
                steamutils.SetLocalLobbyData(lobby, "unique_game_id", tostring(unique_game_id))
            end

            local members = steamutils.getLobbyMembers(lobby)
            for k, member in pairs(members)do
                if(member.id ~= steam.user.getSteamID())then
                    local name = steam.friends.getFriendPersonaName(member.id)
                    if(name ~= nil)then
                        lobby_member_names[tostring(member.id)] = name
                    end
                end
            end

            networking.send.handshake(lobby)

            -- fix daynight cycle
            local world_state = GameGetWorldStateEntity()
            local world_state_component = EntityGetFirstComponentIncludingDisabled(world_state, "WorldStateComponent")
            ComponentSetValue2(world_state_component, "time", 0.2)
            ComponentSetValue2(world_state_component, "time_dt", 0)
            ComponentSetValue2(world_state_component, "fog", 0)
            ComponentSetValue2(world_state_component, "intro_weather", true)

            local unique_seed = data.random.range(100, 10000000)
            GlobalsSetValue("unique_seed", tostring(unique_seed))

        end
        
        local update_seed = steam.matchmaking.getLobbyData(lobby, "update_seed")
        if(update_seed == nil)then
            update_seed = "0"
        end

        GlobalsSetValue("update_seed", update_seed)

        if(data ~= nil)then

            gameplay_handler.Update(lobby, data)
            if(not IsPaused())then
                if(playermenu ~= nil)then
                    playermenu:Update(data, lobby)
                end
            end
        end

        
        local player_ent = player.Get()

        if(player_ent ~= nil)then
            local controlsComp = EntityGetFirstComponentIncludingDisabled(player_ent, "ControlsComponent")
            if(controlsComp ~= nil)then
                local kick = ComponentGetValue2(controlsComp, "mButtonDownKick")
                local kick_frame = ComponentGetValue2(controlsComp, "mButtonFrameKick")
                if(kick and kick_frame == GameGetFrameNum())then

                    -- REMOVE THIS

                    local world_state = GameGetWorldStateEntity()

                    EntityKill(world_state)

                    --[[

                    local component = EntityGetFirstComponent( player_ent, "Inventory2Component" );
                    if component ~= nil then
                        local mActiveItem =  ComponentGetValue2( component, "mActiveItem" );

                        local wand = EZWand(mActiveItem)
                        EntityKill(wand.entity_id)
                        local new_wand = EZWand("data/entities/items/wand_unshuffle_06.xml")
                        new_wand.capacity = 5
                        new_wand:RemoveSpells()
                        new_wand:AddSpells("LIGHT_BULLET")
                        local serialized = new_wand:Serialize()
                        EntityKill(new_wand.entity_id)
                        local n = EZWand(serialized)
                        n:PutInPlayersInventory()

                    end
                    ]]
                end
            end
        end



        --print("Did something go wrong?")
    end,
    late_update = function(lobby)
        if(data ~= nil)then
            gameplay_handler.LateUpdate(lobby, data)
        end
    end,
    leave = function(lobby)
        GameAddFlagRun("player_unloaded")
        gameplay_handler.ResetEverything(lobby)
    end,
    --[[
    message = function(lobby, message, user)
        message_handler.handle(lobby, message, user, data)
    end,
    ]]
    received = function(lobby, event, message, user)

        if(not data.players[tostring(user)])then
            data:DefinePlayer(lobby, user)
        end

        if(data ~= nil)then
            if(networking.receive[event])then
                networking.receive[event](lobby, message, user, data)
            end
        end
    end,
    on_projectile_fired = function(lobby, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message)
        if(EntityHasTag(shooter_id, "client"))then
            EntityAddTag(shooter_id, "player_unit")
        end

        if(data ~= nil)then
            gameplay_handler.OnProjectileFired(lobby, data, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message)
        end
    end,
    on_projectile_fired_post = function(lobby, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message)
        if(EntityHasTag(shooter_id, "client"))then
            EntityRemoveTag(shooter_id, "player_unit")
        end

        if(data ~= nil)then
            gameplay_handler.OnProjectileFiredPost(lobby, data, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message)
        end
    end
}

table.insert(gamemodes, ArenaMode)