local steamutils = dofile_once("mods/evaisa.mp/lib/steamutils.lua")
local player = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/player.lua")
local entity = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/entity.lua")
local counter = dofile_once("mods/evaisa.arena/files/scripts/utilities/ready_counter.lua")
local countdown = dofile_once("mods/evaisa.arena/files/scripts/utilities/countdown.lua")
local json = dofile("mods/evaisa.arena/lib/json.lua")
dofile_once("mods/evaisa.arena/content/data.lua")

local playerRunQueue = {}

function RunWhenPlayerExists(func)
    table.insert(playerRunQueue, func)
end

ArenaGameplay = {
    GetNumRounds = function()
        local holyMountainCount = tonumber(GlobalsGetValue("holyMountainCount", "0")) or 0
        return holyMountainCount
    end,
    AddRound = function()
        local holyMountainCount = tonumber(GlobalsGetValue("holyMountainCount", "0")) or 0
        holyMountainCount = holyMountainCount + 1
        GlobalsSetValue("holyMountainCount", tostring(holyMountainCount))
    end,
    RemoveRound = function()
        local holyMountainCount = tonumber(GlobalsGetValue("holyMountainCount", "0")) or 0
        holyMountainCount = holyMountainCount - 1
        GlobalsSetValue("holyMountainCount", tostring(holyMountainCount))
    end,
    SendGameData = function(lobby, data)
        steam.matchmaking.setLobbyData(lobby, "holyMountainCount", tostring(ArenaGameplay.GetNumRounds()))
        local ready_players = {}
        local members = steamutils.getLobbyMembers(lobby)
        for k, member in pairs(members)do
            if(member.id ~= steam.user.getSteamID())then
                if(data.players[tostring(member.id)] ~= nil and data.players[tostring(member.id)].ready)then
                    table.insert(ready_players, tostring(member.id))
                end
            end
        end
        steam.matchmaking.setLobbyData(lobby, "ready_players", bitser.dumps(ready_players))
    end,
    GetGameData = function(lobby, data)
        local mountainCount = tonumber(steam.matchmaking.getLobbyData(lobby, "holyMountainCount"))
        if(mountainCount ~= nil)then
            GlobalsSetValue("holyMountainCount", tostring(mountainCount))
            print("Holymountain count: "..mountainCount)
        end
        local goldCount = tonumber(steam.matchmaking.getLobbyData(lobby, "total_gold"))
        if(goldCount ~= nil)then
            data.client.first_spawn_gold = goldCount
            print("Gold count: "..goldCount)
        end
        local playerData = steamutils.GetLocalLobbyData(lobby, "player_data")--steam.matchmaking.getLobbyMemberData(lobby, steam.user.getSteamID(), "player_data")
        local rerollCount = tonumber(steamutils.GetLocalLobbyData(lobby, "reroll_count") or 0)
        
        data.client.reroll_count = rerollCount

        GlobalsSetValue( "TEMPLE_PERK_REROLL_COUNT", tostring(rerollCount) )

        if(playerData ~= nil and playerData ~= "")then
            data.client.player_loaded_from_data = true
            data.client.serialized_player = bitser.dumps(playerData)
            print("Player data: "..data.client.serialized_player)
        end
        local ready_players_string = steam.matchmaking.getLobbyData(lobby, "ready_players")
        local ready_players = (ready_players_string ~= nil and ready_players_string ~= "null") and bitser.loads(ready_players_string) or nil
        local members = steamutils.getLobbyMembers(lobby)

        print(tostring(ready_players_string))
        if(ready_players ~= nil)then
            for k, member in pairs(members)do
                if(member.id ~= steam.user.getSteamID())then
                    if(data.players[tostring(member.id)] ~= nil and data.players[tostring(member.id)].ready)then
                        data.players[tostring(member.id)].ready = false
                    end
                end
            end
            for k, member in pairs(ready_players)do
                if(data.players[member] ~= nil)then
                    data.players[member].ready = true
                end
            end
        end
    end,
    ReadyAmount = function(data, lobby)
        local amount = data.client.ready and 1 or 0
        local members = steamutils.getLobbyMembers(lobby)
        for k, member in pairs(members)do
            if(member.id ~= steam.user.getSteamID())then
                if(data.players[tostring(member.id)] ~= nil and data.players[tostring(member.id)].ready)then
                    amount = amount + 1
                end
            end
        end
        return amount
    end,
    CheckFiringBlock = function(lobby, data)
        local members = steamutils.getLobbyMembers(lobby)
        for k, member in pairs(members)do
            if(member.id ~= steam.user.getSteamID())then
                if(data.players[tostring(member.id)] ~= nil and data.players[tostring(member.id)].entity ~= nil)then
                    local player_entity = data.players[tostring(member.id)].entity
                    if(EntityGetIsAlive(player_entity))then
                        --[[if(not data.players[tostring(member.id)].can_fire)then
                            entity.BlockFiring(player_entity, true)
                            data.players[tostring(member.id)].can_fire = false
                        else
                            entity.BlockFiring(player_entity, false)
                        end]]
                        entity.BlockFiring(player_entity, true)
                    end
                end
            end
        end
    end,
    FindUser = function(lobby, user_string)
        local members = steamutils.getLobbyMembers(lobby)
        for k, member in pairs(members)do
            --print("Member: " .. tostring(member.id))
            if(tostring(member.id) == user_string)then
                return member.id
            end
        end
        return nil
    end,
    TotalPlayers = function(lobby)
        local amount = 0
        for k, v in pairs(steamutils.getLobbyMembers(lobby))do
            amount = amount + 1
        end
        return amount
    end,
    ReadyCounter = function(lobby, data)
        data.ready_counter = counter.create("Players ready: ", function()
            local playersReady = ArenaGameplay.ReadyAmount(data, lobby)
            local totalPlayers = ArenaGameplay.TotalPlayers(lobby)
            
            return playersReady, totalPlayers
        end, function()
            data.ready_counter = nil
        end)
    end,
    LoadPlayer = function(lobby, data)
        local current_player = EntityLoad("data/entities/player.xml", 0, 0)
        game_funcs.SetPlayerEntity(current_player)
        np.RegisterPlayerEntityId(current_player)
        player.Deserialize(data.client.serialized_player, (not data.client.player_loaded_from_data))

        GameRemoveFlagRun("player_unloaded")
    end,
    AllowFiring = function(data)
        GameRemoveFlagRun("no_shooting")
        data.client.spread_index = 0
    end,
    PreventFiring = function()
        GameAddFlagRun("no_shooting")
    end,
    CancelFire = function(lobby, data)
        local player_entity = player.Get()
        if(player_entity ~= nil)then
            local items = GameGetAllInventoryItems( player_entity ) or {}
            for k, item in ipairs(items)do
                local abilityComponent = EntityGetFirstComponentIncludingDisabled(item, "AbilityComponent")
                if(abilityComponent ~= nil)then
                    -- set mNextFrameUsable to false
                    ComponentSetValue2(abilityComponent, "mNextFrameUsable", GameGetFrameNum() + 10)
                    -- set mReloadFramesLeft
                    ComponentSetValue2(abilityComponent, "mReloadFramesLeft", 10)
                    -- set mReloadNextFrameUsable to false
                    ComponentSetValue2(abilityComponent, "mReloadNextFrameUsable", GameGetFrameNum() + 10)
    
                end
            end
        end

        for k, v in pairs(data.players)do
            if(v.entity ~= nil)then
                local item = v.held_item
                if(item ~= nil)then
                    local abilityComponent = EntityGetFirstComponentIncludingDisabled(item, "AbilityComponent")
                    if(abilityComponent ~= nil)then
                        -- set mNextFrameUsable to false
                        ComponentSetValue2(abilityComponent, "mNextFrameUsable", GameGetFrameNum() + 10)
                        -- set mReloadFramesLeft
                        ComponentSetValue2(abilityComponent, "mReloadFramesLeft", 10)
                        -- set mReloadNextFrameUsable to false
                        ComponentSetValue2(abilityComponent, "mReloadNextFrameUsable", GameGetFrameNum() + 10)
                    end
                end
            end
        end
    end,
    IsInBounds = function(x, y, max_distance)
        local players = EntityGetWithTag("player_unit") or {}
        for k, v in pairs(players)do
            local x2, y2 = EntityGetTransform(v)
            local distance = math.sqrt((x2 - x) ^ 2 + (y2 - y) ^ 2)
            if(distance > max_distance)then
                return false
            end
        end
        return true
    end,
    DamageZoneCheck = function(x, y, max_distance, distance_cap)
        local players = EntityGetWithTag("player_unit") or {}
        for k, v in pairs(players)do
            local x2, y2 = EntityGetTransform(v)
            local distance = math.sqrt((x2 - x) ^ 2 + (y2 - y) ^ 2)
            if(distance > max_distance)then
                local healthComp = EntityGetFirstComponentIncludingDisabled(v, "DamageModelComponent")
                if(healthComp ~= nil)then
                    local health = tonumber(ComponentGetValue(healthComp, "hp"))
                    local max_health = tonumber(ComponentGetValue(healthComp, "max_hp"))
                    local base_health = 4
                    local damage_percentage = (distance - max_distance) / distance_cap
                    local damage = max_health * damage_percentage
                    EntityInflictDamage(v, damage, "DAMAGE_FALL", "Out of bounds", "BLOOD_EXPLOSION", 0, 0)
                end
            end
        end
    end,
    ResetDamageZone = function(lobby, data)
        GuiDestroy(data.zone_gui)
        data.zone_gui = nil
        data.zone_size = nil
        data.last_step_frame = nil
        data.ready_for_zone = false
        data.zone_spawned = false
    end,
    DamageZoneHandler = function(lobby, data, can_shrink)
        if(data.current_arena)then
            local default_size = data.current_arena.zone_size
            
            --{{"disabled", "Disabled"}, {"static", "Static"}, {"shrinking_Linear", "Linear Shrinking"}, {"shrinking_step", "Stepped Shrinking"}},
            local zone_type = GlobalsGetValue("zone_shrink", "static")
            local zone_speed = tonumber(GlobalsGetValue("zone_speed", "30")) -- pixels per step or pixels per minute (frames * 60 * 60)
            local zone_step_interval = tonumber(GlobalsGetValue("zone_step_interval", "30")) * 60 -- seconds between steps

            local step_time = zone_step_interval / 2

            if(zone_type ~= "disabled")then
                if(data.ready_for_zone and not data.zone_spawned)then
                    EntityLoad("mods/evaisa.arena/files/entities/area_indicator.xml", 0, 0)
                    data.zone_size = default_size
                    data.ready_for_zone = false
                    data.zone_spawned = true

                    GlobalsSetValue("arena_area_size", tostring(data.zone_size))
                    GlobalsSetValue("arena_area_size_cap", tostring(data.zone_size + 200))
                end


                if(data.zone_size ~= nil and can_shrink and steamutils.IsOwner(lobby))then

                    local zone_shrink_time = 0;

                    local last_zone_size = data.zone_size

                    if(data.last_step_frame == nil)then
                        data.last_step_frame = GameGetFrameNum()
                    end

                    if(zone_type == "shrinking_Linear")then

                        if(data.zone_gui == nil)then
                            data.zone_gui = GuiCreate()
                        end

                        GuiStartFrame(data.zone_gui)

                        local step_size = zone_speed / 60 / 60

                        --GamePrint("step_size: " .. step_size)
                        
                        data.zone_size = data.zone_size - step_size

                        if(data.zone_size < 0)then
                            data.zone_size = 0
                        end

                        GlobalsSetValue("arena_area_size", tostring(data.zone_size))
                        GlobalsSetValue("arena_area_size_cap", tostring(data.zone_size + 200))

                        if(not IsPaused())then

                            local screen_width, screen_height = GuiGetScreenDimensions(data.zone_gui)

                            local text = "Zone is shrinking (" .. math.ceil(data.zone_size) .. "/" .. default_size ..")"

                            local text_width, text_height = GuiGetTextDimensions(data.zone_gui, text)

                            GuiBeginAutoBox(data.zone_gui)
                            -- draw at bottom center of screen
                            GuiZSetForNextWidget(data.zone_gui, -200)
                            GuiText(data.zone_gui, (screen_width / 2) - (text_width / 2), screen_height - 12, text)
                            GuiZSetForNextWidget(data.zone_gui, -150)
                            GuiEndAutoBoxNinePiece(data.zone_gui, 2)
                        end

                    elseif(zone_type == "shrinking_step")then

                        if(data.zone_gui == nil)then
                            data.zone_gui = GuiCreate()
                        end

                        GuiStartFrame(data.zone_gui)
                        -- every step should take step_time seconds to complete
                        if(GameGetFrameNum() - data.last_step_frame > zone_step_interval)then
                            local step_size = zone_speed / step_time
                            data.zone_size = data.zone_size - step_size

                            if(data.zone_size < 0)then
                                data.zone_size = 0
                            end

                            if(GameGetFrameNum() - data.last_step_frame > zone_step_interval + step_time)then
                                data.last_step_frame = GameGetFrameNum()
                            end

                            GlobalsSetValue("arena_area_size", tostring(data.zone_size))
                            GlobalsSetValue("arena_area_size_cap", tostring(data.zone_size + 200))

                            if(not IsPaused())then

                                local screen_width, screen_height = GuiGetScreenDimensions(data.zone_gui)

                                local text = "Zone is shrinking (" .. math.ceil(data.zone_size) .. "/" .. default_size ..")"

                                local text_width, text_height = GuiGetTextDimensions(data.zone_gui, text)

                                
                                GuiBeginAutoBox(data.zone_gui)
                                -- draw at bottom center of screen
                                GuiZSetForNextWidget(data.zone_gui, -200)
                                GuiText(data.zone_gui, (screen_width / 2) - (text_width / 2), screen_height - 14, text)
                                GuiZSetForNextWidget(data.zone_gui, -150)
                                GuiEndAutoBoxNinePiece(data.zone_gui, 2)
                            end

                        else
                            if(not IsPaused())then
                                local screen_width, screen_height = GuiGetScreenDimensions(data.zone_gui)

                                local text = "Zone will shrink in " .. math.ceil((zone_step_interval - (GameGetFrameNum() - data.last_step_frame)) / 60) .. " seconds"

                                zone_shrink_time = math.ceil((zone_step_interval - (GameGetFrameNum() - data.last_step_frame)) / 60)

                                local text_width, text_height = GuiGetTextDimensions(data.zone_gui, text)

                                GuiBeginAutoBox(data.zone_gui)
                                -- draw at bottom center of screen
                                GuiZSetForNextWidget(data.zone_gui, -200)
                                GuiText(data.zone_gui, (screen_width / 2) - (text_width / 2), screen_height - 14, text)
                                GuiZSetForNextWidget(data.zone_gui, -150)
                                GuiEndAutoBoxNinePiece(data.zone_gui, 2)
                            end
                        end
                    end

      
                    message_handler.send.ZoneUpdate(lobby, data.zone_size, zone_shrink_time)
           
                   -- GamePrint("Zone size: " .. data.zone_size .. " (" .. last_zone_size .. " -> " .. data.zone_size .. ")")
                end

                if((not steamutils.IsOwner(lobby)) and (not IsPaused()) and data.zone_size ~= nil)then
                    if(data.zone_gui == nil)then
                        data.zone_gui = GuiCreate()
                    end

                    GuiStartFrame(data.zone_gui)

                   -- GamePrint("???")

                    if(zone_type == "shrinking_Linear")then
                        --GamePrint(tostring(data.zone_size))

                        local screen_width, screen_height = GuiGetScreenDimensions(data.zone_gui)

                        local text = "Zone is shrinking (" .. tostring(math.ceil(data.zone_size)) .. "/" .. default_size ..")"

                       -- GamePrint(text)

                        local text_width, text_height = GuiGetTextDimensions(data.zone_gui, text)

                        GuiBeginAutoBox(data.zone_gui)
                        -- draw at bottom center of screen
                        GuiZSetForNextWidget(data.zone_gui, -200)
                        GuiText(data.zone_gui, (screen_width / 2) - (text_width / 2), screen_height - 12, text)
                        GuiZSetForNextWidget(data.zone_gui, -150)
                        GuiEndAutoBoxNinePiece(data.zone_gui, 2)
                    elseif(zone_type == "shrinking_step")then
                        if(data.shrink_time == 0)then
                            local screen_width, screen_height = GuiGetScreenDimensions(data.zone_gui)

                            local text = "Zone is shrinking (" .. tostring(math.ceil(data.zone_size)) .. "/" .. default_size ..")"

                            --GamePrint(text)

                            local text_width, text_height = GuiGetTextDimensions(data.zone_gui, text)

                            GuiBeginAutoBox(data.zone_gui)
                            -- draw at bottom center of screen
                            GuiZSetForNextWidget(data.zone_gui, -200)
                            GuiText(data.zone_gui, (screen_width / 2) - (text_width / 2), screen_height - 14, text)
                            GuiZSetForNextWidget(data.zone_gui, -150)
                            GuiEndAutoBoxNinePiece(data.zone_gui, 2)
                        else

                            local screen_width, screen_height = GuiGetScreenDimensions(data.zone_gui)

                            local text = "Zone will shrink in " .. tostring(data.shrink_time) .. " seconds"

                            --GamePrint(text)

                            local text_width, text_height = GuiGetTextDimensions(data.zone_gui, text)

                            GuiBeginAutoBox(data.zone_gui)
                            -- draw at bottom center of screen
                            GuiZSetForNextWidget(data.zone_gui, -200)
                            GuiText(data.zone_gui, (screen_width / 2) - (text_width / 2), screen_height - 14, text)
                            GuiZSetForNextWidget(data.zone_gui, -150)
                            GuiEndAutoBoxNinePiece(data.zone_gui, 2)
                        end
                    end
                end
                
                if(GameGetFrameNum() % 60 == 0)then
                    ArenaGameplay.DamageZoneCheck(0, 0, data.zone_size, data.zone_size + 200)
                end


            end
        end
    end,
    WinnerCheck = function(lobby, data)
        local alive = data.client.alive and 1 or 0
        local winner = steam.user.getSteamID()
        for k, v in pairs(data.players)do
            if(v.alive)then
                alive = alive + 1
                winner = v.id
            end
        end
        if(alive == 1)then
            GamePrintImportant(steam.friends.getFriendPersonaName(winner) .. " won this round!", "Prepare for the next round in your holy mountain.")



            ArenaGameplay.LoadLobby(lobby, data, false)
        elseif(alive == 0)then
            GamePrintImportant("Nobody won this round!", "Prepare for the next round in your holy mountain.")

            ArenaGameplay.LoadLobby(lobby, data, false)
        end
    end,
    KillCheck = function(lobby, data)
        if(GameHasFlagRun("player_died"))then
            local killer = ModSettingGet("killer");
            local username = steam.friends.getFriendPersonaName(steam.user.getSteamID())

            if(killer == nil)then
                
                GamePrint(tostring(username) .. " died.")
            else
                local killer_id = ArenaGameplay.FindUser(lobby, killer)
                if(killer_id ~= nil)then
                    GamePrint(tostring(username) .. " was killed by " .. steam.friends.getFriendPersonaName(killer_id))
                else
                    GamePrint(tostring(username) .. " died.")
                end
            end

            --if(data.deaths == 0)then
                GameAddFlagRun("first_death")
                GamePrint("You will be compensated for dying.")
            --end

            data.deaths = data.deaths + 1
            data.client.alive = false

            message_handler.send.Death(lobby, killer)

            GameRemoveFlagRun("player_died")

            GamePrintImportant("You died!")

            GameSetCameraFree(true)

            player.Lock()
            player.Immortal(true)
            --player.Move(-3000, -3000)

            ArenaGameplay.WinnerCheck(lobby, data)
        end
    end,
    ClearWorld = function()
        local all_entities = EntityGetInRadius(0, 0, math.huge)
        for k, v in pairs(all_entities)do
            if(v ~= GameGetWorldStateEntity()--[[ and v ~= GameGetPlayerStatsEntity()]])then
                if(EntityHasTag(v, "player_unit"))then
                    EntityRemoveTag(v, "player_unit")
                end
                EntityKill(v)
            end
        end
    end,
    SavePlayerData = function(lobby, data)
        if((not GameHasFlagRun("player_unloaded")) and player.Get())then
  
            --[[local profile = profiler.new()
            profile:start()]]
            local serialized_player_data = player.Serialize()


            if(serialized_player_data ~= data.client.serialized_player)then
                steamutils.SetLocalLobbyData(lobby, "player_data",  serialized_player_data)

                        
                data.client.serialized_player = serialized_player_data
            end
            
            --[[profile:stop()
        
            print("Profiler result: "..tostring(profile:time()) .. "ms")]]

            local rerollCount = GlobalsGetValue( "TEMPLE_PERK_REROLL_COUNT", "0" )

            if(data.client.reroll_count ~= rerollCount)then
            
                steamutils.SetLocalLobbyData(lobby, "reroll_count",  rerollCount)

                data.client.reroll_count = rerollCount
            end
            
        end
    end,
    LoadLobby = function(lobby, data, show_message, first_entry)

        show_message = show_message or false
        first_entry = first_entry or false

        if(not first_entry)then
            --ArenaGameplay.SavePlayerData(lobby, data)
            ArenaGameplay.ClearWorld()
        end

        if(data.client.serialized_player)then
            first_entry = false
        end

        --[[
        local current_player = player.Get()

        if(current_player == nil)then
            ArenaGameplay.LoadPlayer(lobby, data)
        end
        ]]

        RunWhenPlayerExists(function()
            if(first_entry and player.Get())then
                GameDestroyInventoryItems( player.Get() )
            end
        end)

        -- clean other player's data
        ArenaGameplay.CleanMembers(lobby, data)

        -- manage flags
        GameRemoveFlagRun("player_ready")
        GameRemoveFlagRun("ready_check")
        GameRemoveFlagRun("player_unloaded")

        -- destroy active tweens
        data.tweens = {}
        
        -- clean local data
        data.client.ready = false
        data.client.alive = true
        data.client.previous_wand = nil
        data.client.previous_anim = nil
        data.projectile_seeds = {}
        data.current_arena = nil
        ArenaGameplay.ResetDamageZone(lobby, data)
        --data.client.projectile_homing = {}

        -- set state
        data.state = "lobby"

        RunWhenPlayerExists(function()
            -- clean and unlock player entity
            player.Clean(first_entry)
            player.Unlock()

            GameRemoveFlagRun("player_is_unlocked")

            -- grant immortality
            player.Immortal(true)

            -- move player to correct position
            player.Move(0, 0)
        end)

        -- get rounds
        local rounds = ArenaGameplay.GetNumRounds()

        if(data.client.player_loaded_from_data)then
            GameAddFlagRun("skip_perks")
            GameAddFlagRun("skip_health")
            ArenaGameplay.RemoveRound()
        end

        -- Give gold
        local rounds_limited = math.max(0, math.min(math.ceil(rounds / 2), 7))
        local extra_gold = 400 + (70 * (rounds_limited * rounds_limited))

        --print("First spawn gold = "..tostring(data.client.first_spawn_gold))

        print("First entry = "..tostring(first_entry))

        if(first_entry and data.client.first_spawn_gold > 0)then
            extra_gold = data.client.first_spawn_gold
        end

        GamePrint("You were granted " .. tostring(extra_gold) .. " gold for this round. (Rounds: " .. tostring(rounds) .. ")")

        print("Loaded from data: "..tostring(player_loaded_from_data))

        RunWhenPlayerExists(function()
            if(not data.client.player_loaded_from_data)then
                print("Giving gold: "..tostring(extra_gold))
                player.GiveGold(extra_gold)
            end
        end)


        RunWhenPlayerExists(function()
            -- if we are the owner of the lobby
            if(steamutils.IsOwner(lobby))then
                -- get the gold count from the lobby
                local gold = tonumber(steam.matchmaking.getLobbyData(lobby, "total_gold")) or 0
                -- add the new gold
                gold = gold + extra_gold
                -- set the new gold count
                steam.matchmaking.setLobbyData(lobby, "total_gold", tostring(gold))
            end
        end)

        -- increment holy mountain count
        
        ArenaGameplay.AddRound()
       

        RunWhenPlayerExists(function()
            -- give starting gear if first entry
            if(first_entry)then
                player.GiveStartingGear()
                if(((rounds - 1) > 0))then
                    player.GiveMaxHealth(0.4 * (rounds - 1))
                end
            end
        end)

        message_handler.send.Unready(lobby, true)

        -- load map
        BiomeMapLoad_KeepPlayer( "mods/evaisa.arena/files/scripts/world/map_lobby.lua", "mods/evaisa.arena/files/biome/holymountain_scenes.xml" )

        -- show message
        if(show_message)then
            GamePrintImportant("You have entered the holy mountain", "Prepare to enter the arena.")
        end

        
        -- clean other player's data again because it might have failed for some cursed reason
        ArenaGameplay.CleanMembers(lobby, data)

        -- set ready counter
        ArenaGameplay.ReadyCounter(lobby, data)


        -- print member data
        --print(json.stringify(data))
    end,
    LoadArena = function(lobby, data, show_message)
        --ArenaGameplay.SavePlayerData(lobby, data)

        show_message = show_message or false

        ArenaGameplay.ClearWorld()

        playermenu:Close()
        
        --[[
        local current_player = player.Get()

        if(current_player == nil)then
            ArenaGameplay.LoadPlayer(lobby, data)
        end
        ]]

        -- manage flags
        GameRemoveFlagRun("ready_check")
        GameRemoveFlagRun("first_death")
        GameRemoveFlagRun("in_hm")

        data.state = "arena"
        data.preparing = true
        data.players_loaded = false
        data.deaths = 0
        data.lobby_loaded = false
        data.client.player_loaded_from_data = false

        message_handler.send.SendPerks(lobby)

        ArenaGameplay.PreventFiring()

        -- load map
        local arena = arena_list[data.random.range(1, #arena_list)]

        data.current_arena = arena

        BiomeMapLoad_KeepPlayer( arena.biome_map, arena.pixel_scenes )

        RunWhenPlayerExists(function()
            player.Lock()

            -- move player to correct position
            data.spawn_point = arena.spawn_points[data.random.range(1, #arena.spawn_points)]

            ArenaGameplay.LoadClientPlayers(lobby, data)

            GamePrint("Loading arena")
        end)
    end,
    ReadyCheck = function(lobby, data)
        return ArenaGameplay.ReadyAmount(data, lobby) >= ArenaGameplay.TotalPlayers(lobby)
    end,
    CleanMembers = function(lobby, data)
        local members = steamutils.getLobbyMembers(lobby)
        
        for _, member in pairs(members)do
            if(member.id ~= steam.user.getSteamID() and data.players[tostring(member.id)] ~= nil)then
                data.players[tostring(member.id)]:Clean(lobby)
            end
        end
    end,
    UpdateTweens = function(lobby, data)
        local members = steamutils.getLobbyMembers(lobby)
    
        local validMembers = {}
    
        for _, member in pairs(members)do
            local memberid = tostring(member.id)
            
            validMembers[memberid] = true
        end
    
        -- iterate active tweens backwards and update
        for i = #data.tweens, 1, -1 do
            local tween = data.tweens[i]
            if(tween)then
                if(validMembers[tween.id] == nil)then
                    table.remove(data.tweens, i)
                else
                    if(tween:update())then
                        table.remove(data.tweens, i)
                    end
                end
            end
        end
    end,
    LobbyUpdate = function(lobby, data)
        -- update ready counter
        if(data.ready_counter ~= nil)then
            if(not IsPaused())then
                data.ready_counter:appy_offset(9, 28)
            else
                data.ready_counter:appy_offset(9, 9)
            end


            data.ready_counter:update()
        end

        if(steamutils.IsOwner(lobby))then
            -- check if all players are ready
            if(ArenaGameplay.ReadyCheck(lobby, data))then
                ArenaGameplay.LoadArena(lobby, data, true)
                message_handler.send.EnterArena(lobby)
            end
        end

        if(GameHasFlagRun("player_ready"))then
            GameRemoveFlagRun("player_ready")
            GamePrint("You are ready")
            message_handler.send.Ready(lobby)
            data.client.ready = true
        end

        if(GameHasFlagRun("player_unready"))then
            GameRemoveFlagRun("player_unready")
            GamePrint("You are no longer ready")
            message_handler.send.Unready(lobby)
            data.client.ready = false
        end

        if(GameGetFrameNum() % 5 == 0)then
            message_handler.send.UpdateHp(lobby, data)
            message_handler.send.SendPerks(lobby)
        end
    end,
    UpdateHealthbars = function(data)
        for k, v in pairs(data.players)do
            if(v.hp_bar)then
                if(v.entity ~= nil and EntityGetIsAlive(v.entity))then
                    local x, y = EntityGetTransform(v.entity)
                    y = y + 10
                    v.hp_bar:update(x, y)
                end
            end
        end
    end,
    CheckAllPlayersLoaded = function(lobby, data)
        local ready = not data.preparing
        for k, v in pairs(data.players)do
            if not v.loaded then
                ready = false
                break
            end
        end
        return ready
    end,
    FightCountdown = function(lobby, data)
        local playerEntity = player.Get()

        
        if(playerEntity ~= nil)then
            local inventory2Comp = EntityGetFirstComponentIncludingDisabled(playerEntity, "Inventory2Component")
            if(inventory2Comp ~= nil)then
                ComponentSetValue2(inventory2Comp, "mInitialized", false)
                ComponentSetValue2(inventory2Comp, "mForceRefresh", true)
                --[[
                local activeItem = ComponentGetValue2(playerEntity, "mActiveItem")

                if(activeItem ~= nil)then
                    local abilityComp = EntityGetFirstComponentIncludingDisabled(activeItem, "AbilityComponent")
                    if(abilityComp ~= nil)then
                        ComponentSetValue2(abilityComp, "mReloadFramesLeft", 2)
                        ComponentSetValue2(abilityComp, "mReloadNextFrameUsable", GameGetFrameNum() + 2)
                        ComponentSetValue2(abilityComp, "mNextFrameUsable", GameGetFrameNum() + 2)
                    end
                end]]
            end
        end
        
        
        player.Unlock()
        data.countdown = countdown.create({
            "mods/evaisa.arena/files/sprites/ui/countdown/ready.png",
            "mods/evaisa.arena/files/sprites/ui/countdown/3.png",
            "mods/evaisa.arena/files/sprites/ui/countdown/2.png",
            "mods/evaisa.arena/files/sprites/ui/countdown/1.png",
            "mods/evaisa.arena/files/sprites/ui/countdown/fight.png",
        }, 60, function()

            message_handler.send.Unlock(lobby)
            player.Immortal(false)
            ArenaGameplay.AllowFiring(data)
            message_handler.send.RequestWandUpdate(lobby, data)
            data.countdown = nil
        end)
    end,
    SpawnClientPlayer = function(lobby, user, data)
        local client = EntityLoad("mods/evaisa.arena/files/entities/client.xml", -1000, -1000)
        EntitySetName(client, tostring(user))
        local usernameSprite = EntityGetFirstComponentIncludingDisabled(client, "SpriteComponent", "username")
        local name = steam.friends.getFriendPersonaName(user)
        ComponentSetValue2(usernameSprite, "text", name)
        ComponentSetValue2(usernameSprite, "offset_x", string.len(name) * (1.8))
        data.players[tostring(user)].entity = client
        data.players[tostring(user)].alive = true

        print("Spawned client player for " .. name)

        if(data.players[tostring(user)].perks)then
            for k, v in ipairs(data.players[tostring(user)].perks)do
                local perk = v.id
                local count = v.count
                local run_on_clients = v.run_on_clients
                
                if(run_on_clients)then
                    for i = 1, count do
                        entity.GivePerk(client, perk, i)
                    end
                end
            end
        end
    end,
    CheckPlayer = function(lobby, user, data)
        if(not data.players[tostring(user)].entity and data.players[tostring(user)].alive)then
            --ArenaGameplay.SpawnClientPlayer(lobby, user, data)
            return false
        end
        return true
    end,
    LoadClientPlayers = function(lobby, data)
        local members = steamutils.getLobbyMembers(lobby)
        
        for _, member in pairs(members)do
            if(member.id ~= steam.user.getSteamID() and data.players[tostring(member.id)].entity)then
                data.players[tostring(member.id)]:Clean(lobby)
            end

            --[[if(member.id ~= steam.user.getSteamID())then
                print(json.stringify(data.players[tostring(member.id)]))
            end]]

            if(member.id ~= steam.user.getSteamID() and data.players[tostring(member.id)].entity == nil)then
                --GamePrint("Loading player " .. tostring(member.id))
                ArenaGameplay.SpawnClientPlayer(lobby, member.id, data)
            end
        end
    end,
    ClosestPlayer = function(x, y)
        closest = EntityGetClosestWithTag(x, y, "client")
        if(closest ~= nil)then
            return EntityGetName(closest)
        end

        return nil
    end,
    ArenaUpdate = function(lobby, data)
        if(data.preparing)then
            local spawn_points = EntityGetWithTag("spawn_point") or {}
            if(spawn_points ~= nil and #spawn_points > 0)then

                data.ready_for_zone = true

                local spawn_point = spawn_points[Random(1, #spawn_points)]
                local x, y = EntityGetTransform(spawn_point)

                local spawn_loaded = DoesWorldExistAt( x-100, y-100, x+100, y+100 )

                player.Move(x, y)

                print("Arena loaded? "..tostring(spawn_loaded))

                local in_bounds = ArenaGameplay.IsInBounds(0, 0, 400)

                if(not in_bounds)then
                    print("Game tried to spawn player out of bounds, retrying...")
                    GamePrint("Game attempted to spawn you out of bounds, retrying...")
                end
                
                if(spawn_loaded and in_bounds)then
                    

                    data.preparing = false
                    

                    GamePrint("Spawned!!")
                    
                    if(not steamutils.IsOwner(lobby))then
                        message_handler.send.Loaded(lobby)
                    end

                    message_handler.send.Health(lobby)
                end
            else
                player.Move(data.spawn_point.x, data.spawn_point.y)
            end
        end
        local player_entities = {}
        for k, v in pairs(data.players)do
            if(v.entity ~= nil and EntityGetIsAlive(v.entity))then
                table.insert(player_entities, v.entity)
            end
        end
        if(not IsPaused() and GameHasFlagRun("player_is_unlocked") and (not GameHasFlagRun("no_shooting")))then
            game_funcs.RenderOffScreenMarkers(player_entities)
            game_funcs.RenderAboveHeadMarkers(player_entities, 0, 27)
            ArenaGameplay.UpdateHealthbars(data)
        end

        if(GameHasFlagRun("player_is_unlocked") and (not GameHasFlagRun("no_shooting")))then
            ArenaGameplay.DamageZoneHandler(lobby, data, true)
        else
            ArenaGameplay.DamageZoneHandler(lobby, data, false)
        end

        if(steamutils.IsOwner(lobby))then
            if(not data.players_loaded and ArenaGameplay.CheckAllPlayersLoaded(lobby, data))then
                data.players_loaded = true
                print("All players loaded")
                message_handler.send.StartCountdown(lobby)
                ArenaGameplay.FightCountdown(lobby, data)
            end
        end
        if(data.countdown ~= nil)then
            data.countdown:update()
        end
        --if(GameGetFrameNum() % 2 == 0)then
            message_handler.send.CharacterUpdate(lobby)
        --end

        if(GameHasFlagRun("took_damage"))then
            GameRemoveFlagRun("took_damage")
            message_handler.send.Health(lobby)
        end
        if(data.players_loaded)then
            message_handler.send.WandUpdate(lobby, data)
            message_handler.send.SwitchItem(lobby, data)
            --message_handler.send.Kick(lobby, data)
            message_handler.send.AnimationUpdate(lobby, data)
            --message_handler.send.AimUpdate(lobby)
            message_handler.send.SyncControls(lobby, data)
            
            ArenaGameplay.CheckFiringBlock(lobby, data)
        end
    end,
    ValidatePlayers = function(lobby, data)
        for k, v in pairs(data.players)do
            local playerid = ArenaGameplay.FindUser(lobby, k)

            if(playerid == nil)then
                print("Player " .. k .. " is not in the lobby anymore")
                v:Clean(lobby)
                data.players[k] = nil
            end
        end
    end,
    Update = function(lobby, data)

        if(GameGetFrameNum() % 60 == 0)then
            message_handler.send.Handshake(lobby)
        end

        --[[local chunk_loaders = EntityGetWithTag("chunk_loader") or {}
        for k, v in pairs(chunk_loaders)do
            local chunk_loader_x, chunk_loader_y = EntityGetTransform(v)
            game_funcs.LoadRegion(chunk_loader_x, chunk_loader_y, 1000, 1000)
        end]]
        


        for k, v in pairs(data.players)do
            if(v.entity ~= nil and EntityGetIsAlive(v.entity))then
                local controls = EntityGetFirstComponentIncludingDisabled(v.entity, "ControlsComponent")
                if(controls)then
 
                    ComponentSetValue2(controls, "mButtonDownKick", false)
                    ComponentSetValue2(controls, "mButtonDownFire", false)
                    ComponentSetValue2(controls, "mButtonDownFire2", false)
                    ComponentSetValue2(controls, "mButtonDownLeftClick", false)
                    ComponentSetValue2(controls, "mButtonDownRightClick", false)

                end
            end
        end

        if(data.state == "lobby")then
            ArenaGameplay.LobbyUpdate(lobby, data)
        elseif(data.state == "arena")then
           -- message_handler.send.SyncWandStats(lobby, data)
            ArenaGameplay.ArenaUpdate(lobby, data)
            ArenaGameplay.KillCheck(lobby, data)
        end
        if(GameHasFlagRun("no_shooting"))then
            ArenaGameplay.CancelFire(lobby, data)
        end
        ArenaGameplay.UpdateTweens(lobby, data)
        if(GameGetFrameNum() % 60 == 0)then
            ArenaGameplay.ValidatePlayers(lobby, data)
        end
    end,
    LateUpdate = function(lobby, data)
        if(data.state == "arena")then
            ArenaGameplay.KillCheck(lobby, data)
            
            if(data.client.projectiles_fired ~= nil and data.client.projectiles_fired > 0)then
                local special_seed = tonumber(GlobalsGetValue("player_rng", "0"))
                --local cast_state = GlobalsGetValue("player_cast_state") or nil

                --print(tostring(cast_state))

                local cast_state = nil

                --GamePrint("Sending special seed:"..tostring(special_seed))
                message_handler.send.WandFired(lobby, data.client.projectile_rng_stack, special_seed, cast_state)
                data.client.projectiles_fired = 0
                data.client.projectile_rng_stack = {}
            end
        

            GlobalsSetValue( "wand_fire_count", "0" )
            --
        else
            data.client.projectile_rng_stack = {}
            data.client.projectiles_fired = 0
        end
        local current_player = player.Get()




        if((not GameHasFlagRun("player_unloaded")) and current_player == nil)then
            ArenaGameplay.LoadPlayer(lobby, data)
            print("Player is missing, spawning player.")
        else
            if(GameGetFrameNum() % 60 == 0)then
                ArenaGameplay.SavePlayerData(lobby, data)
            end
        end


        if(data.current_player ~= current_player)then
            data.current_player = current_player
            if(current_player ~= nil)then
                np.RegisterPlayerEntityId(current_player)
            end
        end

        if(GameHasFlagRun("in_hm") and current_player)then
            player.Move(0, 0)
            GameRemoveFlagRun("in_hm")
        end

        if(GameGetFrameNum() % 5 == 0)then
            -- if we are host
            if(steamutils.IsOwner(lobby))then
                ArenaGameplay.SendGameData(lobby, data)
            end
        end

        for k, v in pairs(data.players)do
            if(v.entity ~= nil and EntityGetIsAlive(v.entity))then
                local controls = EntityGetFirstComponentIncludingDisabled(v.entity, "ControlsComponent")
                if(controls)then
                    if(ComponentGetValue2(controls, "mButtonDownKick") == false)then
                        data.players[k].controls.kick = false
                    end
                    -- mButtonDownFire
                    if(ComponentGetValue2(controls, "mButtonDownFire") == false)then
                        data.players[k].controls.fire = false
                    end
                    -- mButtonDownFire2
                    if(ComponentGetValue2(controls, "mButtonDownFire2") == false)then
                        data.players[k].controls.fire2 = false
                    end
                    -- mButtonDownLeft
                    if(ComponentGetValue2(controls, "mButtonDownLeftClick") == false)then
                        data.players[k].controls.leftClick = false
                    end
                    -- mButtonDownRight
                    if(ComponentGetValue2(controls, "mButtonDownRightClick") == false)then
                        data.players[k].controls.rightClick = false
                    end
                end
            end
        end

        local current_player = player.Get()

        if((not GameHasFlagRun("player_unloaded")) and current_player ~= nil and EntityGetIsAlive(current_player))then
            --print("Running player function queue")
            -- run playerRunQueue
            for i = 1, #playerRunQueue do
                local func = playerRunQueue[i]
                print("Ran item #" .. i .. " in playerRunQueue")
                func()
            end
            playerRunQueue = {}
        end
    end,
    OnProjectileFired = function(lobby, data, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message)
        if(data.state == "arena")then
            local playerEntity = player.Get()
            if(playerEntity ~= nil)then
                if(playerEntity == shooter_id)then
                    local projectileComponent = EntityGetFirstComponentIncludingDisabled(projectile_id, "ProjectileComponent")

                    local who_shot = ComponentGetValue2(projectileComponent, "mWhoShot")
                    local entity_that_shot  = ComponentGetValue2(projectileComponent, "mEntityThatShot")
                    if(entity_that_shot == 0)then
                        data.client.projectiles_fired = data.client.projectiles_fired + 1
                        
                        --rng = data.client.spread_index
                        local rand = data.random.range(0, 100000)
                        local rng = math.floor(rand)

                        table.insert(data.client.projectile_rng_stack, rng)

                        --GamePrint("Setting spread rng: "..tostring(rng))

                        np.SetProjectileSpreadRNG(rng)

                        --data.client.spread_index = data.client.spread_index + 1

                        --[[if(data.client.spread_index > 10)then
                            data.client.spread_index = 1
                        end]]
                    else
                        if(data.client.projectile_seeds[entity_that_shot])then
                            local new_seed = data.projectile_seeds[entity_that_shot] + 25
                            np.SetProjectileSpreadRNG(new_seed)
                            data.projectile_seeds[entity_that_shot] = data.projectile_seeds[entity_that_shot] + 10
                            data.projectile_seeds[projectile_id] = new_seed
                        end
                    end
                end
            end
            if(EntityGetName(shooter_id) ~= nil and tonumber(EntityGetName(shooter_id)))then
                if(data.players[EntityGetName(shooter_id)])then

                    --print("whar")

                    --GamePrint("Setting RNG: "..tostring(arenaPlayerData[EntityGetName(shooter_id)].next_rng))
                    local projectileComponent = EntityGetFirstComponentIncludingDisabled(projectile_id, "ProjectileComponent")

                    local who_shot = ComponentGetValue2(projectileComponent, "mWhoShot")
                    local entity_that_shot  = ComponentGetValue2(projectileComponent, "mEntityThatShot")
                    if(entity_that_shot == 0)then
                        local rng = 0
                        if(#(data.players[EntityGetName(shooter_id)].projectile_rng_stack) > 0)then
                            -- set rng to first in stack, remove
                            rng = table.remove(data.players[EntityGetName(shooter_id)].projectile_rng_stack, 1)
                        end
                        --GamePrint("Setting client spread rng: "..tostring(rng))

                        np.SetProjectileSpreadRNG(rng)

                        data.players[EntityGetName(shooter_id)].next_rng = rng + 1
                    else
                        if(data.projectile_seeds[entity_that_shot])then
                            local new_seed = data.projectile_seeds[entity_that_shot] + 25
                            np.SetProjectileSpreadRNG(new_seed)
                            data.projectile_seeds[entity_that_shot] = data.projectile_seeds[entity_that_shot] + 10
                        end
                    end
                end
            end
        end
        --[[
        if(data.state == "arena")then
            local playerEntity = player.Get()
            if(playerEntity ~= nil)then
                if(playerEntity == shooter_id)then
                    local projectileComponent = EntityGetFirstComponentIncludingDisabled(projectile_id, "ProjectileComponent")

                    local who_shot = ComponentGetValue2(projectileComponent, "mWhoShot")
                    local entity_that_shot  = ComponentGetValue2(projectileComponent, "mEntityThatShot")
        
                    if(entity_that_shot == 0)then
                        --math.randomseed( tonumber(tostring(steam.user.getSteamID())) + ((os.time() + GameGetFrameNum()) / 2))
                        local rand = data.random.range(0, 100000)
                        local rng = math.floor(rand)
                        --GamePrint("Setting RNG: "..tostring(rng))
                        np.SetProjectileSpreadRNG(rng)

                        data.client.projectile_seeds[projectile_id] = rng
                        --GamePrint("generated_rng: "..tostring(rng))

                        --local special_seed = tonumber(GlobalsGetValue("player_rng", "0"))
  
                        --local fire_count = GlobalsGetValue( "wand_fire_count", "0" )


                        --message_handler.send.WandFired(lobby, rng, nil, special_seed)
                        
                    else
                        if(data.client.projectile_seeds[entity_that_shot])then
                            local new_seed = data.client.projectile_seeds[entity_that_shot] + 10
                            np.SetProjectileSpreadRNG(new_seed)
                            data.client.projectile_seeds[entity_that_shot] = data.client.projectile_seeds[entity_that_shot] + 1
                            data.client.projectile_seeds[projectile_id] = new_seed
                        end
                    end
                    return
                end
            end

            if(EntityGetName(shooter_id) ~= nil and tonumber(EntityGetName(shooter_id)))then
                if(data.players[EntityGetName(shooter_id)] and data.players[EntityGetName(shooter_id)].next_rng)then

                    data.players[EntityGetName(shooter_id)].next_fire_data = nil

                    --GamePrint("Setting RNG: "..tostring(arenaPlayerData[EntityGetName(shooter_id)].next_rng))
                    local projectileComponent = EntityGetFirstComponentIncludingDisabled(projectile_id, "ProjectileComponent")

                    local who_shot = ComponentGetValue2(projectileComponent, "mWhoShot")
                    local entity_that_shot  = ComponentGetValue2(projectileComponent, "mEntityThatShot")
                    if(entity_that_shot == 0)then
                        np.SetProjectileSpreadRNG(data.players[EntityGetName(shooter_id)].next_rng)
                        data.client.projectile_seeds[projectile_id] = data.players[EntityGetName(shooter_id)].next_rng
                    else
                        if(data.client.projectile_seeds[entity_that_shot])then
                            local new_seed = data.client.projectile_seeds[entity_that_shot] + 10
                            np.SetProjectileSpreadRNG(new_seed)
                            data.client.projectile_seeds[entity_that_shot] = data.client.projectile_seeds[entity_that_shot] + 1
                        end
                    end
                end
                return
            end
        end
        ]]
    end,
    OnProjectileFiredPost = function(lobby, data, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message)

        --[[local projectileComp = EntityGetFirstComponentIncludingDisabled(projectile_id, "ProjectileComponent")
        if(projectileComp ~= nil)then
            local who_shot = ComponentGetValue2(projectileComp, "mWhoShot")
            --GamePrint("who_shot: "..tostring(who_shot))
        end]]


        local homingComponents = EntityGetComponentIncludingDisabled(projectile_id, "HomingComponent")

        local shooter_x, shooter_y = EntityGetTransform(shooter_id)

        if(homingComponents ~= nil)then
            for k, v in pairs(homingComponents)do
                local target_who_shot = ComponentGetValue2(v, "target_who_shot")
                if(target_who_shot == false)then
                    if(EntityHasTag(shooter_id, "client"))then
                        -- find closest player which isn't us
                        local closest_player = nil
                        local distance = 9999999
                        local clients = EntityGetWithTag("client")
                        -- add local player to list
                        if(player.Get())then
                            table.insert(clients, player.Get())
                        end

                        for k, v in pairs(clients)do
                            if(v ~= shooter_id)then
                                if(closest_player == nil)then
                                    closest_player = v
                                else
                                    local x, y = EntityGetTransform(v)
                                    local dist = math.abs(x - shooter_x) + math.abs(y - shooter_y)
                                    if(dist < distance)then
                                        distance = dist
                                        closest_player = v
                                    end
                                end
                            end
                        end

                        if(closest_player)then
                            ComponentSetValue2(v, "predefined_target", closest_player)
                            ComponentSetValue2(v, "target_tag", "mortal")
                        end
                    else
                        local closest_player = nil
                        local distance = 9999999
                        local clients = EntityGetWithTag("client")

                        for k, v in pairs(clients)do
                            if(v ~= shooter_id)then
                                if(closest_player == nil)then
                                    closest_player = v
                                else
                                    local x, y = EntityGetTransform(v)
                                    local dist = math.abs(x - shooter_x) + math.abs(y - shooter_y)
                                    if(dist < distance)then
                                        distance = dist
                                        closest_player = v
                                    end
                                end
                            end
                        end

                        if(closest_player)then
                            ComponentSetValue2(v, "predefined_target", closest_player)
                            ComponentSetValue2(v, "target_tag", "mortal")
                        end

                    end

                end
            end
        end
    end,
}

return ArenaGameplay