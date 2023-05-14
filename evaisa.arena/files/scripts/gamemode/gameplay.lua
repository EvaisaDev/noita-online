local steamutils = dofile_once("mods/evaisa.mp/lib/steamutils.lua")
local player = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/player.lua")
local entity = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/entity.lua")
local counter = dofile_once("mods/evaisa.arena/files/scripts/utilities/ready_counter.lua")
local countdown = dofile_once("mods/evaisa.arena/files/scripts/utilities/countdown.lua")
local json = dofile("mods/evaisa.arena/lib/json.lua")
dofile_once("mods/evaisa.arena/content/data.lua")

ArenaLoadCountdown = ArenaLoadCountdown or nil

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
        for k, member in pairs(members) do
            if (member.id ~= steam.user.getSteamID()) then
                if (data.players[tostring(member.id)] ~= nil and data.players[tostring(member.id)].ready) then
                    table.insert(ready_players, tostring(member.id))
                end
            end
        end
        steam.matchmaking.setLobbyData(lobby, "ready_players", bitser.dumps(ready_players))
    end,
    GetGameData = function(lobby, data)
        local mountainCount = tonumber(steam.matchmaking.getLobbyData(lobby, "holyMountainCount"))
        if (mountainCount ~= nil) then
            GlobalsSetValue("holyMountainCount", tostring(mountainCount))
            arena_log:print("Holymountain count: " .. mountainCount)
        end
        local goldCount = tonumber(steam.matchmaking.getLobbyData(lobby, "total_gold"))
        if (goldCount ~= nil) then
            data.client.first_spawn_gold = goldCount
            arena_log:print("Gold count: " .. goldCount)
        end
        local playerData = steamutils.GetLocalLobbyData(lobby, "player_data") --steam.matchmaking.getLobbyMemberData(lobby, steam.user.getSteamID(), "player_data")
        --local rerollCount = tonumber(steamutils.GetLocalLobbyData(lobby, "reroll_count") or 0)

        --[[
             local match_data = {
                reroll_count = GlobalsGetValue("TEMPLE_PERK_REROLL_COUNT", "0"),
                picked_health = GameHasFlagRun("picked_health"),
                picked_perk = GameHasFlagRun("picked_perk"),
            }

            local serialized = bitser.dumps(match_data)

            if(data.client.match_data ~= serialized)then
                steamutils.SetLocalLobbyData(lobby, "match_data", serialized)

                data.client.match_data = serialized
            end
        ]]

        if(steamutils.GetLocalLobbyData(lobby, "match_data") ~= nil)then
            local match_data = bitser.loads(steamutils.GetLocalLobbyData(lobby, "match_data"))

            if(match_data ~= nil)then
                data.client.reroll_count = tonumber(match_data.reroll_count)
                GlobalsSetValue("TEMPLE_PERK_REROLL_COUNT", tostring(data.client.reroll_count))
                GameAddFlagRun("picked_health")
                GameAddFlagRun("picked_perk")
            end
        end

        --[[
        if(steamutils.GetLocalLobbyData(lobby, "reroll_count") == nil)then
            data.rejoined = true
        end

        data.client.reroll_count = rerollCount

        GlobalsSetValue("TEMPLE_PERK_REROLL_COUNT", tostring(rerollCount))
        ]]

        if (playerData ~= nil and playerData ~= "") then
            data.client.serialized_player = playerData

            data.client.player_loaded_from_data = true
            --data.client.serialized_player = bitser.dumps(playerData)
            arena_log:print("Player data: " .. data.client.serialized_player)
        end
        
        local ready_players_string = steam.matchmaking.getLobbyData(lobby, "ready_players")
        local ready_players = (ready_players_string ~= nil and ready_players_string ~= "null") and
            bitser.loads(ready_players_string) or nil
        local members = steamutils.getLobbyMembers(lobby)

        --print(tostring(ready_players_string))
        if (ready_players ~= nil) then
            for k, member in pairs(members) do
                if (member.id ~= steam.user.getSteamID()) then
                    if (data.players[tostring(member.id)] ~= nil and data.players[tostring(member.id)].ready) then
                        data.players[tostring(member.id)].ready = false
                    end
                end
            end
            for k, member in pairs(ready_players) do
                if (data.players[member] ~= nil) then
                    data.players[member].ready = true
                end
            end
        end
    end,
    GracefulReset = function(lobby, data)
        if (data.spectator_gui) then
            GuiDestroy(data.spectator_gui)
            data.spectator_gui = nil
            if(data.spectator_text_gui)then
                GuiDestroy(data.spectator_text_gui)
                data.spectator_text_gui = nil
            end

            if (data.spectator_gui_entity and EntityGetIsAlive(data.spectator_gui_entity)) then
                EntityKill(data.spectator_gui_entity)
            end
        end
        if (data.countdown) then
            data.countdown:cleanup()
            data.countdown = nil
        end
        if (data.ready_counter) then
            data.ready_counter:cleanup()
            data.ready_counter = nil
        end
    end,
    ResetEverything = function(lobby)
        local player = player.Get()

        dofile_once("data/scripts/perks/perk_list.lua")
        for i, perk_data in ipairs(perk_list) do
            local perk_id = perk_data.id
            local flag_name = get_perk_picked_flag_name(perk_id)

            local pickup_count = tonumber(GlobalsGetValue(flag_name .. "_PICKUP_COUNT", "0"))

            if (pickup_count > 0) then
                if (perk_data.func_remove ~= nil) then
                    perk_data.func_remove(player)
                end
            end

            GlobalsSetValue(flag_name .. "_PICKUP_COUNT", "0")
        end

        if (player ~= nil) then
            EntityKill(player)
        end

        GlobalsSetValue("TEMPLE_SHOP_ITEM_COUNT", "5")
        GlobalsSetValue("TEMPLE_PERK_REROLL_COUNT", "0")
        GlobalsSetValue("EXTRA_MONEY_COUNT", "0")
        GlobalsSetValue("RESPAWN_COUNT", "0")
        GlobalsSetValue("holyMountainCount", "0")
        GlobalsSetValue("HEARTS_MORE_EXTRA_HP_MULTIPLIER", "1")
        GlobalsSetValue("PERK_SHIELD_COUNT", "0")
        GlobalsSetValue("PERK_ATTRACT_ITEMS_RANGE", "0")
        GlobalsSetValue("PERK_NO_MORE_SHUFFLE_WANDS", "0")
        GlobalsSetValue("TEMPLE_PERK_COUNT", "3")
        GlobalsSetValue("TEMPLE_PERK_DESTROY_CHANCE", "100")
        GlobalsSetValue("TEMPLE_SHOP_ITEM_COUNT", "5")
        GlobalsSetValue("TEMPLE_PEACE_WITH_GODS", "0")
        GlobalsSetValue("TEMPLE_SPAWN_GUARDIAN", "0")
        GameRemoveFlagRun("ATTACK_FOOT_CLIMBER")
        GameRemoveFlagRun("player_status_cordyceps")
        GameRemoveFlagRun("player_status_mold")
        GameRemoveFlagRun("player_status_fungal_disease")
        GameRemoveFlagRun("player_status_angry_ghost")
        GameRemoveFlagRun("player_status_hungry_ghost")
        GameRemoveFlagRun("player_status_death_ghost")
        GameRemoveFlagRun("player_status_lukki_minion")
        GameRemoveFlagRun("exploding_gold")
        GameRemoveFlagRun("first_death")

        if (steamutils.IsOwner(lobby)) then
            steam.matchmaking.deleteLobbyData(lobby, "holyMountainCount")
            steam.matchmaking.deleteLobbyData(lobby, "total_gold")
            steam.matchmaking.deleteLobbyData(lobby, "ready_players")

            -- loop through all players and remove their data
            local members = steamutils.getLobbyMembers(lobby)
            for k, member in pairs(members) do
                local winner_key = tostring(member.id) .. "_wins"
                steam.matchmaking.deleteLobbyData(lobby, winner_key)
            end
        end

        GameRemoveFlagRun("saving_grace")
        GameRemoveFlagRun("player_ready")
    end,
    ReadyAmount = function(data, lobby)
        local amount = data.client.ready and 1 or 0
        local members = steamutils.getLobbyMembers(lobby)
        for k, member in pairs(members) do
            if (member.id ~= steam.user.getSteamID()) then
                if (data.players[tostring(member.id)] ~= nil and data.players[tostring(member.id)].ready) then
                    amount = amount + 1
                end
            end
        end
        return amount
    end,
    CheckFiringBlock = function(lobby, data)
        local members = steamutils.getLobbyMembers(lobby)
        for k, member in pairs(members) do
            if (member.id ~= steam.user.getSteamID()) then
                if (data.players[tostring(member.id)] ~= nil and data.players[tostring(member.id)].entity ~= nil) then
                    local player_entity = data.players[tostring(member.id)].entity
                    if (EntityGetIsAlive(player_entity)) then
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
    FindUser = function(lobby, user_string, debug)
        local members = steamutils.getLobbyMembers(lobby)
        for k, member in pairs(members) do
            if (tostring(member.id) == user_string) then
                if (debug) then
                    arena_log:print("found member: " .. tostring(member.id))
                end
                return member.id
            end
        end
        return nil
    end,
    TotalPlayers = function(lobby)
        local amount = 0
        for k, v in pairs(steamutils.getLobbyMembers(lobby)) do
            amount = amount + 1
        end
        return amount
    end,
    ReadyCounter = function(lobby, data)
        data.ready_counter = counter.create(GameTextGetTranslatedOrNot("$arena_players_ready"), function()
            local playersReady = ArenaGameplay.ReadyAmount(data, lobby)
            local totalPlayers = ArenaGameplay.TotalPlayers(lobby)

            return playersReady, totalPlayers
        end, function()
            data.ready_counter = nil
        end)
    end,
    LoadPlayer = function(lobby, data)
        local current_player = EntityLoad("data/entities/player.xml", 0, 0)

        local aiming_reticle = EntityGetComponentIncludingDisabled(current_player, "SpriteComponent", "aiming_reticle") or {}

        for k, v in ipairs(aiming_reticle)do
            if(GameGetIsGamepadConnected())then
                ComponentSetValue2(v, "visible", true)
            else
                ComponentSetValue2(v, "visible", false)
            end
        end

        game_funcs.SetPlayerEntity(current_player)
        np.RegisterPlayerEntityId(current_player)

        -- Mark inventory as initialised, else the game will change the item
        -- after we've set it in the deserialization.
        local inventory = EntityGetFirstComponentIncludingDisabled(current_player, "Inventory2Component")
        ComponentSetValue2(inventory, "mInitialized", true)

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
        if (player_entity ~= nil) then
            local items = GameGetAllInventoryItems(player_entity) or {}
            for k, item in ipairs(items) do
                local abilityComponent = EntityGetFirstComponentIncludingDisabled(item, "AbilityComponent")
                if (abilityComponent ~= nil) then
                    -- set mNextFrameUsable to false
                    ComponentSetValue2(abilityComponent, "mNextFrameUsable", GameGetFrameNum() + 10)
                    -- set mReloadFramesLeft
                    ComponentSetValue2(abilityComponent, "mReloadFramesLeft", 10)
                    -- set mReloadNextFrameUsable to false
                    ComponentSetValue2(abilityComponent, "mReloadNextFrameUsable", GameGetFrameNum() + 10)
                end
            end
        end

        for k, v in pairs(data.players) do
            if (v.entity ~= nil) then
                local item = v.held_item
                if (item ~= nil) then
                    local abilityComponent = EntityGetFirstComponentIncludingDisabled(item, "AbilityComponent")
                    if (abilityComponent ~= nil) then
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
        for k, v in pairs(players) do
            local x2, y2 = EntityGetTransform(v)
            local distance = math.sqrt((x2 - x) ^ 2 + (y2 - y) ^ 2)
            if (distance > max_distance) then
                return false
            end
        end
        return true
    end,
    DamageZoneCheck = function(x, y, max_distance, distance_cap)
        local players = EntityGetWithTag("player_unit") or {}
        for k, v in pairs(players) do
            local x2, y2 = EntityGetTransform(v)
            local distance = math.sqrt((x2 - x) ^ 2 + (y2 - y) ^ 2)
            if (distance > max_distance) then
                local healthComp = EntityGetFirstComponentIncludingDisabled(v, "DamageModelComponent")
                if (healthComp ~= nil) then
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
        if (data.current_arena) then
            local default_size = data.current_arena.zone_size

            --{{"disabled", "Disabled"}, {"static", "Static"}, {"shrinking_Linear", "Linear Shrinking"}, {"shrinking_step", "Stepped Shrinking"}},
            local zone_type = GlobalsGetValue("zone_shrink", "static")
            local zone_speed = tonumber(GlobalsGetValue("zone_speed", "30")) -- pixels per step or pixels per minute (frames * 60 * 60)
            local zone_step_interval = tonumber(GlobalsGetValue("zone_step_interval", "30")) *
                60                                                           -- seconds between steps

            local step_time = zone_step_interval / 2

            if (zone_type ~= "disabled") then
                if (data.ready_for_zone and not data.zone_spawned) then
                    EntityLoad("mods/evaisa.arena/files/entities/area_indicator.xml", 0, 0)
                    data.zone_size = default_size
                    data.ready_for_zone = false
                    data.zone_spawned = true

                    GlobalsSetValue("arena_area_size", tostring(data.zone_size))
                    GlobalsSetValue("arena_area_size_cap", tostring(data.zone_size + 200))
                end


                if (data.zone_size ~= nil and can_shrink and steamutils.IsOwner(lobby)) then
                    local zone_shrink_time = 0;

                    local last_zone_size = data.zone_size

                    if (data.last_step_frame == nil) then
                        data.last_step_frame = GameGetFrameNum()
                    end

                    if (zone_type == "shrinking_Linear") then
                        if (data.zone_gui == nil) then
                            data.zone_gui = GuiCreate()
                        end

                        GuiStartFrame(data.zone_gui)

                        if (data.using_controller) then
                            GuiOptionsAdd(data.zone_gui, GUI_OPTION.NonInteractive)
                        end

                        local step_size = zone_speed / 60 / 60

                        --GamePrint("step_size: " .. step_size)

                        data.zone_size = data.zone_size - step_size

                        if (data.zone_size < 0) then
                            data.zone_size = 0
                        end

                        GlobalsSetValue("arena_area_size", tostring(data.zone_size))
                        GlobalsSetValue("arena_area_size_cap", tostring(data.zone_size + 200))

                        if (not IsPaused()) then
                            local screen_width, screen_height = GuiGetScreenDimensions(data.zone_gui)

                            local text = GameTextGetTranslatedOrNot("$arena_zone_shrinking").." (" .. math.ceil(data.zone_size) .. "/" .. default_size .. ")"

                            local text_width, text_height = GuiGetTextDimensions(data.zone_gui, text)

                            GuiBeginAutoBox(data.zone_gui)
                            -- draw at bottom center of screen
                            GuiZSetForNextWidget(data.zone_gui, -200)
                            GuiText(data.zone_gui, (screen_width / 2) - (text_width / 2), screen_height - 12, text)
                            GuiZSetForNextWidget(data.zone_gui, -150)
                            GuiEndAutoBoxNinePiece(data.zone_gui, 2)
                        end
                    elseif (zone_type == "shrinking_step") then
                        if (data.zone_gui == nil) then
                            data.zone_gui = GuiCreate()
                        end

                        GuiStartFrame(data.zone_gui)

                        if (data.using_controller) then
                            GuiOptionsAdd(data.zone_gui, GUI_OPTION.NonInteractive)
                        end

                        -- every step should take step_time seconds to complete
                        if (GameGetFrameNum() - data.last_step_frame > zone_step_interval) then
                            local step_size = zone_speed / step_time
                            data.zone_size = data.zone_size - step_size

                            if (data.zone_size < 0) then
                                data.zone_size = 0
                            end

                            if (GameGetFrameNum() - data.last_step_frame > zone_step_interval + step_time) then
                                data.last_step_frame = GameGetFrameNum()
                            end

                            GlobalsSetValue("arena_area_size", tostring(data.zone_size))
                            GlobalsSetValue("arena_area_size_cap", tostring(data.zone_size + 200))

                            if (not IsPaused()) then
                                local screen_width, screen_height = GuiGetScreenDimensions(data.zone_gui)

                                local text = GameTextGetTranslatedOrNot("$arena_zone_shrinking").." (" ..
                                    math.ceil(data.zone_size) .. "/" .. default_size .. ")"

                                local text_width, text_height = GuiGetTextDimensions(data.zone_gui, text)


                                GuiBeginAutoBox(data.zone_gui)
                                -- draw at bottom center of screen
                                GuiZSetForNextWidget(data.zone_gui, -200)
                                GuiText(data.zone_gui, (screen_width / 2) - (text_width / 2), screen_height - 14, text)
                                GuiZSetForNextWidget(data.zone_gui, -150)
                                GuiEndAutoBoxNinePiece(data.zone_gui, 2)
                            end
                        else
                            if (not IsPaused()) then
                                local screen_width, screen_height = GuiGetScreenDimensions(data.zone_gui)

                                local text = "Zone will shrink in " ..
                                    math.ceil((zone_step_interval - (GameGetFrameNum() - data.last_step_frame)) / 60) ..
                                    " seconds"

                                zone_shrink_time = math.ceil((zone_step_interval - (GameGetFrameNum() - data.last_step_frame)) /
                                    60)

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


                    --message_handler.send.ZoneUpdate(lobby, data.zone_size, zone_shrink_time)
                    networking.send.zone_update(lobby, data.zone_size, zone_shrink_time)

                    -- GamePrint("Zone size: " .. data.zone_size .. " (" .. last_zone_size .. " -> " .. data.zone_size .. ")")
                end

                if ((not steamutils.IsOwner(lobby)) and (not IsPaused()) and data.zone_size ~= nil) then
                    if (data.zone_gui == nil) then
                        data.zone_gui = GuiCreate()
                    end

                    GuiStartFrame(data.zone_gui)

                    if (data.using_controller) then
                        GuiOptionsAdd(data.zone_gui, GUI_OPTION.NonInteractive)
                    end
                    -- GamePrint("???")

                    if (zone_type == "shrinking_Linear") then
                        --GamePrint(tostring(data.zone_size))

                        local screen_width, screen_height = GuiGetScreenDimensions(data.zone_gui)

                        local text = GameTextGetTranslatedOrNot("$arena_zone_shrinking").." (" ..
                            tostring(math.ceil(data.zone_size)) .. "/" .. default_size .. ")"

                        -- GamePrint(text)

                        local text_width, text_height = GuiGetTextDimensions(data.zone_gui, text)

                        GuiBeginAutoBox(data.zone_gui)
                        -- draw at bottom center of screen
                        GuiZSetForNextWidget(data.zone_gui, -200)
                        GuiText(data.zone_gui, (screen_width / 2) - (text_width / 2), screen_height - 12, text)
                        GuiZSetForNextWidget(data.zone_gui, -150)
                        GuiEndAutoBoxNinePiece(data.zone_gui, 2)
                    elseif (zone_type == "shrinking_step") then
                        if (data.shrink_time == 0) then
                            local screen_width, screen_height = GuiGetScreenDimensions(data.zone_gui)

                            local text = GameTextGetTranslatedOrNot("$arena_zone_shrinking").." (" ..
                                tostring(math.ceil(data.zone_size)) .. "/" .. default_size .. ")"

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

                            local text = string.format("$arena_zone_shrink_countdown", tostring(data.shrink_time))--"Zone will shrink in " .. tostring(data.shrink_time) .. " seconds"

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

                if (GameGetFrameNum() % 60 == 0) then
                    ArenaGameplay.DamageZoneCheck(0, 0, data.zone_size, data.zone_size + 200)
                end
            end
        end
    end,
    GetWins = function(lobby, user)
        return tonumber(steam.matchmaking.getLobbyData(lobby, tostring(user) .. "_wins")) or 0
    end,
    WinnerCheck = function(lobby, data)
        --[[
        if(true)then
            return
        end
        ]]

        if(GameHasFlagRun("round_finished"))then
            return
        end

        print("WinnerCheck (gameplay)")

        local alive = data.client.alive and 1 or 0
        local winner = steam.user.getSteamID()
        for k, v in pairs(data.players) do
            if (v.alive) then
                alive = alive + 1
                winner = v.id
            end
        end

        print("Alive count: "..tostring(alive))

        if (alive == 1) then
            GamePrintImportant(string.format(GameTextGetTranslatedOrNot("$arena_winner_text"), steamutils.getTranslatedPersonaName(winner)), GameTextGetTranslatedOrNot("$arena_round_end_text"))

            -- if we are owner, add win to tally
            if (steamutils.IsOwner(lobby)) then
                local winner_key = tostring(winner) .. "_wins"
                local current_wins = tonumber(tonumber(steam.matchmaking.getLobbyData(lobby, winner_key)) or "0")
                steam.matchmaking.setLobbyData(lobby, winner_key, tostring(current_wins + 1))
            end

            GameAddFlagRun("round_finished")

            delay.new(5 * 60, function()
                ArenaGameplay.LoadLobby(lobby, data, false)
            end, function(frames)
                if (frames % 60 == 0) then
                    GamePrint(string.format(GameTextGetTranslatedOrNot("$arena_returning_to_lobby_text"), tostring(math.floor(frames / 60))))
                end
            end)
        elseif (alive == 0) then
            GamePrintImportant(GameTextGetTranslatedOrNot("$arena_tie_text"), GameTextGetTranslatedOrNot("$arena_round_end_text"))

            GameAddFlagRun("round_finished")

            delay.new(5 * 60, function()
                ArenaGameplay.LoadLobby(lobby, data, false)
            end, function(frames)
                if (frames % 60 == 0) then
                    GamePrint(string.format(GameTextGetTranslatedOrNot("$arena_returning_to_lobby_text"), tostring(math.floor(frames / 60))))
                end
            end)
        end
    end,
    KillCheck = function(lobby, data)
        if (GameHasFlagRun("player_died")) then
            local killer = ModSettingGet("killer");
            local username = steamutils.getTranslatedPersonaName(steam.user.getSteamID())

            if (killer == nil) then
                GamePrint(string.format(GameTextGetTranslatedOrNot("$arena_other_player_died"), tostring(username)))
            else
                local killer_id = ArenaGameplay.FindUser(lobby, killer)
                if (killer_id ~= nil) then
                    GamePrint(string.format(GameTextGetTranslatedOrNot("$arena_kill"), tostring(username), steamutils.getTranslatedPersonaName(killer_id))--[[tostring(username) .. " was killed by " .. steamutils.getTranslatedPersonaName(killer_id)]])
                else
                    GamePrint(string.format(GameTextGetTranslatedOrNot("$arena_other_player_died"), tostring(username)))
                end
            end

            --if(data.deaths == 0)then
            GameAddFlagRun("first_death")
            GamePrint(GameTextGetTranslatedOrNot("$arena_compensation"))
            --end

            data.deaths = data.deaths + 1
            data.client.alive = false

            --message_handler.send.Death(lobby, killer)
            networking.send.death(lobby, killer)

            GameRemoveFlagRun("player_died")

            GamePrintImportant(GameTextGetTranslatedOrNot("$arena_player_died"))

            GameSetCameraFree(true)

            data.arena_spectator = true

            player.Lock()
            player.Immortal(true)
            --player.Move(-3000, -3000)

            ArenaGameplay.WinnerCheck(lobby, data)
        end
    end,
    ClearWorld = function()
        local all_entities = EntityGetInRadius(0, 0, math.huge)
        for k, v in pairs(all_entities) do
            if (v ~= GameGetWorldStateEntity() and not EntityHasTag(v, "free_camera_light") --[[ and v ~= GameGetPlayerStatsEntity()]]) then
                if (EntityHasTag(v, "player_unit")) then
                    EntityRemoveTag(v, "player_unit")
                end
                EntityKill(v)
            end
        end
    end,
    SavePlayerData = function(lobby, data, force)
        if ((not GameHasFlagRun("player_unloaded")) and player.Get()) then
            --[[local profile = profiler.new()
            profile:start()]]
            local serialized_player_data, compare_string = player.Serialize()


            if (force or compare_string ~= data.client.player_data_old) then
                steamutils.SetLocalLobbyData(lobby, "player_data", serialized_player_data)

                --print("Backing up Player Data: \n"..serialized_player_data)

                data.client.serialized_player = serialized_player_data
                data.client.player_data_old = compare_string
            end

            --[[profile:stop()

            print("Profiler result: "..tostring(profile:time()) .. "ms")]]

            local match_data = {
                reroll_count = GlobalsGetValue("TEMPLE_PERK_REROLL_COUNT", "0"),
                picked_health = GameHasFlagRun("picked_health"),
                picked_perk = GameHasFlagRun("picked_perk"),
            }

            local serialized = bitser.dumps(match_data)

            if(data.client.match_data ~= serialized)then
                steamutils.SetLocalLobbyData(lobby, "match_data", serialized)

                data.client.match_data = serialized
            end
        end
    end,
    LoadLobby = function(lobby, data, show_message, first_entry)
        ArenaGameplay.GracefulReset(lobby, data)

        data.selected_player = nil
        data.selected_player_name = nil
        data.client.previous_spectate_data = nil
        GameRemoveFlagRun("lock_ready_state")
        GameRemoveFlagRun("can_save_player")
        GameRemoveFlagRun("countdown_completed")
        GameRemoveFlagRun("round_finished")
        show_message = show_message or false
        first_entry = first_entry or false

        np.ComponentUpdatesSetEnabled("CellEaterSystem", false)
        np.ComponentUpdatesSetEnabled("LooseGroundSystem", false)
        np.ComponentUpdatesSetEnabled("BlackHoleSystem", false)
        np.ComponentUpdatesSetEnabled("MagicConvertMaterialSystem", false)


        if (not first_entry) then
            ArenaGameplay.SavePlayerData(lobby, data, true)
            ArenaGameplay.ClearWorld()
        end

        if (data.client.serialized_player) then
            first_entry = false
        end

        --[[
        local current_player = player.Get()

        if(current_player == nil)then
            ArenaGameplay.LoadPlayer(lobby, data)
        end
        ]]
        RunWhenPlayerExists(function()
            if (first_entry and player.Get()) then
                GameDestroyInventoryItems(player.Get())
            end

            player.Immortal(true)
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

        ArenaGameplay.SetReady(lobby, data, false, true)

        data.client.alive = true
        data.client.previous_wand = nil
        data.client.previous_anim = nil
        data.projectile_seeds = {}

        data.current_arena = nil
        ArenaGameplay.ResetDamageZone(lobby, data)
        --data.client.projectile_homing = {}

        -- set state
        data.state = "lobby"

        player.Immortal(true)

        RunWhenPlayerExists(function()
            -- clean and unlock player entity
            player.Clean(first_entry)
            player.Unlock(data)

            GameRemoveFlagRun("player_is_unlocked")

            -- move player to correct position
            player.Move(0, 0)
        end)

        -- get rounds
        local rounds = ArenaGameplay.GetNumRounds()

        if (data.client.player_loaded_from_data) then
            if(GameHasFlagRun("picked_perk"))then
                GameAddFlagRun("skip_perks")
            end
            if(GameHasFlagRun("picked_health"))then
                GameAddFlagRun("skip_health")
            end
            ArenaGameplay.RemoveRound()
        else
            GameRemoveFlagRun("picked_health")
            GameRemoveFlagRun("picked_perk")
        end

        -- Give gold
        local rounds_limited = math.max(0, math.min(math.ceil(rounds / 2), 7))
        local extra_gold = 400 + (70 * (rounds_limited * rounds_limited))

        --print("First spawn gold = "..tostring(data.client.first_spawn_gold))

        arena_log:print("First entry = " .. tostring(first_entry))

        if (first_entry and data.client.first_spawn_gold > 0) then
            extra_gold = data.client.first_spawn_gold
        end

        --GamePrint("You were granted " ..tostring(extra_gold) .. " gold for this round. (Rounds: " .. tostring(rounds) .. ")")
        GamePrint(string.format(GameTextGetTranslatedOrNot("$arena_round_gold"), tostring(extra_gold), tostring(rounds)))

        arena_log:print("Loaded from data: " .. tostring(player_loaded_from_data))

        RunWhenPlayerExists(function()
            if (not data.client.player_loaded_from_data) then
                arena_log:print("Giving gold: " .. tostring(extra_gold))
                player.GiveGold(extra_gold)
            end
        end)


        RunWhenPlayerExists(function()
            -- if we are the owner of the lobby
            if (steamutils.IsOwner(lobby)) then
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
            if (first_entry) then
                player.GiveStartingGear()
                if (((rounds - 1) > 0)) then
                    player.GiveMaxHealth(0.4 * (rounds - 1))
                end
            end

            GameAddFlagRun("can_save_player")

            networking.send.request_perk_update(lobby)
        end)

        --message_handler.send.Unready(lobby, true)

        -- load map
        BiomeMapLoad_KeepPlayer("mods/evaisa.arena/files/scripts/world/map_lobby.lua",
            "mods/evaisa.arena/files/biome/holymountain_scenes.xml")

        -- show message
        if (show_message) then
            GamePrintImportant("$arena_holymountain_enter", "$arena_holymountain_enter_sub")
        end


        -- clean other player's data again because it might have failed for some cursed reason
        ArenaGameplay.CleanMembers(lobby, data)

        -- set ready counter
        ArenaGameplay.ReadyCounter(lobby, data)


        -- print member data
        --print(json.stringify(data))
    end,
    LoadArena = function(lobby, data, show_message)
        ArenaGameplay.SavePlayerData(lobby, data, true)

        GameRemoveFlagRun("can_save_player")

        show_message = show_message or false

        np.ComponentUpdatesSetEnabled("CellEaterSystem", true)
        np.ComponentUpdatesSetEnabled("LooseGroundSystem", true)
        np.ComponentUpdatesSetEnabled("BlackHoleSystem", true)
        np.ComponentUpdatesSetEnabled("MagicConvertMaterialSystem", true)

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

        local members = steamutils.getLobbyMembers(lobby)

        for _, member in pairs(members) do
            if (member.id ~= steam.user.getSteamID() and data.players[tostring(member.id)] ~= nil) then
                data.players[tostring(member.id)].alive = true
            end
        end

        --message_handler.send.SendPerks(lobby)
        networking.send.perk_update(lobby, data)

        ArenaGameplay.PreventFiring()

        -- load map
        local arena = arena_list[data.random.range(1, #arena_list)]

        data.current_arena = arena

        BiomeMapLoad_KeepPlayer(arena.biome_map, arena.pixel_scenes)

        RunWhenPlayerExists(function()
            player.Lock()

            -- move player to correct position
            data.spawn_point = arena.spawn_points[data.random.range(1, #arena.spawn_points)]

            ArenaGameplay.LoadClientPlayers(lobby, data)

            --GamePrint("Loading arena")

            GameAddFlagRun("can_save_player")
        end)
    end,
    ReadyCheck = function(lobby, data)
        --print("Players ready: "..tostring(ArenaGameplay.ReadyAmount(data, lobby)))
        return ArenaGameplay.TotalPlayers(lobby) > 0 and (ArenaGameplay.ReadyAmount(data, lobby) >= ArenaGameplay.TotalPlayers(lobby))
    end,
    SetReady = function(lobby, data, ready, silent)
        if (ready == nil) then
            return
        end

        --print("SetReady called: "..tostring(ready))

        if (ready) then
            GamePrint(GameTextGetTranslatedOrNot("$arena_self_ready"))
        else
            GamePrint(GameTextGetTranslatedOrNot("$arena_self_unready"))
            GameRemoveFlagRun("ready_check")
        end

        networking.send.ready(lobby, ready, silent or false)
        data.client.ready = ready
        if (steamutils.IsOwner(lobby)) then
            steam.matchmaking.setLobbyData(lobby, tostring(steam.user.getSteamID()) .. "_ready", tostring(ready))
        end
    end,
    CleanMembers = function(lobby, data)
        local members = steamutils.getLobbyMembers(lobby)

        for _, member in pairs(members) do
            if (member.id ~= steam.user.getSteamID() and data.players[tostring(member.id)] ~= nil) then
                data.players[tostring(member.id)]:Clean(lobby)
            end
        end
    end,
    UpdateTweens = function(lobby, data)
        local members = steamutils.getLobbyMembers(lobby)

        local validMembers = {}

        for _, member in pairs(members) do
            local memberid = tostring(member.id)

            validMembers[memberid] = true
        end

        -- iterate active tweens backwards and update
        for i = #data.tweens, 1, -1 do
            local tween = data.tweens[i]
            if (tween) then
                if (validMembers[tween.id] == nil) then
                    table.remove(data.tweens, i)
                else
                    if (tween:update()) then
                        table.remove(data.tweens, i)
                    end
                end
            end
        end
    end,
    RunReadyCheck = function(lobby, data)
        if (steamutils.IsOwner(lobby)) then
            -- check if all players are ready
            if (ArenaGameplay.ReadyCheck(lobby, data) and ArenaLoadCountdown == nil) then
                GameAddFlagRun("lock_ready_state")
                networking.send.lock_ready_state(lobby)
                ArenaLoadCountdown = GameGetFrameNum() + 62
            end

            if (ArenaLoadCountdown ~= nil and GameGetFrameNum() >= ArenaLoadCountdown) then
                ArenaLoadCountdown = nil

                -- still ready? start game.
                if (ArenaGameplay.ReadyCheck(lobby, data)) then
                    if(steamutils.IsSpectator(lobby))then
                        spectator_handler.LoadArena(lobby, data, true)
                    else
                        ArenaGameplay.LoadArena(lobby, data, true)
                    end

                    --message_handler.send.EnterArena(lobby)
                    networking.send.enter_arena(lobby)
                end
            end
        end
    end,
    LobbyUpdate = function(lobby, data)
        -- update ready counter
        if (data.ready_counter ~= nil) then
            if (not IsPaused()) then
                data.ready_counter:appy_offset(9, 28)
            else
                data.ready_counter:appy_offset(9, 9)
            end


            data.ready_counter:update()
        end

        --if (GameGetFrameNum() % 2 == 0) then
            networking.send.character_position(lobby, data, true)
        --end
        networking.send.wand_update(lobby, data, nil, nil, true)
        networking.send.input_update(lobby, true)
        networking.send.switch_item(lobby, data, nil, nil, true)
        networking.send.animation_update(lobby, data, true)
        networking.send.player_data_update(lobby, data, true)
        networking.send.spectate_data(lobby, data, nil, false)

        GameAddFlagRun("Immortal")

        ArenaGameplay.RunReadyCheck(lobby, data)

        if (GameHasFlagRun("player_ready")) then
            GameRemoveFlagRun("player_ready")

            ArenaGameplay.SetReady(lobby, data, true)
        end

        if (GameHasFlagRun("player_unready")) then
            GameRemoveFlagRun("player_unready")

            ArenaGameplay.SetReady(lobby, data, false)
        end

        if (GameGetFrameNum() % 5 == 0) then
            -- message_handler.send.UpdateHp(lobby, data)
            networking.send.health_update(lobby, data)
            --message_handler.send.SendPerks(lobby)
            networking.send.perk_update(lobby, data)
        end
    end,
    UpdateHealthbars = function(data)
        for k, v in pairs(data.players) do
            if (v.hp_bar) then
                if (v.entity ~= nil and EntityGetIsAlive(v.entity)) then
                    local x, y = EntityGetTransform(v.entity)
                    y = y + 10
                    v.hp_bar:update(x, y)
                end
            end
        end
    end,
    CheckAllPlayersLoaded = function(lobby, data)
        local ready = not data.preparing
        for k, v in pairs(data.players) do
            if not v.loaded then
                ready = false
                break
            end
        end
        return ready
    end,
    FightCountdown = function(lobby, data)
        player.Unlock(data)
        data.countdown = countdown.create({
            "mods/evaisa.arena/files/sprites/ui/countdown/ready.png",
            "mods/evaisa.arena/files/sprites/ui/countdown/3.png",
            "mods/evaisa.arena/files/sprites/ui/countdown/2.png",
            "mods/evaisa.arena/files/sprites/ui/countdown/1.png",
            "mods/evaisa.arena/files/sprites/ui/countdown/fight.png",
        }, 60, function()
            print("Countdown completed")
            data.countdown:cleanup()
            data.countdown = nil
            --message_handler.send.Unlock(lobby)
            networking.send.unlock(lobby)
            GameAddFlagRun("countdown_completed")
            if(not steamutils.IsSpectator(lobby))then
                player.Immortal(false)
            end
            ArenaGameplay.AllowFiring(data)

            arena_log:print("Completed countdown.")

            --message_handler.send.RequestWandUpdate(lobby, data)
            networking.send.request_wand_update(lobby)
        end)
    end,
    SpawnClientPlayer = function(lobby, user, data, x, y)
        local client = EntityLoad("mods/evaisa.arena/files/entities/client.xml", x or -1000, y or -1000)
        EntitySetName(client, tostring(user))
        local usernameSprite = EntityGetFirstComponentIncludingDisabled(client, "SpriteComponent", "username")
        local name = steamutils.getTranslatedPersonaName(user)
        ComponentSetValue2(usernameSprite, "text", name)
        ComponentSetValue2(usernameSprite, "offset_x", string.len(name) * (1.8))
        data.players[tostring(user)].entity = client
        data.players[tostring(user)].alive = true

        arena_log:print("Spawned client player for " .. name)

        if (data.players[tostring(user)].perks) then
            for k, v in ipairs(data.players[tostring(user)].perks) do
                local perk = v[1]
                local count = v[2]

                for i = 1, count do
                    entity.GivePerk(client, perk, i, true)
                end
            end
        end

        return client
    end,
    CheckPlayer = function(lobby, user, data)
        if (not data.players[tostring(user)].entity and data.players[tostring(user)].alive) then
            --ArenaGameplay.SpawnClientPlayer(lobby, user, data)
            return false
        end
        return true
    end,
    LoadClientPlayers = function(lobby, data)
        local members = steamutils.getLobbyMembers(lobby)

        for _, member in pairs(members) do
            if (member.id ~= steam.user.getSteamID() and data.players[tostring(member.id)].entity) then
                data.players[tostring(member.id)]:Clean(lobby)
            end

            --[[if(member.id ~= steam.user.getSteamID())then
                print(json.stringify(data.players[tostring(member.id)]))
            end]]
            if (member.id ~= steam.user.getSteamID() and data.players[tostring(member.id)].entity == nil) then
                --GamePrint("Loading player " .. tostring(member.id))
                ArenaGameplay.SpawnClientPlayer(lobby, member.id, data)
            end
        end
    end,
    ClosestPlayer = function(x, y)
        closest = EntityGetClosestWithTag(x, y, "client")
        if (closest ~= nil) then
            return EntityGetName(closest)
        end

        return nil
    end,
    ArenaUpdate = function(lobby, data)
        if (data.preparing) then
            local spawn_points = EntityGetWithTag("spawn_point") or {}
            if (spawn_points ~= nil and #spawn_points > 0) then
                data.ready_for_zone = true

                local spawn_point = spawn_points[Random(1, #spawn_points)]
                local x, y = EntityGetTransform(spawn_point)

                local spawn_loaded = DoesWorldExistAt(x - 100, y - 100, x + 100, y + 100)

                player.Move(x, y)

                arena_log:print("Arena loaded? " .. tostring(spawn_loaded))

                local in_bounds = ArenaGameplay.IsInBounds(0, 0, 400)

                if (not in_bounds) then
                    arena_log:print("Game tried to spawn player out of bounds, retrying...")
                    GamePrint("Game attempted to spawn you out of bounds, retrying...")
                end

                if (spawn_loaded and in_bounds) then
                    data.preparing = false


                    --GamePrint("Spawned!!")

                    if (not steamutils.IsOwner(lobby)) then
                        networking.send.arena_loaded(lobby)
                        --message_handler.send.Loaded(lobby)
                    end

                    --message_handler.send.Health(lobby)
                    networking.send.health_update(lobby, data, true)
                end
            else
                player.Move(data.spawn_point.x, data.spawn_point.y)
            end
        end
        local player_entities = {}
        for k, v in pairs(data.players) do
            if (v.entity ~= nil and EntityGetIsAlive(v.entity)) then
                table.insert(player_entities, v.entity)
            end
        end
        if (not IsPaused() and GameHasFlagRun("player_is_unlocked") and (not GameHasFlagRun("no_shooting"))) then
            game_funcs.RenderOffScreenMarkers(player_entities)
            game_funcs.RenderAboveHeadMarkers(player_entities, 0, 27)
            ArenaGameplay.UpdateHealthbars(data)
        end

        if (GameHasFlagRun("player_is_unlocked") and (not GameHasFlagRun("no_shooting"))) then
            ArenaGameplay.DamageZoneHandler(lobby, data, true)
        else
            ArenaGameplay.DamageZoneHandler(lobby, data, false)
        end

        local player_entity = player.Get()

        if (steamutils.IsOwner(lobby)) then
            if (player_entity ~= nil and (not data.players_loaded and ArenaGameplay.CheckAllPlayersLoaded(lobby, data))) then
                data.players_loaded = true
                arena_log:print("All players loaded")
                --message_handler.send.StartCountdown(lobby)
                networking.send.start_countdown(lobby)
                ArenaGameplay.FightCountdown(lobby, data)
            end
        end
        if (data.countdown ~= nil) then
            data.countdown:update()
        end

        if (GameGetFrameNum() % 2 == 0) then
            networking.send.character_position(lobby, data)
        end

        if (GameHasFlagRun("took_damage")) then
            GameRemoveFlagRun("took_damage")
            --message_handler.send.Health(lobby)
            networking.send.health_update(lobby, data, true)
        end
        if (data.players_loaded) then
            --message_handler.send.WandUpdate(lobby, data)
            networking.send.wand_update(lobby, data)

            --[[if(GameGetFrameNum() % 60 == 0)then
                networking.send.wand_update(lobby, data, nil, true)
                networking.send.switch_item(lobby, data, nil, true)
            end]]
            if (GameGetFrameNum() % 2 == 0 and GameHasFlagRun("countdown_completed")) then
                networking.send.unlock(lobby)
            end


            --message_handler.send.SwitchItem(lobby, data)
            networking.send.switch_item(lobby, data)
            --message_handler.send.Kick(lobby, data)
            --message_handler.send.AnimationUpdate(lobby, data)
            networking.send.animation_update(lobby, data)
            networking.send.player_data_update(lobby, data)
            --message_handler.send.AimUpdate(lobby)
            --message_handler.send.SyncControls(lobby, data)
            networking.send.input_update(lobby)

            ArenaGameplay.CheckFiringBlock(lobby, data)
        end
    end,
    ValidatePlayers = function(lobby, data)
        for k, v in pairs(data.players) do
            local playerid = ArenaGameplay.FindUser(lobby, k)

            if (playerid == nil) then
                v:Clean(lobby)
                data.players[k] = nil
                --local name = steamutils.getTranslatedPersonaName(playerid)
                GamePrint(string.format(GameTextGetTranslatedOrNot("$arena_player_left") ,tostring(lobby_member_names[k])))

                -- if we are the last player, unready
                if(not data.spectator_mode)then
                    if (steam.matchmaking.getNumLobbyMembers(lobby) == 1) then
                        ArenaGameplay.SetReady(lobby, data, false, true)
                    end
                end

                if (steamutils.IsOwner(lobby)) then
                    local winner_key = tostring(k) .. "_wins"
                    steam.matchmaking.deleteLobbyData(lobby, winner_key)
                end

                lobby_member_names[k] = nil
                if (data.state == "arena") then
                    if(not data.spectator_mode)then
                        ArenaGameplay.WinnerCheck(lobby, data) 
                    else
                        spectator_handler.WinnerCheck(lobby, data)
                    end
                end
            end
        end
    end,
    GetAlivePlayers = function(lobby, data)
        local alive_players = {}
        for k, v in pairs(data.players) do
            if (v.entity ~= nil and EntityGetIsAlive(v.entity)) then
                table.insert(alive_players, v)
            end
        end
        return alive_players
    end,
    Update = function(lobby, data)
        SpectatorMode.SpectateUpdate(lobby, data)
        --if(GameGetFrameNum() % 60 == 0)then
        --message_handler.send.Handshake(lobby)
        --end

        --[[local chunk_loaders = EntityGetWithTag("chunk_loader") or {}
        for k, v in pairs(chunk_loaders)do
            local chunk_loader_x, chunk_loader_y = EntityGetTransform(v)
            game_funcs.LoadRegion(chunk_loader_x, chunk_loader_y, 1000, 1000)
        end]]
        for k, v in pairs(data.players) do
            if (v.entity ~= nil and EntityGetIsAlive(v.entity)) then
                local controls = EntityGetFirstComponentIncludingDisabled(v.entity, "ControlsComponent")
                if (controls) then
                    ComponentSetValue2(controls, "mButtonDownKick", false)
                    ComponentSetValue2(controls, "mButtonDownFire", false)
                    ComponentSetValue2(controls, "mButtonDownFire2", false)
                    ComponentSetValue2(controls, "mButtonDownLeftClick", false)
                    ComponentSetValue2(controls, "mButtonDownRightClick", false)
                end
            end
        end

        if (data.state == "lobby") then
            networking.send.sync_wand_stats(lobby, data, true)
            ArenaGameplay.LobbyUpdate(lobby, data)
        elseif (data.state == "arena") then
            -- message_handler.send.SyncWandStats(lobby, data)
            networking.send.sync_wand_stats(lobby, data)
            ArenaGameplay.ArenaUpdate(lobby, data)
            ArenaGameplay.KillCheck(lobby, data)
        end
        if (GameHasFlagRun("no_shooting")) then
            ArenaGameplay.CancelFire(lobby, data)
        end
        ArenaGameplay.UpdateTweens(lobby, data)
        if (GameGetFrameNum() % 60 == 0) then
            ArenaGameplay.ValidatePlayers(lobby, data)
        end
    end,
    LateUpdate = function(lobby, data)
        if (data.state == "arena") then
            ArenaGameplay.KillCheck(lobby, data)


            --
        --[[else
            data.client.projectile_rng_stack = {}
            data.client.projectiles_fired = 0]]
        end
        local current_player = player.Get()

        if (data.client.projectiles_fired ~= nil and data.client.projectiles_fired > 0) then
            local special_seed = tonumber(GlobalsGetValue("player_rng", "0"))
            --local cast_state = GlobalsGetValue("player_cast_state") or nil

            --print(tostring(cast_state))

            --GamePrint("Sending special seed:"..tostring(special_seed))
            --message_handler.send.WandFired(lobby, data.client.projectile_rng_stack, special_seed, cast_state)
            if(data.state == "arena")then
                networking.send.fire_wand(lobby, data.client.projectile_rng_stack, special_seed)
            else
                networking.send.fire_wand(lobby, data.client.projectile_rng_stack, special_seed, true)
            end
            data.client.projectiles_fired = 0
            data.client.projectile_rng_stack = {}
        end


        GlobalsSetValue("wand_fire_count", "0")


        if ((not GameHasFlagRun("player_unloaded")) and current_player == nil) then
            ArenaGameplay.LoadPlayer(lobby, data)
            arena_log:print("Player is missing, spawning player.")
        else
            if (GameGetFrameNum() % 30 == 0 and GameHasFlagRun("can_save_player")) then
                ArenaGameplay.SavePlayerData(lobby, data)
            end
        end


        if (data.current_player ~= current_player) then
            data.current_player = current_player
            if (current_player ~= nil) then
                np.RegisterPlayerEntityId(current_player)
            end
        end

        if (GameHasFlagRun("in_hm") and current_player) then
            player.Move(0, 0)
            GameRemoveFlagRun("in_hm")
        end

        if (GameGetFrameNum() % 5 == 0) then
            -- if we are host
            if (steamutils.IsOwner(lobby)) then
                ArenaGameplay.SendGameData(lobby, data)
            end
        end

        for k, v in pairs(data.players) do
            if (v.entity ~= nil and EntityGetIsAlive(v.entity)) then
                local controls = EntityGetFirstComponentIncludingDisabled(v.entity, "ControlsComponent")
                if (controls) then
                    if (ComponentGetValue2(controls, "mButtonDownKick") == false) then
                        data.players[k].controls.kick = false
                    end
                    -- mButtonDownFire
                    if (ComponentGetValue2(controls, "mButtonDownFire") == false) then
                        data.players[k].controls.fire = false
                    end
                    -- mButtonDownFire2
                    if (ComponentGetValue2(controls, "mButtonDownFire2") == false) then
                        data.players[k].controls.fire2 = false
                    end
                    -- mButtonDownLeft
                    if (ComponentGetValue2(controls, "mButtonDownLeftClick") == false) then
                        data.players[k].controls.leftClick = false
                    end
                    -- mButtonDownRight
                    if (ComponentGetValue2(controls, "mButtonDownRightClick") == false) then
                        data.players[k].controls.rightClick = false
                    end
                end
            end
        end

        local current_player = player.Get()

        if ((not GameHasFlagRun("player_unloaded")) and current_player ~= nil and EntityGetIsAlive(current_player)) then
            --print("Running player function queue")
            -- run playerRunQueue
            for i = 1, #playerRunQueue do
                local func = playerRunQueue[i]
                arena_log:print("Ran item #" .. i .. " in playerRunQueue")
                func()
            end
            playerRunQueue = {}
        end
    end,
    OnProjectileFired = function(lobby, data, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message, unknown1, multicast_index, unknown3)
        --if (data.state == "arena") then
            local playerEntity = player.Get()
            if (playerEntity ~= nil) then
                if (playerEntity == shooter_id) then
                    local projectileComponent = EntityGetFirstComponentIncludingDisabled(projectile_id,
                        "ProjectileComponent")

                    local who_shot            = ComponentGetValue2(projectileComponent, "mWhoShot")
                    local entity_that_shot    = ComponentGetValue2(projectileComponent, "mEntityThatShot")
                    if (entity_that_shot == 0 and multicast_index ~= -1 and unknown3 == 0) then
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
                        if (data.projectile_seeds[entity_that_shot]) then
                            local new_seed = data.projectile_seeds[entity_that_shot] + 25
                            np.SetProjectileSpreadRNG(new_seed)
                            data.projectile_seeds[entity_that_shot] = data.projectile_seeds[entity_that_shot] + 10
                            data.projectile_seeds[projectile_id] = new_seed
                        end
                    end
                end
            end
            if (EntityGetName(shooter_id) ~= nil and tonumber(EntityGetName(shooter_id))) then
                if (data.players[EntityGetName(shooter_id)]) then
                    --print("whar")

                    --GamePrint("Setting RNG: "..tostring(arenaPlayerData[EntityGetName(shooter_id)].next_rng))
                    local projectileComponent = EntityGetFirstComponentIncludingDisabled(projectile_id,
                        "ProjectileComponent")

                    local who_shot            = ComponentGetValue2(projectileComponent, "mWhoShot")
                    local entity_that_shot    = ComponentGetValue2(projectileComponent, "mEntityThatShot")
                    if (entity_that_shot == 0 and multicast_index ~= -1 and unknown3 == 0) then
                        local rng = 0
                        if (#(data.players[EntityGetName(shooter_id)].projectile_rng_stack) > 0) then
                            -- set rng to first in stack, remove
                            rng = table.remove(data.players[EntityGetName(shooter_id)].projectile_rng_stack, 1)
                        end
                        --GamePrint("Setting client spread rng: "..tostring(rng))

                        np.SetProjectileSpreadRNG(rng)

                        data.players[EntityGetName(shooter_id)].next_rng = rng + 1
                    else
                        if (data.projectile_seeds[entity_that_shot]) then
                            local new_seed = data.projectile_seeds[entity_that_shot] + 25
                            np.SetProjectileSpreadRNG(new_seed)
                            data.projectile_seeds[entity_that_shot] = data.projectile_seeds[entity_that_shot] + 10
                        end
                    end
                end
            end
        --end
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
    OnProjectileFiredPost = function(lobby, data, shooter_id, projectile_id, rng, position_x, position_y, target_x,
                                     target_y, send_message, unknown1, multicast_index, unknown3)
        --[[local projectileComp = EntityGetFirstComponentIncludingDisabled(projectile_id, "ProjectileComponent")
        if(projectileComp ~= nil)then
            local who_shot = ComponentGetValue2(projectileComp, "mWhoShot")
            --GamePrint("who_shot: "..tostring(who_shot))
        end]]
        local homingComponents = EntityGetComponentIncludingDisabled(projectile_id, "HomingComponent")

        local shooter_x, shooter_y = EntityGetTransform(shooter_id)

        if (homingComponents ~= nil) then
            for k, v in pairs(homingComponents) do
                local target_who_shot = ComponentGetValue2(v, "target_who_shot")
                if (target_who_shot == false) then
                    if (EntityHasTag(shooter_id, "client")) then
                        -- find closest player which isn't us
                        local closest_player = nil
                        local distance = 9999999
                        local clients = EntityGetWithTag("client")
                        -- add local player to list
                        if (player.Get()) then
                            table.insert(clients, player.Get())
                        end

                        for k, v in pairs(clients) do
                            if (v ~= shooter_id) then
                                if (closest_player == nil) then
                                    closest_player = v
                                else
                                    local x, y = EntityGetTransform(v)
                                    local dist = math.abs(x - shooter_x) + math.abs(y - shooter_y)
                                    if (dist < distance) then
                                        distance = dist
                                        closest_player = v
                                    end
                                end
                            end
                        end

                        if (closest_player) then
                            ComponentSetValue2(v, "predefined_target", closest_player)
                            ComponentSetValue2(v, "target_tag", "mortal")
                        end
                    else
                        local closest_player = nil
                        local distance = 9999999
                        local clients = EntityGetWithTag("client")

                        for k, v in pairs(clients) do
                            if (v ~= shooter_id) then
                                if (closest_player == nil) then
                                    closest_player = v
                                else
                                    local x, y = EntityGetTransform(v)
                                    local dist = math.abs(x - shooter_x) + math.abs(y - shooter_y)
                                    if (dist < distance) then
                                        distance = dist
                                        closest_player = v
                                    end
                                end
                            end
                        end

                        if (closest_player) then
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
