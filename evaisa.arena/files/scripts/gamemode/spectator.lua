

SpectatorMode = {
    LoadLobby = function(lobby, data, show_message)
        ArenaGameplay.GracefulReset(lobby, data)

        data.selected_player = nil
        data.selected_player_name = nil
        GameRemoveFlagRun("can_save_player")
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

        BiomeMapLoad_KeepPlayer("mods/evaisa.arena/files/scripts/world/map_lobby.lua",
            "mods/evaisa.arena/files/biome/holymountain_scenes.xml")

        -- clean other player's data again because it might have failed for some cursed reason
        ArenaGameplay.CleanMembers(lobby, data)

        -- set ready counter
        ArenaGameplay.ReadyCounter(lobby, data)

        GameSetCameraFree(true)

    end,
    UpdateSpectatorEntity = function(lobby, data)
        if(data.spectator_entity == nil or not EntityGetIsAlive(data.spectator_entity))then
            data.spectator_entity = EntityLoad("mods/evaisa.arena/files/entities/spectator_entity.xml", 0, 0)
        end
        
        if(data.spectator_entity)then
            local camera_x, camera_y = GameGetCameraPos()
            EntitySetTransform(data.spectator_entity, camera_x, camera_y)
            EntityApplyTransform(data.spectator_entity, camera_x, camera_y)
        end
    end,
    SpectateUpdate = function(lobby, data)
        if (data.arena_spectator) then
            if (data.spectator_gui_entity == nil or not EntityGetIsAlive(data.spectator_gui_entity)) then
                data.spectator_gui_entity = EntityLoad("mods/evaisa.arena/files/entities/misc/spectator_text.xml")

                EntitySetTransform(data.spectator_gui_entity, 0, 0, 0, 0.25, 0.25)
            end

            if (data.spectator_text_gui == nil) then
                data.spectator_text_gui = GuiCreate()
            end

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

            local screen_text_width, screen_text_height = GuiGetScreenDimensions(data.spectator_text_gui)

            local text = GameTextGetTranslatedOrNot("$arena_spectating_text")

            if (data.selected_player ~= nil and data.selected_player_name ~= nil) then
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
                --[[
                arena_log:print("stick_x: "..tostring(stick_x))
                arena_log:print("stick_y: "..tostring(stick_y))
                arena_log:print("r_stick_x: "..tostring(r_stick_x))
                arena_log:print("r_stick_y: "..tostring(r_stick_y))
                arena_log:print("left_trigger: "..tostring(left_trigger))
                arena_log:print("right_trigger: "..tostring(right_trigger))
                ]]

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
    Update = function(lobby, data)
        SpectatorMode.UpdateSpectatorEntity(lobby, data)
        SpectatorMode.SpectateUpdate(lobby, data)
    end,
    LateUpdate = function(lobby, data)

    end,
}

return SpectatorMode