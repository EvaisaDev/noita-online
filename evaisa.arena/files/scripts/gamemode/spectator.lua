

SpectatorMode = {
    LoadLobby = function(lobby, data, show_message)

        print("Loading lobby through spectator system.")

        ArenaGameplay.GracefulReset(lobby, data)

        data.arena_spectator = false
        data.selected_player = nil
        data.selected_player_name = nil
        data.lobby_spectated_player = nil
        data.spectator_lobby_loaded = false

        GameRemoveFlagRun("countdown_completed")
        show_message = show_message or false

        np.ComponentUpdatesSetEnabled("CellEaterSystem", false)
        np.ComponentUpdatesSetEnabled("LooseGroundSystem", false)
        np.ComponentUpdatesSetEnabled("BlackHoleSystem", false)
        np.ComponentUpdatesSetEnabled("MagicConvertMaterialSystem", false)

        ArenaGameplay.ClearWorld()

        -- clean other player's data
        ArenaGameplay.CleanMembers(lobby, data)

        -- manage flags
        GameRemoveFlagRun("player_ready")
        GameRemoveFlagRun("ready_check")
        GameRemoveFlagRun("player_unloaded")

        -- destroy active tweens
        data.tweens = {}

        -- clean local data

        --ArenaGameplay.SetReady(lobby, data, false, true)

        data.client.alive = true
        data.client.previous_wand = nil
        data.client.previous_anim = nil
        data.projectile_seeds = {}

        data.current_arena = nil
        ArenaGameplay.ResetDamageZone(lobby, data)
        --data.client.projectile_homing = {}

        -- set state
        data.state = "lobby"

        --[[player.Immortal(true)

        RunWhenPlayerExists(function()
            -- clean and unlock player entity
            player.Clean(first_entry)
            player.Unlock(data)

            GameRemoveFlagRun("player_is_unlocked")

            -- move player to correct position
            player.Move(0, 0)
        end)
        ]]

        local rounds = ArenaGameplay.GetNumRounds()

        -- Give gold
        local rounds_limited = math.max(0, math.min(math.ceil(rounds / 2), 7))
        local extra_gold = 400 + (70 * (rounds_limited * rounds_limited))

        if (steamutils.IsOwner(lobby)) then
            -- get the gold count from the lobby
            local gold = tonumber(steam.matchmaking.getLobbyData(lobby, "total_gold")) or 0
            -- add the new gold
            gold = gold + extra_gold
            -- set the new gold count
            steam.matchmaking.setLobbyData(lobby, "total_gold", tostring(gold))
        end

        if (not data.rejoined) then
            ArenaGameplay.AddRound()
        end

        networking.send.request_perk_update(lobby)

        data.spectator_entity = EntityLoad("mods/evaisa.arena/files/entities/spectator_entity.xml", 0, 0)
        np.RegisterPlayerEntityId(data.spectator_entity)

        BiomeMapLoad_KeepPlayer("mods/evaisa.arena/files/scripts/world/map_lobby_spectator.lua",
            "mods/evaisa.arena/files/biome/holymountain_scenes.xml")

        -- clean other player's data again because it might have failed for some cursed reason
        ArenaGameplay.CleanMembers(lobby, data)

        -- set ready counter
        ArenaGameplay.ReadyCounter(lobby, data)

        GameSetCameraFree(true)

    end,
    LoadArena = function(lobby, data, show_message)
        show_message = show_message or false

        np.ComponentUpdatesSetEnabled("CellEaterSystem", true)
        np.ComponentUpdatesSetEnabled("LooseGroundSystem", true)
        np.ComponentUpdatesSetEnabled("BlackHoleSystem", true)

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
        data.arena_spectator = true

        local members = steamutils.getLobbyMembers(lobby)

        for _, member in pairs(members) do
            if (member.id ~= steam.user.getSteamID() and data.players[tostring(member.id)] ~= nil) then
                data.players[tostring(member.id)].alive = true
            end
        end

        ArenaGameplay.PreventFiring()

        -- load map
        local arena = arena_list[data.random.range(1, #arena_list)]

        data.current_arena = arena

        BiomeMapLoad_KeepPlayer(arena.biome_map, arena.pixel_scenes)


    end,
    UpdateSpectatorEntity = function(lobby, data)
        if(data.spectator_entity == nil or not EntityGetIsAlive(data.spectator_entity))then
            data.spectator_entity = EntityLoad("mods/evaisa.arena/files/entities/spectator_entity.xml", 0, 0)
            np.RegisterPlayerEntityId(data.spectator_entity)
        end
        
        if(data.spectator_entity)then
            local camera_x, camera_y = GameGetCameraPos()
            EntitySetTransform(data.spectator_entity, camera_x, camera_y)
            EntityApplyTransform(data.spectator_entity, camera_x, camera_y)
        end
    end,
    SpectatorText = function(lobby, data)
        if (data.spectator_gui_entity == nil or not EntityGetIsAlive(data.spectator_gui_entity)) then
            data.spectator_gui_entity = EntityLoad("mods/evaisa.arena/files/entities/misc/spectator_text.xml")

            EntitySetTransform(data.spectator_gui_entity, 0, 0, 0, 0.25, 0.25)
        end

        if (data.spectator_text_gui == nil) then
            data.spectator_text_gui = GuiCreate()
        end

        local camera_x, camera_y = GameGetCameraPos()

        
        local screen_text_width, screen_text_height = GuiGetScreenDimensions(data.spectator_text_gui)

        local text = GameTextGetTranslatedOrNot("$arena_spectating_text")

        if (data.selected_player_name ~= nil) then
            text = string.format(text, data.selected_player_name)
        else
            text = string.format(text, "")
        end


        local font_width, font_height = data.big_font:GetTextDimensions(text, 0.25, 0.25)

        local text_sprite_component = EntityGetFirstComponentIncludingDisabled(data.spectator_gui_entity,
            "SpriteComponent")

        ComponentSetValue2(text_sprite_component, "text", text)
        ComponentSetValue2(text_sprite_component, "transform_offset", screen_text_width / 2 - font_width / 2, 0)

        EntityRefreshSprite(data.spectator_gui_entity, text_sprite_component)
    end,
    SpectateUpdate = function(lobby, data)
        if (data.arena_spectator) then

            SpectatorMode.SpectatorText(lobby, data)

            if (data.spectator_gui == nil) then
                data.spectator_gui = GuiCreate()
            end

            local camera_x, camera_y = GameGetCameraPos()

            GuiStartFrame(data.spectator_gui)

            --GuiOptionsAdd(data.spectator_gui, GUI_OPTION.NonInteractive)
            --GuiOptionsAdd(data.spectator_gui, GUI_OPTION.NoPositionTween)

            local id = 39582
            local function new_id()
                id = id + 1
                return id
            end

            local screen_width, screen_height = GuiGetScreenDimensions(data.spectator_gui)

            --GamePrint("Spectator mode")
            if (data.selected_player ~= nil) then
                local client_entity = data.selected_player
                if (client_entity ~= nil and EntityGetIsAlive(client_entity)) then
                    local x, y = EntityGetTransform(client_entity)

                    if (x ~= nil and y ~= nil) then
                        -- camera smoothing
                        local camera_speed = 0.1

                        local camera_x_diff = x - camera_x
                        local camera_y_diff = y - camera_y
                        local camera_x_new = camera_x + camera_x_diff * camera_speed
                        local camera_y_new = camera_y + camera_y_diff * camera_speed
                        GameSetCameraPos(camera_x_new, camera_y_new)
                    else
                        data.selected_player = nil
                        data.selected_player_name = nil
                    end
                else
                    data.selected_player = nil
                    data.selected_player_name = nil
                end
            end

            local keys_pressed = {
                w = input:WasKeyPressed("w"),
                a = input:WasKeyPressed("a"),
                s = input:WasKeyPressed("s"),
                d = input:WasKeyPressed("d"),
                q = input:WasKeyPressed("q"),
                e = input:WasKeyPressed("e"),
            }

            local stick_x, stick_y = input:GetGamepadAxis("left_stick")
            local r_stick_x, r_stick_y = input:GetGamepadAxis("right_stick")
            local left_trigger = input:GetGamepadAxis("left_trigger")
            local right_trigger = input:GetGamepadAxis("right_trigger")

            local left_bumper = input:WasGamepadButtonPressed("left_shoulder")
            local right_bumper = input:WasGamepadButtonPressed("right_shoulder")

            local right_trigger_pressed = right_trigger >= 0.5 and data.spectator_quick_switch_trigger < 0.5
            
            data.spectator_quick_switch_trigger = right_trigger

            if (not GameHasFlagRun("chat_input_hovered")) then

                local camera_speed = tonumber(MagicNumbersGetValue("DEBUG_FREE_CAMERA_SPEED")) or 2
                local movement_x = (stick_x * (camera_speed * (1 + (right_trigger * 5))))
                local movement_y = (stick_y * (camera_speed * (1 + (right_trigger * 5))))

                local stick_average = ((stick_x + stick_y) / 2)

                if(stick_average >= 0.1 or stick_average <= -0.1)then
                    --arena_log:print("x_move: "..tostring(movement_x)..", y_move: "..tostring(movement_y))

                    GameSetCameraPos(camera_x + movement_x, camera_y + movement_y)
                end

                if (keys_pressed.w or keys_pressed.a or keys_pressed.s or keys_pressed.d or stick_average >= 0.1 or stick_average <= -0.1) then
                    data.selected_player = nil
                    data.selected_player_name = nil
                end

                if (keys_pressed.q or left_bumper) then
                    -- GamePrint("Q pressed")
                    local players = ArenaGameplay.GetAlivePlayers(lobby, data)
                    local player_count = #players
                    if (player_count > 0) then
                        local selected_index = 1
                        if (data.selected_player ~= nil) then
                            for k, v in ipairs(players) do
                                if (v.entity == data.selected_player) then
                                    selected_index = k
                                    break
                                end
                            end
                        end
                        selected_index = selected_index - 1
                        if (selected_index < 1) then
                            selected_index = player_count
                        end
                        data.selected_player = players[selected_index].entity
                        arena_log:print("Spectating player: " .. EntityGetName(data.selected_player))

                        local player = ArenaGameplay.FindUser(lobby, EntityGetName(data.selected_player))

                        data.selected_player_name = "Unknown Player"
                        if (player ~= nil) then
                            data.selected_player_name = steamutils.getTranslatedPersonaName(player)
                        end
                    end
                end

                if (keys_pressed.e or right_bumper) then
                    -- GamePrint("E pressed")
                    local players = ArenaGameplay.GetAlivePlayers(lobby, data)
                    local player_count = #players
                    if (player_count > 0) then
                        local selected_index = 1
                        if (data.selected_player ~= nil) then
                            for k, v in ipairs(players) do
                                if (v.entity == data.selected_player) then
                                    selected_index = k
                                    break
                                end
                            end
                        end
                        selected_index = selected_index + 1
                        if (selected_index > player_count) then
                            selected_index = 1
                        end
                        data.selected_player = players[selected_index].entity
                        arena_log:print("Spectating player: " .. EntityGetName(data.selected_player))

                        local player = ArenaGameplay.FindUser(lobby, EntityGetName(data.selected_player))

                        data.selected_player_name = "Unknown Player"
                        if (player ~= nil) then
                            data.selected_player_name = steamutils.getTranslatedPersonaName(player)
                        end
                    end
                end

                if(input:IsKeyDown("space") or left_trigger > 0.5)then
                    local circle_image = "mods/evaisa.arena/files/sprites/ui/spectator/circle_selection-2.png"
                    --local inner_circle_image = "mods/evaisa.arena/files/sprites/ui/spectator/circle_selection_inner.png"
                    local circle_width, circle_height = GuiGetImageDimensions(data.spectator_gui, circle_image)
                    local circle_x = screen_width / 2 - circle_width / 2
                    local circle_y = screen_height / 2 - circle_height / 2
                    GuiImage(data.spectator_gui, new_id(), circle_x, circle_y, circle_image, 0.2, 1, 1)
                    --GuiImage(data.spectator_gui, new_id(), circle_x, circle_y, inner_circle_image, 0.4, 1, 1)

                    local marker_distance_from_center = 16

                    local camera_x, camera_y = GameGetCameraPos()
                    local mouse_x, mouse_y = DEBUG_GetMouseWorld()
                    
                    -- get mouse direction
                    local x_diff = mouse_x - camera_x
                    local y_diff = mouse_y - camera_y
                    local dist = math.sqrt(x_diff * x_diff + y_diff * y_diff)
                    local aim_x, aim_y = x_diff / dist, y_diff / dist

                    if(GameGetIsGamepadConnected())then
                        aim_x = r_stick_x
                        aim_y = r_stick_y
                    end
                    
                    local player_marker = "mods/evaisa.arena/files/sprites/ui/spectator/marker-2.png"
                    local selected_player_marker = "mods/evaisa.arena/files/sprites/ui/spectator/marker-selected.png"
                    local players = ArenaGameplay.GetAlivePlayers(lobby, data)
                    local player_count = #players
                    if (player_count > 0) then
                        local closest_player = nil
                        local highest_dot_product = -1
                        local selected_marker_x = nil
                        local selected_marker_y = nil
                        for k, v in ipairs(players) do
                            if(v.entity ~= data.selected_player)then
                                local x, y = EntityGetTransform(v.entity)
                                if (x ~= nil and y ~= nil) then
                                    local x_diff = x - camera_x
                                    local y_diff = y - camera_y
                                    local dist = math.sqrt(x_diff * x_diff + y_diff * y_diff)
                                    local to_player_x, to_player_y = x_diff / dist, y_diff / dist
                        
                                    local dot_product = aim_x * to_player_x + aim_y * to_player_y
                        
                                    local angle = math.atan2(y_diff, x_diff)
                                    local marker_x = screen_width / 2 + math.cos(angle) * marker_distance_from_center
                                    local marker_y = screen_height / 2 + math.sin(angle) * marker_distance_from_center
                                    GuiImage(data.spectator_gui, new_id(), marker_x - 3.5, marker_y - 3.5, player_marker, 0.8, 1, 1)
                        
                                    if dot_product > highest_dot_product then
                                        highest_dot_product = dot_product
                                        closest_player = v
                                        selected_marker_x = marker_x
                                        selected_marker_y = marker_y
                                    end


                                end
                            end
                        end
                        
                        if(closest_player ~= nil)  then
                            GuiImage(data.spectator_gui, new_id(), selected_marker_x - 3.5, selected_marker_y - 3.5, selected_player_marker, 0.8, 1, 1)
                            if(input:WasMousePressed("left") or right_trigger_pressed)then
                                data.selected_player = closest_player.entity
                                arena_log:print("Spectating player: " .. EntityGetName(data.selected_player))

                                local player = ArenaGameplay.FindUser(lobby, EntityGetName(data.selected_player))

                                data.selected_player_name = "Unknown Player"
                                if (player ~= nil) then
                                    data.selected_player_name = steamutils.getTranslatedPersonaName(player)
                                end
                            end
                        end
                        
                    end
                end
            end

            --[[
            local pressed, shift_held = hack_update_keys()

            for _, key in ipairs(pressed) do
                if(data.selected_player ~= nil)then
                    if(key == "w" or key == "a" or key == "s" or key == "d")then

                        data.selected_player = nil

                    elseif(key == "q")then



                    elseif(key == "e")then

                    end
                end
            end
            ]]
        end
    end,
    WinnerCheck = function(lobby, data)
        --[[
        if(true)then
            return
        end
        ]]

        print("WinnerCheck (spectator)")

        local alive = 0
        local winner = nil
        for k, v in pairs(data.players) do
            if (v.alive) then
                print("Player " .. steamutils.getTranslatedPersonaName(v.id) .. " is alive")
                alive = alive + 1
                winner = v.id
            end
        end
        if (alive == 1) then
            GamePrintImportant(string.format(GameTextGetTranslatedOrNot("$arena_winner_text"), steamutils.getTranslatedPersonaName(winner)), GameTextGetTranslatedOrNot("$arena_round_end_text"))

            -- if we are owner, add win to tally
            if (steamutils.IsOwner(lobby)) then
                local winner_key = tostring(winner) .. "_wins"
                local current_wins = tonumber(tonumber(steam.matchmaking.getLobbyData(lobby, winner_key)) or "0")
                steam.matchmaking.setLobbyData(lobby, winner_key, tostring(current_wins + 1))
            end

            SpectatorMode.LoadLobby(lobby, data, false)
        elseif (alive == 0) then
            GamePrintImportant(GameTextGetTranslatedOrNot("$arena_tie_text"), GameTextGetTranslatedOrNot("$arena_round_end_text"))

            SpectatorMode.LoadLobby(lobby, data, false)
        end
    end,
    ArenaUpdate = function(lobby, data)
        if (data.preparing) then
            local spawn_points = EntityGetWithTag("spawn_point") or {}
            if (spawn_points ~= nil and #spawn_points > 0) then
                data.ready_for_zone = true

                local spawn_point = spawn_points[Random(1, #spawn_points)]
                local x, y = EntityGetTransform(spawn_point)

                local spawn_loaded = DoesWorldExistAt(x - 100, y - 100, x + 100, y + 100)

                GameSetCameraPos(x, y)

                arena_log:print("Arena loaded? " .. tostring(spawn_loaded))

                local in_bounds = ArenaGameplay.IsInBounds(0, 0, 400)

                if (not in_bounds) then
                    arena_log:print("Game tried to spawn player out of bounds, retrying...")
                    GamePrint("Game attempted to spawn you out of bounds, retrying...")
                end

                if (spawn_loaded and in_bounds) then
                    data.preparing = false

                    data.arena_spectator = true
                    ArenaGameplay.LoadClientPlayers(lobby, data)
                    --GamePrint("Spawned!!")

                    --if (not steamutils.IsOwner(lobby)) then
                    --    networking.send.arena_loaded(lobby)
                        --message_handler.send.Loaded(lobby)
                    --end

                end
            else
                GameSetCameraPos(data.spawn_point.x, data.spawn_point.y)
            end
        end
        if (steamutils.IsOwner(lobby)) then
            if ((not data.players_loaded and ArenaGameplay.CheckAllPlayersLoaded(lobby, data))) then
                data.players_loaded = true
                arena_log:print("All players loaded")
                --message_handler.send.StartCountdown(lobby)
                networking.send.start_countdown(lobby)
                print("Sent countdown")
                ArenaGameplay.FightCountdown(lobby, data)
            end
        end

        if (data.countdown ~= nil) then
            data.countdown:update()
        end
    end,
    SpawnSpectatedPlayer = function(lobby, data)
        if(data.lobby_spectated_player ~= nil)then
            if (data.lobby_spectated_player ~= steam.user.getSteamID() and data.players[tostring(data.lobby_spectated_player)].entity) then
                data.players[tostring(data.lobby_spectated_player)]:Clean(lobby)
            end

            if (data.lobby_spectated_player ~= steam.user.getSteamID() and data.players[tostring(data.lobby_spectated_player)].entity == nil) then
                for k, v in ipairs(EntityGetWithTag("client") or {})do
                    EntityKill(v)
                end
                --GamePrint("Loading player " .. tostring(member.id))
                data.selected_player = ArenaGameplay.SpawnClientPlayer(lobby, data.lobby_spectated_player, data, 0, 0)
            end
        end
    end,
    LobbySpectateUpdate = function(lobby, data)
        local members = steamutils.getLobbyMembers(lobby)
        local lobby_spectated_player = data.lobby_spectated_player

        if(lobby_spectated_player == nil and members ~= nil and #members > 0)then
            data.lobby_spectated_player = members[1].id
            data.selected_player_name = steamutils.getTranslatedPersonaName(data.lobby_spectated_player)
            data.spectator_lobby_loaded = false
        end

        local camera_x, camera_y = GameGetCameraPos()

        if ( data.selected_player ~= nil) then
            local client_entity = data.selected_player
            if (client_entity ~= nil and EntityGetIsAlive(client_entity)) then
                local x, y = EntityGetTransform(client_entity)

                if (x ~= nil and y ~= nil) then
                    -- camera smoothing
                    local camera_speed = 0.1

                    local camera_x_diff = x - camera_x
                    local camera_y_diff = y - camera_y
                    local camera_x_new = camera_x + camera_x_diff * camera_speed
                    local camera_y_new = camera_y + camera_y_diff * camera_speed
                    GameSetCameraPos(camera_x_new, camera_y_new)
                else
                    data.selected_player = nil
                    data.selected_player_name = nil
                    data.lobby_spectated_player = nil
                end
            else
                data.selected_player = nil
                data.selected_player_name = nil
                data.lobby_spectated_player = nil
            end
        end

        local keys_pressed = {
            w = input:WasKeyPressed("w"),
            a = input:WasKeyPressed("a"),
            s = input:WasKeyPressed("s"),
            d = input:WasKeyPressed("d"),
            q = input:WasKeyPressed("q"),
            e = input:WasKeyPressed("e"),
            space = input:WasKeyPressed("space"),
        }

        local stick_x, stick_y = input:GetGamepadAxis("left_stick")
        local r_stick_x, r_stick_y = input:GetGamepadAxis("right_stick")
        local left_trigger = input:GetGamepadAxis("left_trigger")
        local right_trigger = input:GetGamepadAxis("right_trigger")

        local left_bumper = input:WasGamepadButtonPressed("left_shoulder")
        local right_bumper = input:WasGamepadButtonPressed("right_shoulder")

        local right_trigger_pressed = right_trigger >= 0.5 and data.spectator_quick_switch_trigger < 0.5
        
        data.spectator_quick_switch_trigger = right_trigger

        if (not GameHasFlagRun("chat_input_hovered")) then

            local camera_speed = tonumber(MagicNumbersGetValue("DEBUG_FREE_CAMERA_SPEED")) or 2
            local movement_x = (stick_x * (camera_speed * (1 + (right_trigger * 5))))
            local movement_y = (stick_y * (camera_speed * (1 + (right_trigger * 5))))

            local stick_average = ((stick_x + stick_y) / 2)

            if(stick_average >= 0.1 or stick_average <= -0.1)then
                --arena_log:print("x_move: "..tostring(movement_x)..", y_move: "..tostring(movement_y))

                GameSetCameraPos(camera_x + movement_x, camera_y + movement_y)
            end

            if (keys_pressed.w or keys_pressed.a or keys_pressed.s or keys_pressed.d or stick_average >= 0.1 or stick_average <= -0.1) then
                data.selected_player = nil
            end

            if(right_trigger_pressed or keys_pressed.space)then
                local player_entities = EntityGetWithTag("client") or {}

                if(#player_entities > 0)then
                    data.selected_player = player_entities[1]

                end
            end

            if (keys_pressed.q or left_bumper) then
                --[[
                    data.lobby_spectated_player = 
                    data.selected_player_name = 
                ]]
                local lobby_spectated_player = data.lobby_spectated_player

                if(lobby_spectated_player ~= nil and members ~= nil and #members > 0)then
                    local index = 1
                    for k, v in ipairs(members)do
                        if(v.id == lobby_spectated_player)then
                            index = k
                            break
                        end
                    end

                    index = index - 1

                    if(index < 1)then
                        index = #members
                    end

                    data.lobby_spectated_player = members[index].id
                    data.selected_player_name = steamutils.getTranslatedPersonaName(data.lobby_spectated_player)
                    data.spectator_lobby_loaded = false
                    data.selected_player = nil
                end
            end

            if (keys_pressed.e or right_bumper) then
                local lobby_spectated_player = data.lobby_spectated_player

                if(lobby_spectated_player ~= nil and members ~= nil and #members > 0)then
                    local index = 1
                    for k, v in ipairs(members)do
                        if(v.id == lobby_spectated_player)then
                            index = k
                            break
                        end
                    end

                    index = index + 1

                    if(index > #members)then
                        index = 1
                    end

                    data.lobby_spectated_player = members[index].id
                    data.selected_player_name = steamutils.getTranslatedPersonaName(data.lobby_spectated_player)
                    data.spectator_lobby_loaded = false
                    data.selected_player = nil
                end
            end
        end
    end,
    LobbyUpdate = function(lobby, data)
        SpectatorMode.SpectatorText(lobby, data)

        SpectatorMode.LobbySpectateUpdate(lobby, data)

        if(#(EntityGetWithTag("workshop") or {}) > 0 and not data.spectator_lobby_loaded)then
            data.spectator_lobby_loaded = true
            SpectatorMode.SpawnSpectatedPlayer(lobby, data)
        end

        ArenaGameplay.RunReadyCheck(lobby, data)
    end,
    Update = function(lobby, data)
        SpectatorMode.UpdateSpectatorEntity(lobby, data)
        SpectatorMode.SpectateUpdate(lobby, data)
        if(data.state == "lobby")then
            SpectatorMode.LobbyUpdate(lobby, data)
        elseif(data.state == "arena") then
            SpectatorMode.ArenaUpdate(lobby, data)
        end
        ArenaGameplay.UpdateTweens(lobby, data)
        if (GameGetFrameNum() % 60 == 0) then
            ArenaGameplay.ValidatePlayers(lobby, data)
        end
        ArenaGameplay.CheckFiringBlock(lobby, data)
    end,
    LateUpdate = function(lobby, data)

    end,
}

return SpectatorMode