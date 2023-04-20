local steamutils = dofile_once("mods/evaisa.mp/lib/steamutils.lua")
local player = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/player.lua")
local playerinfo = dofile("mods/evaisa.arena/files/scripts/gamemode/playerinfo.lua")
local healthbar = dofile("mods/evaisa.arena/files/scripts/utilities/health_bar.lua")
local tween = dofile("mods/evaisa.arena/lib/tween.lua")
local Vector = dofile("mods/evaisa.arena/lib/vector.lua")
local json = dofile("mods/evaisa.arena/lib/json.lua")
local EZWand = dofile("mods/evaisa.arena/files/scripts/utilities/EZWand.lua")
local EntityHelper = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/entity.lua")
local smallfolk = dofile("mods/evaisa.arena/lib/smallfolk.lua")
dofile_once( "data/scripts/perks/perk_list.lua" )
dofile_once("mods/evaisa.arena/content/data.lua")



ArenaMessageHandler = {
    receive = {
        ready = function(lobby, message, user, data, username)
            data.players[tostring(user)].ready = true

            GamePrint(tostring(username) .. " is ready.")

            if(steamutils.IsOwner(lobby))then
                steam.matchmaking.setLobbyData(lobby, tostring(user).."_ready", "true")
            end
        end,
        unready = function(lobby, message, user, data, username)
            data.players[tostring(user)].ready = false

            if(not message.no_message)then
                GamePrint(tostring(username) .. " is no longer ready.")
            end
            if(steamutils.IsOwner(lobby))then
                steam.matchmaking.setLobbyData(lobby, tostring(user).."_ready", "false")
            end
        end,
        arena_loaded = function(lobby, message, user, data, username)
            data.players[tostring(user)].loaded = true

            GamePrint(username .. " has loaded the arena.")

            if(steamutils.IsOwner(lobby))then
                steam.matchmaking.setLobbyData(lobby, tostring(user).."_loaded", "true")
            end
        end,
        enter_arena = function(lobby, message, user, data)
            gameplay_handler.LoadArena(lobby, data, true)
        end,
        health_info = function(lobby, message, user, data)
            if(not gameplay_handler.CheckPlayer(lobby, user, data))then
                return
            end


            local health = message.health
            local maxHealth = message.max_health

            if(data.players[tostring(user)].entity ~= nil)then
                local last_health = maxHealth
                if(data.players[tostring(user)].health)then
                    last_health = data.players[tostring(user)].health
                end
                if(health < last_health)then
                    local damage = last_health - health
                    EntityInflictDamage(data.players[tostring(user)].entity, damage, "DAMAGE_DROWNING", "damage_fake", "NORMAL", 0, 0, nil)
                end

                local DamageModelComp = EntityGetFirstComponentIncludingDisabled(data.players[tostring(user)].entity, "DamageModelComponent")
            
                if(DamageModelComp ~= nil)then
                    ComponentSetValue2(DamageModelComp, "max_hp", maxHealth)
                    ComponentSetValue2(DamageModelComp, "hp", health)
                end
            end

            data.players[tostring(user)].health = health
            data.players[tostring(user)].max_health = maxHealth

            if(data.players[tostring(user)].hp_bar)then
                data.players[tostring(user)].hp_bar:setHealth(health, maxHealth)
            else
                local hp_bar = healthbar.create(health, maxHealth, 18, 2)
                data.players[tostring(user)].hp_bar = hp_bar
            end
        end,
        update_hp = function(lobby, message, user, data)
            local health = message.health
            local maxHealth = message.max_health

            data.players[tostring(user)].health = health
            data.players[tostring(user)].max_health = maxHealth
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
            data.countdown = nil
        end,
        death = function(lobby, message, user, data, username)
            
            local killer = message.killer
            -- iterate data.tweens backwards and remove tweens belonging to the dead player
            for i = #data.tweens, 1, -1 do
                local tween = data.tweens[i]
                if(tween.id == tostring(user))then
                    table.remove(data.tweens, i)
                end
            end

            data.players[tostring(user)]:Clean(lobby)
            data.players[tostring(user)].alive = false
            data.deaths = data.deaths + 1

            if(killer == nil)then
                
                GamePrint(tostring(username) .. " died.")
            else
                local killer_id = gameplay_handler.FindUser(lobby, killer)
                if(killer_id ~= nil)then
                    GamePrint(tostring(username) .. " was killed by " .. steam.friends.getFriendPersonaName(killer_id))
                else
                    GamePrint(tostring(username) .. " died.")
                end
            end

            gameplay_handler.WinnerCheck(lobby, data)
        end,
        wand_fired = function(lobby, message, user, data)
            if(not gameplay_handler.CheckPlayer(lobby, user, data))then
                return
            end

            if(GameHasFlagRun("player_is_unlocked") and (not GameHasFlagRun("no_shooting")) and data.players[tostring(user)].entity ~= nil and EntityGetIsAlive(data.players[tostring(user)].entity))then
            
                data.players[tostring(user)].can_fire = true

                --local platformShooterPlayerComponent = EntityGetFirstComponentIncludingDisabled(data.players[tostring(user)].entity, "PlatformShooterPlayerComponent")
                --ComponentSetValue2(platformShooterPlayerComponent, "mForceFireOnNextUpdate", true)

                --print("special seed received: "..tostring(message.special_seed))

                --GamePrint("1: shooter_rng_"..tostring(user))
                GlobalsSetValue("shooter_rng_"..tostring(user), tostring(message.special_seed))

                --[[if(message.cast_state ~= nil)then
                    GlobalsSetValue("shooter_cast_state_"..tostring(user), tostring(message.cast_state))
                end]]

                data.players[tostring(user)].projectile_rng_stack = message.rng

                --data.players[tostring(user)].projectile_fire_data = message.fire_data
    
                local controlsComp = EntityGetFirstComponentIncludingDisabled(data.players[tostring(user)].entity, "ControlsComponent")

                if(controlsComp ~= nil)then
                    local inventory2Comp = EntityGetFirstComponentIncludingDisabled(data.players[tostring(user)].entity, "Inventory2Component")
                    local mActiveItem = ComponentGetValue2(inventory2Comp, "mActiveItem")

                    local aimNormal_x, aimNormal_y = ComponentGetValue2(controlsComp, "mAimingVectorNormalized")
                    local aim_x, aim_y = ComponentGetValue2(controlsComp, "mAimingVector")

                    local wand_x, wand_y = EntityGetTransform(mActiveItem)

                    local x = wand_x + (aimNormal_x * 2)
                    local y = wand_y + (aimNormal_y * 2)
                    y = y - 1

                    local target_x = x + aim_x
                    local target_y = y + aim_y

                    EntityHelper.BlockFiring(data.players[tostring(user)].entity, false)

                    --GamePrint("client is shooting.")

                    local wand_data = message.wand_data

                    EntitySetTransform(mActiveItem, wand_data.x, wand_data.y, wand_data.r, wand_data.w, wand_data.h)
                    EntityApplyTransform(mActiveItem, wand_data.x, wand_data.y, wand_data.r, wand_data.w, wand_data.h)

                    EntityAddTag(data.players[tostring(user)].entity, "player_unit")
                    np.UseItem(data.players[tostring(user)].entity, mActiveItem, true, true, true, x, y, target_x, target_y)
                    EntityRemoveTag(data.players[tostring(user)].entity, "player_unit")

                    EntityHelper.BlockFiring(data.players[tostring(user)].entity, true)
                    --[[if(message.target)then
                        data.players[tostring(user)].target = message.target
                    end]]
                end
            end
        end,
        character_update = function(lobby, message, user, data)
            if(not gameplay_handler.CheckPlayer(lobby, user, data))then
                return
            end
            if(GameHasFlagRun("player_is_unlocked") and (not GameHasFlagRun("no_shooting")))then
                local entity = data.players[tostring(user)].entity
                if(entity ~= nil and EntityGetIsAlive(entity))then
                    local x, y = EntityGetTransform(entity)
                    local characterData = EntityGetFirstComponentIncludingDisabled(entity, "CharacterDataComponent")

                    --local vel_x, vel_y = ComponentGetValue2(characterData, "mVelocity")

                    --EntitySetTransform(entity, message.x, message.y, message.r, message.w, message.h)
                    --EntityApplyTransform(entity, message.x, message.y, message.r, message.w, message.h)

                    ComponentSetValue2(characterData, "mVelocity", message.vel_x, message.vel_y)

                    --[[if(entity ~= nil and EntityGetIsAlive(entity))then
                        EntitySetTransform(entity, message.x, message.y)
                        EntityApplyTransform(entity, message.x, message.y)
        
                    end]]


                    --local positionTween = tween.vector(Vector.new(x, y), Vector.new(message.x, message.y), 1, function(value)
                        local newPlayerEntity = data.players[tostring(user)].entity
                        if(newPlayerEntity ~= nil and EntityGetIsAlive(newPlayerEntity))then

                            local x, y = message.x, message.y

                            if((ModSettingGet("evaisa.arena.predictive_netcode") or false) == true)then
                                local delay = math.floor(data.players[tostring(user)].delay_frames / 2) or 0

                                local last_position_x, last_position_y = nil, nil

                                for k, v in ipairs(data.players[tostring(user)].previous_positions)do
                                    if(last_position_x == nil)then
                                        last_position_x = x
                                    else
                                        last_position_x = last_position_x + v.x
                                    end
                                    if(last_position_y == nil)then
                                        last_position_y = y
                                    else
                                        last_position_y = last_position_y + v.y
                                    end
                                end

                                local new_x, new_y = x, y

                                if(last_position_x ~= nil and last_position_y ~= nil)then

                                    last_position_x = last_position_x / #data.players[tostring(user)].previous_positions
                                    last_position_y = last_position_y / #data.players[tostring(user)].previous_positions
    

                                    -- calculate movement since last update
                                    local additional_movement_x = x - last_position_x
                                    local additional_movement_y = y - last_position_y

                                    -- predict likely movement using delay
                                    local predicted_movement_x = additional_movement_x * delay
                                    local predicted_movement_y = additional_movement_y * delay

                                    -- add predicted movement to current position
                                    new_x = x + predicted_movement_x
                                    new_y = y + predicted_movement_y

                                    local hit, hit_x, hit_y = RaytracePlatforms(x, y, new_x, new_y)

                                    if(hit)then
                                        new_x = hit_x
                                        new_y = hit_y
                                    end

                                end

                                --[[
                                data.players[tostring(user)].last_position_x = x
                                data.players[tostring(user)].last_position_y = y
                                ]]

                                if(#data.players[tostring(user)].previous_positions >= 5)then
                                    table.remove(data.players[tostring(user)].previous_positions, 1)
                                end
                                table.insert(data.players[tostring(user)].previous_positions, {x = x, y = y} )

                                --GamePrint("additional_movement_x: "..tostring(additional_movement_x))
                               -- GamePrint("additional_movement_y: "..tostring(additional_movement_y))

                                EntitySetTransform(newPlayerEntity, new_x, new_y)
                                EntityApplyTransform(newPlayerEntity, new_x, new_y)
                            else
                                EntitySetTransform(newPlayerEntity, x, y)
                                EntityApplyTransform(newPlayerEntity, x, y)
                            end
                            --GamePrint("Updating client position")
                        end
                   -- end)
        
                    --positionTween.id = tostring(user)

                    --table.insert(data.tweens, positionTween)

                    --[[
                    local velocityTween = tween.vector(Vector.new(vel_x, vel_y), Vector.new(data.vel_x, data.vel_y), 2, function(value)
                        local newPlayerEntity = data.players[tostring(user)].entity
                        if(newPlayerEntity ~= nil and EntityGetIsAlive(newPlayerEntity))then
                            local newCharacterData = EntityGetFirstComponentIncludingDisabled(newPlayerEntity, "CharacterDataComponent")
                            ComponentSetValue2(newCharacterData, "mVelocity", value.x, value.y)
                        end
                    end)

                    velocityTween.id = tostring(user)

                    table.insert(data.tweens, velocityTween)
                    ]]
                end
            end
        end,
        wand_update = function(lobby, message, user, data)
            --print(message.wandData)

            if(not gameplay_handler.CheckPlayer(lobby, user, data))then
                return
            end

            --GamePrint("Received wand update")

            if(data.players[tostring(user)].entity and EntityGetIsAlive(data.players[tostring(user)].entity))then

                if(data.players[tostring(user)].entity and EntityGetIsAlive(data.players[tostring(user)].entity))then
                    local items = GameGetAllInventoryItems( data.players[tostring(user)].entity ) or {}
                    for i,item_id in ipairs(items) do
                        GameKillInventoryItem( data.players[tostring(user)].entity, item_id )
                        EntityKill(item_id)
                    end
                end
                if(message.wandData ~= nil)then
                    for k, wandInfo in ipairs(message.wandData)do

                        local x, y = EntityGetTransform(data.players[tostring(user)].entity)

                        local wand = EZWand(wandInfo.data, x, y)
                        if(wand == nil)then
                            return
                        end

                        wand:PickUp(data.players[tostring(user)].entity)
                        
                        local itemComp = EntityGetFirstComponentIncludingDisabled(wand.entity_id, "ItemComponent")
                        if(itemComp ~= nil)then
                            ComponentSetValue2(itemComp, "inventory_slot", wandInfo.slot_x, wandInfo.slot_y)
                        end

                        if(wandInfo.active)then
                            game_funcs.SetActiveHeldEntity(data.players[tostring(user)].entity, wand.entity_id, false, false)
                        end

                        GlobalsSetValue(tostring(wand.entity_id).."_wand", tostring(wandInfo.id))
                        
                    end
                end

                --[[
                if(DebugGetIsDevBuild())then
                    EntitySave(data.players[tostring(user)].entity, "player_" .. tostring(user) .. ".xml")
                end
            ]]
            end
        end,
        switch_item = function(lobby, message, user, data)
            if(not gameplay_handler.CheckPlayer(lobby, user, data))then
                return
            end

            --GlobalsSetValue(tostring(wand.entity_id).."_wand", wandInfo.id)
            local id = message.item_id
            if(data.players[tostring(user)].entity and EntityGetIsAlive(data.players[tostring(user)].entity))then

                if(data.players[tostring(user)].entity and EntityGetIsAlive(data.players[tostring(user)].entity))then
                    local items = GameGetAllInventoryItems( data.players[tostring(user)].entity ) or {}
                    for i,item in ipairs(items) do
                        -- check id
                        local item_id = tonumber(GlobalsGetValue(tostring(item).."_wand")) or -1
                        if(item_id == id)then
                            game_funcs.SetActiveHeldEntity(data.players[tostring(user)].entity, item, false, false)
                            return
                        end
                    end
                end
            end
        end,
        animation_update = function(lobby, message, user, data)
            if(not gameplay_handler.CheckPlayer(lobby, user, data))then
                return
            end

            --GamePrint("Updating animation")
            if(message.rectAnim ~= nil and message.rectAnim ~= "")then
                local entity = data.players[tostring(user)].entity
                if(entity ~= nil)then
                    local spriteComp = EntityGetFirstComponent(entity, "SpriteComponent", "character")
                    if(spriteComp ~= nil)then
                        local lastRect = ComponentGetValue2(spriteComp, "rect_animation")

                        if (lastRect == message.rectAnim) then
                            return
                        end

                        --print(tostring(message.rectAnim))

                        --if(message.rectAnim == "stand")then
                        --    ComponentSetValue2(spriteComp, "rect_animation", "stand")
                        --else
                            GamePlayAnimation( entity, message.rectAnim, 1 )
                        --end
                        --GamePrint("Animation set to " .. message.rectAnim)
                    end
                end
            end
        end,
        --[[
        aim_update = function(lobby, message, user, data)
            if(not gameplay_handler.CheckPlayer(lobby, user, data))then
                return
            end

            local entity = data.players[tostring(user)].entity
            if(entity ~= nil)then
                local controlsComp = EntityGetFirstComponentIncludingDisabled(entity, "ControlsComponent")
                ComponentSetValue2(controlsComp, "mAimingVector", message.aimData.x, message.aimData.y)
            end
        end,
        ]]
        perk_info = function(lobby, message, user, data)
            --print("Received perk info: "..json.stringify(message.perks))
            data.players[tostring(user)].perks = message.perks
        end,
        sync_controls = function(lobby, message, user, data)
            if(not gameplay_handler.CheckPlayer(lobby, user, data))then
                return
            end
            if(GameHasFlagRun("player_is_unlocked") and (not GameHasFlagRun("no_shooting")))then
                if(data.players[tostring(user)] ~= nil and data.players[tostring(user)].entity ~= nil and EntityGetIsAlive(data.players[tostring(user)].entity))then
                    -- set mButtonDownKick to true
                    local controlsComp = EntityGetFirstComponentIncludingDisabled(data.players[tostring(user)].entity, "ControlsComponent")

                    if(controlsComp ~= nil)then

                        local controls_data = data.players[tostring(user)].controls

                        if(message.kick)then
                            ComponentSetValue2(controlsComp, "mButtonDownKick", true)
                            if(not controls_data.kick)then
                                ComponentSetValue2(controlsComp, "mButtonFrameKick", GameGetFrameNum())
                            end
                            controls_data.kick = true
                        else
                            ComponentSetValue2(controlsComp, "mButtonDownKick", false)
                        end

                        if(message.fire)then
                            ComponentSetValue2(controlsComp, "mButtonDownFire", true)
                            --local lastFireFrame = ComponentGetValue2(controlsComp, "mButtonFrameFire")
                            if(not controls_data.fire)then
                                ComponentSetValue2(controlsComp, "mButtonFrameFire", GameGetFrameNum())
                            end
                            ComponentSetValue2(controlsComp, "mButtonLastFrameFire", GameGetFrameNum())
                            controls_data.fire = true
                        else
                            ComponentSetValue2(controlsComp, "mButtonDownFire", false)
                        end

                        if(message.fire2)then
                            ComponentSetValue2(controlsComp, "mButtonDownFire2", true)
                            if(not controls_data.fire2)then
                                ComponentSetValue2(controlsComp, "mButtonFrameFire2", GameGetFrameNum())
                            end
                            controls_data.fire2 = true
                        else
                            ComponentSetValue2(controlsComp, "mButtonDownFire2", false)
                        end
                        
                        if(message.leftClick)then
                            ComponentSetValue2(controlsComp, "mButtonDownLeftClick", true)
                            if(not controls_data.leftClick)then
                                ComponentSetValue2(controlsComp, "mButtonFrameLeftClick", GameGetFrameNum())
                            end
                            controls_data.leftClick = true
                        else
                            ComponentSetValue2(controlsComp, "mButtonDownLeftClick", false)
                        end

                        if(message.rightClick)then
                            ComponentSetValue2(controlsComp, "mButtonDownRightClick", true)
                            if(not controls_data.rightClick)then
                                ComponentSetValue2(controlsComp, "mButtonFrameRightClick", GameGetFrameNum())
                            end
                            controls_data.rightClick = true
                        else
                            ComponentSetValue2(controlsComp, "mButtonDownRightClick", false)
                        end

                        ComponentSetValue2(controlsComp, "mAimingVector", message.aim.x, message.aim.y)
                        ComponentSetValue2(controlsComp, "mAimingVectorNormalized", message.aimNormal.x, message.aimNormal.y)
                        ComponentSetValue2(controlsComp, "mAimingVectorNonZeroLatest", message.aimNonZero.x, message.aimNonZero.y)
                        ComponentSetValue2(controlsComp, "mMousePosition", message.mouse.x, message.mouse.y)
                        ComponentSetValue2(controlsComp, "mMousePositionRaw", message.mouseRaw.x, message.mouseRaw.y)
                        ComponentSetValue2(controlsComp, "mMousePositionRawPrev", message.mouseRawPrev.x, message.mouseRawPrev.y)
                        ComponentSetValue2(controlsComp, "mMouseDelta", message.mouseDelta.x, message.mouseDelta.y)

                        -- get cursor entity
                        local children = EntityGetAllChildren(data.players[tostring(user)].entity)
                        for i,child in ipairs(children) do
                            if(EntityGetName(child) == "cursor")then
                                EntitySetTransform(child, message.mouse.x, message.mouse.y)
                                EntityApplyTransform(child, message.mouse.x, message.mouse.y)
                            end
                        end
                    end
                end
            end
        end,
        sync_wand_stats = function(lobby, message, user, data)
            --[[
                steamutils.sendData({type = "sync_wand_stats", 
                    mana = mana, 
                    mCastDelayStartFrame = GameGetFrameNum() - cast_delay_start_frame,
                    mReloadFramesLeft = reload_frames_left,
                    mReloadNextFrameUsable = reload_next_frame_usable - GameGetFrameNum(),
                    mNextChargeFrame = next_charge_frame - GameGetFrameNum(),
                }, steamutils.messageTypes.OtherPlayers, lobby)
            ]]

            if(not gameplay_handler.CheckPlayer(lobby, user, data))then
                return
            end
            if(GameHasFlagRun("player_is_unlocked") and (not GameHasFlagRun("no_shooting")))then
                if(data.players[tostring(user)].entity and EntityGetIsAlive(data.players[tostring(user)].entity))then
                    local inventory2Comp = EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component")
                    local mActiveItem = ComponentGetValue2(inventory2Comp, "mActiveItem")
                
                    if(mActiveItem ~= nil)then
                        local mana = message.mana
                        local mCastDelayStartFrame = GameGetFrameNum() - message.mCastDelayStartFrame
                        local mReloadFramesLeft = message.mReloadFramesLeft
                        local mReloadNextFrameUsable = message.mReloadNextFrameUsable + GameGetFrameNum()
                        local mNextChargeFrame = message.mNextChargeFrame + GameGetFrameNum()

                        local abilityComp = EntityGetFirstComponentIncludingDisabled(mActiveItem, "AbilityComponent")
                        if(abilityComp ~= nil)then
                            ComponentSetValue2(abilityComp, "mana", mana)
                            ComponentSetValue2(abilityComp, "mCastDelayStartFrame", mCastDelayStartFrame)
                            ComponentSetValue2(abilityComp, "mReloadFramesLeft", mReloadFramesLeft)
                            ComponentSetValue2(abilityComp, "mReloadNextFrameUsable", mReloadNextFrameUsable)
                            ComponentSetValue2(abilityComp, "mNextChargeFrame", mNextChargeFrame)
                        end
                    end
                end
            end
        end,
        handshake = function(lobby, message, user, data)
            steamutils.sendDataToPlayer({type = "handshake_confirmed", frame_sent = message.frame_sent, time_sent = message.time_sent--[[, time_received = (game_funcs.UintToString(game_funcs.GetUnixTimestamp()))]]}, user)
        end,
        handshake_confirmed = function(lobby, message, user, data)
            if(data.players[tostring(user)] ~= nil)then

                data.players[tostring(user)].ping = game_funcs.GetUnixTimeElapsed(game_funcs.StringToUint(message.time_sent), game_funcs.GetUnixTimestamp())
                data.players[tostring(user)].delay_frames = GameGetFrameNum() - message.frame_sent
            end
        end,
        request_wand_update = function(lobby, message, user, data)
            data.client.previous_wand = nil
            message_handler.send.WandUpdate(lobby, data, user)
        end,
        zone_update = function(lobby, message, user, data)
            GlobalsSetValue("arena_area_size", tostring(message.zone_size))
            GlobalsSetValue("arena_area_size_cap", tostring(message.zone_size + 200))
            data.zone_size = message.zone_size
            data.shrink_time = message.shrink_time
            GamePrint("Zone size: "..message.zone_size.."; Shrink time: "..message.shrink_time)
        end,
    },
    send = {
        ZoneUpdate = function(lobby, zone_size, shrink_time)
            steamutils.sendData({type = "zone_update", zone_size = zone_size, shrink_time = shrink_time}, steamutils.messageTypes.OtherPlayers, lobby)
        end,
        Handshake = function(lobby)
            steamutils.sendData({type = "handshake", frame_sent = GameGetFrameNum(), time_sent = (game_funcs.UintToString(game_funcs.GetUnixTimestamp())) }, steamutils.messageTypes.OtherPlayers, lobby)
        end,
        Ready = function(lobby)
            if(steamutils.IsOwner(lobby))then
                steam.matchmaking.setLobbyData(lobby, tostring(steam.user.getSteamID()).."_ready", "true")
            end
            steamutils.sendData({type = "ready"}, steamutils.messageTypes.OtherPlayers, lobby)
        end,
        Unready = function(lobby, no_message)
            if(steamutils.IsOwner(lobby))then
                steam.matchmaking.setLobbyData(lobby, tostring(steam.user.getSteamID()).."_ready", "false")
            end
            steamutils.sendData({type = "unready", no_message = no_message}, steamutils.messageTypes.OtherPlayers, lobby)
        end,
        RequestWandUpdate = function(lobby)
            steamutils.sendData({type = "request_wand_update"}, steamutils.messageTypes.OtherPlayers, lobby)
        end,
        EnterArena = function(lobby)
            steamutils.sendData({type = "enter_arena"}, steamutils.messageTypes.OtherPlayers, lobby)
        end,
        Loaded = function(lobby)
            steamutils.sendData({type = "arena_loaded"}, steamutils.messageTypes.Host, lobby)
        end,
        StartCountdown = function(lobby)
            steamutils.sendData({type = "start_countdown"}, steamutils.messageTypes.OtherPlayers, lobby)
        end,
        Health = function(lobby)
            local health, max_health = player.GetHealthInfo()
            steamutils.sendData({type = "health_info", health = health, max_health = max_health}, steamutils.messageTypes.OtherPlayers, lobby)
        end,
        Unlock = function(lobby)
            steamutils.sendData({type = "unlock"}, steamutils.messageTypes.OtherPlayers, lobby)
        end,
        Death = function(lobby, killer)
            steamutils.sendData({type = "death", killer = killer}, steamutils.messageTypes.OtherPlayers, lobby)
        end,
        WandFired = function(lobby, rng, special_seed, cast_state)
            local player = player.Get()
            if(player)then
                local wand = EntityHelper.GetHeldItem(player)

                if(wand ~= nil)then
                    --[[if(cast_state ~= nil)then
                        cast_state = smallfolk.loadsies(cast_state)
                    end]]

                    local x, y, r, w, h = EntityGetTransform(wand)
                    steamutils.sendData({type = "wand_fired", rng = rng, special_seed = special_seed, wand_data = {x = x, y = y, r = r, w = w, h = h}, cast_state = cast_state}, steamutils.messageTypes.OtherPlayers, lobby)
                end
            end
        end,
        CharacterUpdate = function(lobby, data)
            local player = player.Get()
            if(player)then
                local x, y, r, w, h = EntityGetTransform(player)
                local characterData = EntityGetFirstComponentIncludingDisabled(player, "CharacterDataComponent")
                local vel_x, vel_y = ComponentGetValue2(characterData, "mVelocity")
 
                steamutils.sendData({type = "character_update", x = x, y = y, r = r, w = w, h = h, vel_x = vel_x, vel_y = vel_y}, steamutils.messageTypes.OtherPlayers, lobby)
            end
        end,
        WandUpdate = function(lobby, data, user)
            --[[
            local wandData = player.GetWandData()
            if(wandData ~= nil)then
                if(wandData ~= data.client.previous_wand)then
                    local wandDataMana = player.GetWandDataMana()
                    steamutils.sendData({type = "wand_update", wandData = wandDataMana}, steamutils.messageTypes.OtherPlayers, lobby)
                    data.client.previous_wand = wandData
                end
            end
            ]]
            local wandString = player.GetWandString()
            if(wandString ~= nil)then
                if(wandString ~= data.client.previous_wand)then
                    local wandData = player.GetWandData()
                    if(wandData ~= nil)then
                        if(user ~= nil)then
                            steamutils.sendDataToPlayer({type = "wand_update", wandData = wandData}, user)
                        else
                            steamutils.sendData({type = "wand_update", wandData = wandData}, steamutils.messageTypes.OtherPlayers, lobby)
                        end
                    end
                    data.client.previous_wand = wandString
                end
            else
                if(data.client.previous_wand ~= nil)then
                    
                    if(user ~= nil)then
                        steamutils.sendDataToPlayer({type = "wand_update"}, user)
                    else
                        steamutils.sendData({type = "wand_update"}, steamutils.messageTypes.OtherPlayers, lobby) 
                    end
                    data.client.previous_wand = nil
                end
            end
        end,
        SwitchItem = function(lobby, data)
            local held_item = player.GetActiveHeldItem()
            if(held_item ~= nil)then
                if(held_item ~= data.client.previous_selected_item)then
                    local wand_id = tonumber(GlobalsGetValue(tostring(held_item).."_wand")) or -1
                    if(wand_id ~= -1)then
                        steamutils.sendData({type = "switch_item", item_id = wand_id}, steamutils.messageTypes.OtherPlayers, lobby)
                        data.client.previous_selected_item = held_item
                    end
                end
            end
        end,
        --[[
        Kick = function(lobby, data)
            local didKick = player.DidKick()
            if(didKick)then
                steamutils.sendData({type = "kick"}, steamutils.messageTypes.OtherPlayers, lobby)
            end
        end,
        ]]
        AnimationUpdate = function(lobby, data)
            local rectAnim = player.GetAnimationData()
            if(rectAnim ~= nil)then
                if(rectAnim ~= data.client.previous_anim)then
                    steamutils.sendData({type = "animation_update", rectAnim = rectAnim}, steamutils.messageTypes.OtherPlayers, lobby)
                    data.client.previous_anim = rectAnim
                end
            end
        end,
        --[[
        AimUpdate = function(lobby)
            local aim = player.GetAimData()
            if(aim ~= nil)then
                steamutils.sendData({type = "aim_update", aimData = aim}, steamutils.messageTypes.OtherPlayers, lobby)
            end
        end,
        ]]
        SyncControls = function(lobby, data)
            local controls = player.GetControlsComponent()
            if(controls ~= nil)then

                --[[
                    if(message.kick)then
                        ComponentSetValue2(controlsComp, "mButtonDownKick", true)
                        ComponentSetValue2(controlsComp, "mButtonFrameKick", GameGetFrameNum())
                    else
                        ComponentSetValue2(controlsComp, "mButtonDownKick", false)
                    end

                    
                    if(message.fire)then
                        ComponentSetValue2(controlsComp, "mButtonDownFire", true)
                        local lastFireFrame = ComponentGetValue2(controlsComp, "mButtonFrameFire")
                        ComponentSetValue2(controlsComp, "mButtonFrameFire", GameGetFrameNum())
                        ComponentSetValue2(controlsComp, "mButtonLastFrameFire", lastFireFrame)
                    else
                        ComponentSetValue2(controlsComp, "mButtonDownFire", false)
                    end

                    if(message.fire2)then
                        ComponentSetValue2(controlsComp, "mButtonDownFire2", true)
                        ComponentSetValue2(controlsComp, "mButtonFrameFire2", GameGetFrameNum())
                    else
                        ComponentSetValue2(controlsComp, "mButtonDownFire2", false)
                    end
                    
                    if(message.leftClick)then
                        ComponentSetValue2(controlsComp, "mButtonDownLeft", true)
                        ComponentSetValue2(controlsComp, "mButtonFrameLeft", GameGetFrameNum())
                    else
                        ComponentSetValue2(controlsComp, "mButtonDownLeft", false)
                    end

                    if(message.rightClick)then
                        ComponentSetValue2(controlsComp, "mButtonDownRight", true)
                        ComponentSetValue2(controlsComp, "mButtonFrameRight", GameGetFrameNum())
                    else
                        ComponentSetValue2(controlsComp, "mButtonDownRight", false)
                    end

                    ComponentSetValue2(controlsComp, "mAimingVector", message.aim.x, message.aim.y)
                    ComponentSetValue2(controlsComp, "mAimingVectorNormalized", message.aimNormal.x, message.aimNormal.y)
                    ComponentSetValue2(controlsComp, "mAimingVectorNonZeroLatest", message.aimNonZero.x, message.aimNonZero.y)
                    ComponentSetValue2(controlsComp, "mMousePosition", message.mouse.x, message.mouse.y)
                    ComponentSetValue2(controlsComp, "mMousePositionRaw", message.mouseRaw.x, message.mouseRaw.y)
                    ComponentSetValue2(controlsComp, "mMousePositionRawPrev", message.mouseRawPrev.x, message.mouseRawPrev.y)
                    ComponentSetValue2(controlsComp, "mMouseDelta", message.mouseDelta.x, message.mouseDelta.y)

                ]]

                local kick = ComponentGetValue2(controls, "mButtonDownKick")
                local fire = ComponentGetValue2(controls, "mButtonDownFire")
                local fire2 = ComponentGetValue2(controls, "mButtonDownFire2")
                local leftClick = ComponentGetValue2(controls, "mButtonDownLeftClick")
                local rightClick = ComponentGetValue2(controls, "mButtonDownRightClick")
                local aim_x, aim_y = ComponentGetValue2(controls, "mAimingVector")
                local aimNormal_x, aimNormal_y = ComponentGetValue2(controls, "mAimingVectorNormalized")
                local aimNonZero_x, aimNonZero_y = ComponentGetValue2(controls, "mAimingVectorNonZeroLatest")
                local mouse_x, mouse_y = ComponentGetValue2(controls, "mMousePosition")
                local mouseRaw_x, mouseRaw_y = ComponentGetValue2(controls, "mMousePositionRaw")
                local mouseRawPrev_x, mouseRawPrev_y = ComponentGetValue2(controls, "mMousePositionRawPrev")
                local mouseDelta_x, mouseDelta_y = ComponentGetValue2(controls, "mMouseDelta")

                local data = {
                    type = "sync_controls",
                    kick = kick,
                    fire = fire,
                    fire2 = fire2,
                    leftClick = leftClick,
                    rightClick = rightClick,
                    aim = {x = aim_x, y = aim_y},
                    aimNormal = {x = aimNormal_x, y = aimNormal_y},
                    aimNonZero = {x = aimNonZero_x, y = aimNonZero_y},
                    mouse = {x = mouse_x, y = mouse_y},
                    mouseRaw = {x = mouseRaw_x, y = mouseRaw_y},
                    mouseRawPrev = {x = mouseRawPrev_x, y = mouseRawPrev_y},
                    mouseDelta = {x = mouseDelta_x, y = mouseDelta_y},
                }

                steamutils.sendData(data, steamutils.messageTypes.OtherPlayers, lobby)

            end
        end,
        SendPerks = function(lobby)
            --GamePrint("Sending perks!")
            local perk_info = {}
            for i,perk_data in ipairs(perk_list) do
                local perk_id = perk_data.id
                --if(perks_allowed[perk_id] == nil or perks_allowed[perk_id] ~= false)then
                    --if (((( perk_data.one_off_effect == nil ) or ( perk_data.one_off_effect == false )) and perk_data.usable_by_enemies) or perks_allowed[perk_id] == true) then
                        local flag_name = get_perk_picked_flag_name( perk_id )

                        --print("Checking flag " .. flag_name)
                        
                        local pickup_count = tonumber( GlobalsGetValue( flag_name .. "_PICKUP_COUNT", "0" ) )
                        
                        --print(tostring(GameHasFlagRun( flag_name )))

                        if GameHasFlagRun( flag_name ) or ( pickup_count > 0 ) then
                            --print("Has flag: " .. perk_id)
                            table.insert( perk_info, { id = perk_id, count = pickup_count, run_on_clients = (perk_data.run_on_clients or perk_data.usable_by_enemies) or false } )
                        end
                   -- end
                --end
            end
            if(#perk_info > 0)then
                steamutils.sendData({type = "perk_info", perks = perk_info}, steamutils.messageTypes.OtherPlayers, lobby)
            end
        end,
        UpdateHp = function(lobby, data)
            local health, max_health = player.GetHealthInfo()

            if(data.client.previous_max_hp ~= max_health or data.client.previous_hp ~= health)then
                steamutils.sendData({type = "update_hp", health = health, max_health = max_health}, steamutils.messageTypes.OtherPlayers, lobby)
                data.client.previous_max_hp = max_health
                data.client.previous_hp = health
            end
        end,
        SyncWandStats = function(lobby, data)
            local held_item = player.GetActiveHeldItem()
            if(held_item ~= nil)then
                -- if has ability component
                local abilityComp = EntityGetFirstComponentIncludingDisabled(held_item, "AbilityComponent")
                if(abilityComp)then
                    --[[
                    -- get current mana
                    local mana = ComponentGetValue2(abilityComp, "mana")
                    -- mCastDelayStartFrame
                    local cast_delay_start_frame = ComponentGetValue2(abilityComp, "mCastDelayStartFrame")
                    -- mReloadFramesLeft
                    local reload_frames_left = ComponentGetValue2(abilityComp, "mReloadFramesLeft")
                    -- mReloadNextFrameUsable
                    local reload_next_frame_usable = ComponentGetValue2(abilityComp, "mReloadNextFrameUsable")
                    -- mNextChargeFramemNextChargeFrame
                    local next_charge_frame = ComponentGetValue2(abilityComp, "mNextChargeFrame")

                    steamutils.sendData({type = "sync_wand_stats", 
                        mana = mana, 
                        mCastDelayStartFrame = GameGetFrameNum() - cast_delay_start_frame,
                        mReloadFramesLeft = reload_frames_left,
                        mReloadNextFrameUsable = reload_next_frame_usable - GameGetFrameNum(),
                        mNextChargeFrame = next_charge_frame - GameGetFrameNum(),
                    }, steamutils.messageTypes.OtherPlayers, lobby)
                    ]]

                    --[[
                        previous_wand_stats = {
                            mana = nil, 
                            mCastDelayStartFrame = nil, 
                            mReloadFramesLeft = nil, 
                            mReloadNextFrameUsable = nil, 
                            mNextChargeFrame = nil, 
                        },
                    ]]
                    
                    -- check if any stats changed from previous, if they did send them
                    -- get current mana
                    local mana = ComponentGetValue2(abilityComp, "mana")
                    -- mCastDelayStartFrame
                    local cast_delay_start_frame = ComponentGetValue2(abilityComp, "mCastDelayStartFrame")
                    -- mReloadFramesLeft
                    local reload_frames_left = ComponentGetValue2(abilityComp, "mReloadFramesLeft")
                    -- mReloadNextFrameUsable
                    local reload_next_frame_usable = ComponentGetValue2(abilityComp, "mReloadNextFrameUsable")
                    -- mNextChargeFramemNextChargeFrame
                    local next_charge_frame = ComponentGetValue2(abilityComp, "mNextChargeFrame")

                    if( data.client.previous_wand_stats.mana ~= mana or
                        data.client.previous_wand_stats.mCastDelayStartFrame ~= cast_delay_start_frame or
                        data.client.previous_wand_stats.mReloadFramesLeft ~= reload_frames_left or
                        data.client.previous_wand_stats.mReloadNextFrameUsable ~= reload_next_frame_usable or
                        data.client.previous_wand_stats.mNextChargeFrame ~= next_charge_frame)then
                            
                        data.client.previous_wand_stats.mana = mana
                        data.client.previous_wand_stats.mCastDelayStartFrame = cast_delay_start_frame
                        data.client.previous_wand_stats.mReloadFramesLeft = reload_frames_left
                        data.client.previous_wand_stats.mReloadNextFrameUsable = reload_next_frame_usable
                        data.client.previous_wand_stats.mNextChargeFrame = next_charge_frame

                        steamutils.sendData({type = "sync_wand_stats", 
                            mana = mana, 
                            mCastDelayStartFrame = GameGetFrameNum() - cast_delay_start_frame,
                            mReloadFramesLeft = reload_frames_left,
                            mReloadNextFrameUsable = reload_next_frame_usable - GameGetFrameNum(),
                            mNextChargeFrame = next_charge_frame - GameGetFrameNum(),
                        }, steamutils.messageTypes.OtherPlayers, lobby)
                    end

                    
                end
            end
        end,
    },
    handle = function(lobby, message, user, data)
        if(not data)then
            GamePrint("ARENA: [FAILED CRITICALLY, DATA IS UNDEFINED]")
            print("ARENA: [FAILED CRITICALLY, DATA IS UNDEFINED]")
            return
        end

        -- if playerinfo is not initialized, initialize it
        if(not data.players[tostring(user)])then
            data:DefinePlayer(lobby, user)
        end

        local username = steam.friends.getFriendPersonaName(user)

        --GamePrint("ARENA: [RECEIVED MESSAGE] " .. message.type .. " FROM " .. username)
        --print("ARENA: [RECEIVED MESSAGE] " .. message.type .. " FROM " .. username)
        --[[if(data.last_message_type ~= message.type)then
            data.last_message_type = message.type
            GamePrint("ARENA: [RECEIVED MESSAGE] " .. message.type .. " FROM " .. username)
            print("ARENA: [RECEIVED MESSAGE] " .. message.type .. " FROM " .. username)
            print(json.stringify(message))
        end]]
        

        if ArenaMessageHandler.receive[message.type] then
            ArenaMessageHandler.receive[message.type](lobby, message, user, data, username)
        end
    end,
    update = function(lobby, data)
        if(GameGetFrameNum() % 60 == 0)then
            ArenaMessageHandler.send.Handshake(lobby)
        end
    end
}

return ArenaMessageHandler