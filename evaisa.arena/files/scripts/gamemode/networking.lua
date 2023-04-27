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
            print(username .. " has loaded the arena.") 

            if(steamutils.IsOwner(lobby))then
                steam.matchmaking.setLobbyData(lobby, tostring(user).."_loaded", "true")
            end
        end,
        enter_arena = function(lobby, message, user, data)
            gameplay_handler.LoadArena(lobby, data, true)
        end,
        start_countdown = function(lobby, message, user, data)
            RunWhenPlayerExists(function()

                GamePrint("Starting countdown...")

                print("Received all clear for starting countdown.")

                data.players_loaded = true
                gameplay_handler.FightCountdown(lobby, data)

            end)
        end,
        unlock = function(lobby, message, user, data)
            if(GameHasFlagRun("Immortal") and not GameHasFlagRun("player_died"))then

                --print("Received unlock message, attempting to unlock player.")

                --player_helper.immortal(false)

                GameRemoveFlagRun("Immortal")

                gameplay_handler.AllowFiring(data)
                --message_handler.send.RequestWandUpdate(lobby, data)
                networking.send.request_wand_update(lobby)
                if(data.countdown ~= nil)then
                    data.countdown:cleanup()
                    data.countdown = nil
                end
            end
        end,
        character_position = function(lobby, message, user, data)
            if(not gameplay_handler.CheckPlayer(lobby, user, data))then
                return
            end

            if(GameHasFlagRun("player_is_unlocked") and (not GameHasFlagRun("no_shooting")))then

                local x, y = message[1], message[2]

                local entity = data.players[tostring(user)].entity
                if(entity ~= nil and EntityGetIsAlive(entity))then
                    local characterData = EntityGetFirstComponentIncludingDisabled(entity, "CharacterDataComponent")

                    ComponentSetValue2(characterData, "mVelocity", message[3], message[4])

                    if((ModSettingGet("evaisa.arena.predictive_netcode") or false) == true)then
                        local delay = math.floor(data.players[tostring(user)].delay_frames / 2) or 0

                        --[[
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

                        if(#data.players[tostring(user)].previous_positions >= 5)then
                            table.remove(data.players[tostring(user)].previous_positions, 1)
                        end
                        table.insert(data.players[tostring(user)].previous_positions, {x = x, y = y} )

                        EntitySetTransform(entity, new_x, new_y)
                        EntityApplyTransform(entity, new_x, new_y)
                        ]]

                        EntitySetTransform(entity, x, y)
                        EntityApplyTransform(entity, x, y)
                    else
                        EntitySetTransform(entity, x, y)
                        EntityApplyTransform(entity, x, y)
                    end
  

                end
            end
        end,
        handshake = function(lobby, message, user, data)
            steamutils.sendToPlayer("handshake_confirmed", {message[1], message[2]}, user, true)
        end,
        handshake_confirmed = function(lobby, message, user, data)
            if(data.players[tostring(user)] ~= nil)then

                data.players[tostring(user)].ping = game_funcs.GetUnixTimeElapsed(game_funcs.StringToUint(message[2]), game_funcs.GetUnixTimestamp())
                data.players[tostring(user)].delay_frames = GameGetFrameNum() - message[1]
            end
        end,
        wand_update = function(lobby, message, user, data)
            
            if(not gameplay_handler.CheckPlayer(lobby, user, data))then
                return
            end

            if(data.players[tostring(user)].entity and EntityGetIsAlive(data.players[tostring(user)].entity))then

                local wand_string = message[2]

                local last_inventory_string = data.players[tostring(user)].last_inventory_string

                if(last_inventory_string == nil)then
                    last_inventory_string = ""
                end

                if(last_inventory_string ~= wand_string)then

                    if(data.players[tostring(user)].entity and EntityGetIsAlive(data.players[tostring(user)].entity))then
                        local items = GameGetAllInventoryItems( data.players[tostring(user)].entity ) or {}
                        for i,item_id in ipairs(items) do
                            GameKillInventoryItem( data.players[tostring(user)].entity, item_id )
                            EntityKill(item_id)
                        end
                    end

                    if(message[1] ~= nil)then
                        local username = steam.friends.getFriendPersonaName(user)

                        print("User ["..username.."] received inventory: "..tostring(json.stringify(message[1])))

                        for k, wandInfo in ipairs(message[1])do

                            local x, y = EntityGetTransform(data.players[tostring(user)].entity)

                            local wand = EZWand(wandInfo.data, x, y)
                            if(wand == nil)then
                                return
                            end

                            wand:PickUp(data.players[tostring(user)].entity)

                            
                            local wand_owner = EntityGetName(EntityGetRootEntity(wand.entity_id))

                            print("Wand has been picked up by: ["..tostring(wand_owner).."] was supposed to be: ["..tostring(user).."]")
                            
                            
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

                    data.players[tostring(user)].last_inventory_string = wand_string
                end

            end
        end,
        request_wand_update = function(lobby, message, user, data)
            data.client.previous_wand = nil
            networking.send.wand_update(lobby, data, user, true)
            networking.send.switch_item(lobby, data, user, true)
        end,
        input_update = function(lobby, message, user, data)
            if(not gameplay_handler.CheckPlayer(lobby, user, data))then
                return
            end
            if(GameHasFlagRun("player_is_unlocked") and (not GameHasFlagRun("no_shooting")))then
                if(data.players[tostring(user)] ~= nil and data.players[tostring(user)].entity ~= nil and EntityGetIsAlive(data.players[tostring(user)].entity))then
                    -- set mButtonDownKick to true
                    local controlsComp = EntityGetFirstComponentIncludingDisabled(data.players[tostring(user)].entity, "ControlsComponent")

                    if(controlsComp ~= nil)then

                        --[[
                            Message reference:
                            {
                                kick,
                                fire,
                                fire2,
                                leftClick,
                                rightClick,
                                aim_x,
                                aim_y,
                                aimNormal_x,
                                aimNormal_y,
                                aimNonZero_x,
                                aimNonZero_y,
                                mouse_x,
                                mouse_y,
                                mouseRaw_x,
                                mouseRaw_y,
                                mouseRawPrev_x,
                                mouseRawPrev_y,
                                mouseDelta_x,
                                mouseDelta_y,
                            }
                        ]]

                        local message_data = {
                            kick = message[1],
                            fire = message[2],
                            fire2 = message[3],
                            leftClick = message[4],
                            rightClick = message[5],
                            aim_x = message[6],
                            aim_y = message[7],
                            aimNormal_x = message[8],
                            aimNormal_y = message[9],
                            aimNonZero_x = message[10],
                            aimNonZero_y = message[11],
                            mouse_x = message[12],
                            mouse_y = message[13],
                            mouseRaw_x = message[14],
                            mouseRaw_y = message[15],
                            mouseRawPrev_x = message[16],
                            mouseRawPrev_y = message[17],
                            mouseDelta_x = message[18],
                            mouseDelta_y = message[19],
                        }
                        

                        local controls_data = data.players[tostring(user)].controls

                        if(message_data.kick)then
                            ComponentSetValue2(controlsComp, "mButtonDownKick", true)
                            if(not controls_data.kick)then
                                ComponentSetValue2(controlsComp, "mButtonFrameKick", GameGetFrameNum())
                            end
                            controls_data.kick = true
                        else
                            ComponentSetValue2(controlsComp, "mButtonDownKick", false)
                        end

                        if(message_data.fire)then
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

                        if(message_data.fire2)then
                            ComponentSetValue2(controlsComp, "mButtonDownFire2", true)
                            if(not controls_data.fire2)then
                                ComponentSetValue2(controlsComp, "mButtonFrameFire2", GameGetFrameNum())
                            end
                            controls_data.fire2 = true
                        else
                            ComponentSetValue2(controlsComp, "mButtonDownFire2", false)
                        end
                        
                        if(message_data.leftClick)then
                            ComponentSetValue2(controlsComp, "mButtonDownLeftClick", true)
                            if(not controls_data.leftClick)then
                                ComponentSetValue2(controlsComp, "mButtonFrameLeftClick", GameGetFrameNum())
                            end
                            controls_data.leftClick = true
                        else
                            ComponentSetValue2(controlsComp, "mButtonDownLeftClick", false)
                        end

                        if(message_data.rightClick)then
                            ComponentSetValue2(controlsComp, "mButtonDownRightClick", true)
                            if(not controls_data.rightClick)then
                                ComponentSetValue2(controlsComp, "mButtonFrameRightClick", GameGetFrameNum())
                            end
                            controls_data.rightClick = true
                        else
                            ComponentSetValue2(controlsComp, "mButtonDownRightClick", false)
                        end

                        ComponentSetValue2(controlsComp, "mAimingVector", message_data.aim_x, message_data.aim_y)
                        ComponentSetValue2(controlsComp, "mAimingVectorNormalized", message_data.aimNormal_x, message_data.aimNormal_y)
                        ComponentSetValue2(controlsComp, "mAimingVectorNonZeroLatest", message_data.aimNonZero_x, message_data.aimNonZero_y)
                        ComponentSetValue2(controlsComp, "mMousePosition", message_data.mouse_x, message_data.mouse_y)
                        ComponentSetValue2(controlsComp, "mMousePositionRaw", message_data.mouseRaw_x, message_data.mouseRaw_y)
                        ComponentSetValue2(controlsComp, "mMousePositionRawPrev", message_data.mouseRawPrev_x, message_data.mouseRawPrev_y)
                        ComponentSetValue2(controlsComp, "mMouseDelta", message_data.mouseDelta_x, message_data.mouseDelta_y)

                        -- get cursor entity
                        local children = EntityGetAllChildren(data.players[tostring(user)].entity) or {}
                        for i,child in ipairs(children) do
                            if(EntityGetName(child) == "cursor")then
                                EntitySetTransform(child, message_data.mouse_x, message_data.mouse_y)
                                EntityApplyTransform(child, message_data.mouse_x, message_data.mouse_y)
                            end
                        end
                    end
                end
            end
        end,
        animation_update = function(lobby, message, user, data)
            if(not gameplay_handler.CheckPlayer(lobby, user, data))then
                return
            end

            if(message[1] ~= nil and message[1] ~= "")then
                local entity = data.players[tostring(user)].entity
                if(entity ~= nil)then
                    local spriteComp = EntityGetFirstComponent(entity, "SpriteComponent", "character")
                    if(spriteComp ~= nil)then
                        local lastRect = ComponentGetValue2(spriteComp, "rect_animation")

                        if (lastRect == message[1]) then
                            return
                        end

                        GamePlayAnimation( entity, message[1], 1 )

                    end
                end
            end
        end,
        switch_item = function(lobby, message, user, data)
            if(not gameplay_handler.CheckPlayer(lobby, user, data))then
                return
            end

            --GlobalsSetValue(tostring(wand.entity_id).."_wand", wandInfo.id)
            local id = message[1]
            if(data.players[tostring(user)].entity and EntityGetIsAlive(data.players[tostring(user)].entity))then

                local items = GameGetAllInventoryItems( data.players[tostring(user)].entity ) or {}
                for i,item in ipairs(items) do
                    -- check id
                    local item_id = tonumber(GlobalsGetValue(tostring(item).."_wand")) or -1
                    if(item_id == id)then

                        local inventory2Comp = EntityGetFirstComponentIncludingDisabled(data.players[tostring(user)].entity, "Inventory2Component")
                        local mActiveItem = ComponentGetValue2(inventory2Comp, "mActiveItem")

                        if(mActiveItem ~= item)then
                            game_funcs.SetActiveHeldEntity(data.players[tostring(user)].entity, item, false, false)
                        end
                        return
                    end
                end

            end
        end,
        sync_wand_stats = function(lobby, message, user, data)

            if(not gameplay_handler.CheckPlayer(lobby, user, data))then
                return
            end
            if(GameHasFlagRun("player_is_unlocked") and (not GameHasFlagRun("no_shooting")))then
                if(data.players[tostring(user)].entity and EntityGetIsAlive(data.players[tostring(user)].entity))then
                    local inventory2Comp = EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component")
                    local mActiveItem = ComponentGetValue2(inventory2Comp, "mActiveItem")
                
                    if(mActiveItem ~= nil)then
                        --[[
                            local msg_data = {
                                mana,
                                GameGetFrameNum() - cast_delay_start_frame, 
                                mReloadFramesLeft = reload_frames_left,
                                mReloadNextFrameUsable = reload_next_frame_usable - GameGetFrameNum(),
                                mNextChargeFrame = next_charge_frame - GameGetFrameNum(),
                            }
                        ]]

                        local mana = message[1]
                        local mCastDelayStartFrame = GameGetFrameNum() - message[2]
                        local mReloadFramesLeft = message[3]
                        local mReloadNextFrameUsable = message[4] + GameGetFrameNum()
                        local mNextChargeFrame = message[5] + GameGetFrameNum()

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
        health_update = function(lobby, message, user, data)
            local health = message[1]
            local maxHealth = message[2]

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


                if(data.players[tostring(user)].hp_bar)then
                    data.players[tostring(user)].hp_bar:setHealth(health, maxHealth)
                else
                    local hp_bar = healthbar.create(health, maxHealth, 18, 2)
                    data.players[tostring(user)].hp_bar = hp_bar
                end
            end

            data.players[tostring(user)].health = health
            data.players[tostring(user)].max_health = maxHealth
        end,
        perk_update = function(lobby, message, user, data)
            print("Received perk update!!")
            print(json.stringify(message[1]))
            data.players[tostring(user)].perks = message[1]
        end,
        fire_wand = function(lobby, message, user, data)
            if(not gameplay_handler.CheckPlayer(lobby, user, data))then
                return
            end

            if(GameHasFlagRun("player_is_unlocked") and (not GameHasFlagRun("no_shooting")) and data.players[tostring(user)].entity ~= nil and EntityGetIsAlive(data.players[tostring(user)].entity))then
            
                data.players[tostring(user)].can_fire = true

                GlobalsSetValue("shooter_rng_"..tostring(user), tostring(message[4]))

                data.players[tostring(user)].projectile_rng_stack = message[3]

                local controlsComp = EntityGetFirstComponentIncludingDisabled(data.players[tostring(user)].entity, "ControlsComponent")

                if(controlsComp ~= nil)then
                    local inventory2Comp = EntityGetFirstComponentIncludingDisabled(data.players[tostring(user)].entity, "Inventory2Component")
                    
                    if(inventory2Comp == nil)then
                        return
                    end
                    
                    local mActiveItem = ComponentGetValue2(inventory2Comp, "mActiveItem")

                    if(mActiveItem ~= nil)then
                            
                        

                        local aimNormal_x, aimNormal_y = ComponentGetValue2(controlsComp, "mAimingVectorNormalized")
                        local aim_x, aim_y = ComponentGetValue2(controlsComp, "mAimingVector")

                        local wand_x, wand_y = EntityGetTransform(mActiveItem)

                        local x = wand_x + (aimNormal_x * 2)
                        local y = wand_y + (aimNormal_y * 2)
                        y = y - 1

                        local target_x = x + aim_x
                        local target_y = y + aim_y

                        EntityHelper.BlockFiring(data.players[tostring(user)].entity, false)

                        EntitySetTransform(mActiveItem, message[1], message[2])
                        EntityApplyTransform(mActiveItem, message[1], message[2])

                        EntityAddTag(data.players[tostring(user)].entity, "player_unit")
                        np.UseItem(data.players[tostring(user)].entity, mActiveItem, true, true, true, x, y, target_x, target_y)
                        EntityRemoveTag(data.players[tostring(user)].entity, "player_unit")

                        EntityHelper.BlockFiring(data.players[tostring(user)].entity, true)
                    end
                end
            end
        end,
        death = function(lobby, message, user, data)
            local username = steam.friends.getFriendPersonaName(user)

            local killer = message[1]
            -- iterate data.tweens backwards and remove tweens belonging to the dead player
            for i = #data.tweens, 1, -1 do
                local tween = data.tweens[i]
                if(tween.id == tostring(user))then
                    table.remove(data.tweens, i)
                end
            end

            --print(json.stringify(killer))

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
        zone_update = function(lobby, message, user, data)
            GlobalsSetValue("arena_area_size", tostring(message[1]))
            GlobalsSetValue("arena_area_size_cap", tostring(message[1] + 200))
            data.zone_size = message[1]
            data.shrink_time = message[2]
        end,
        request_perk_update = function(lobby, message, user, data)
            print("Attempting to send perk update")
            local perk_info = {}
            for i,perk_data in ipairs(perk_list) do
                local perk_id = perk_data.id
                local flag_name = get_perk_picked_flag_name( perk_id )

                local pickup_count = tonumber( GlobalsGetValue( flag_name .. "_PICKUP_COUNT", "0" ) )

                if GameHasFlagRun( flag_name ) or ( pickup_count > 0 ) then
                    --print("Has flag: " .. perk_id)
                    table.insert( perk_info, {perk_id, pickup_count} )
                end
            end

            if(#perk_info > 0)then
                local message_data = {perk_info}

                print("Replied to perk requests!")
                steamutils.sendToPlayer("perk_update", message_data, user, true)

            end
        end,
    },
    send = {
        handshake = function(lobby)
            steamutils.send("handshake", {GameGetFrameNum(), (game_funcs.UintToString(game_funcs.GetUnixTimestamp()))},  steamutils.messageTypes.OtherPlayers, lobby, true)
        end,
        request_perk_update = function(lobby)
            print("Requesting perk update")
            steamutils.send("request_perk_update", {}, steamutils.messageTypes.OtherPlayers, lobby, true)
        end,
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
        character_position = function(lobby, data)
            local player = player.Get()
            if(player)then
                local x, y = EntityGetTransform(player)
                local characterData = EntityGetFirstComponentIncludingDisabled(player, "CharacterDataComponent")
                local vel_x, vel_y = ComponentGetValue2(characterData, "mVelocity")
 
                steamutils.send("character_position", {x, y, vel_x, vel_y}, steamutils.messageTypes.OtherPlayers, lobby, false)
            end
        end,
        wand_update = function(lobby, data, user, force)
            local wandString = player.GetWandString()
            if(wandString ~= nil)then
                if(force or (wandString ~= data.client.previous_wand))then
                    local wandData = player.GetWandData()
                    if(wandData ~= nil)then
                        --GamePrint("Sending wand data to player")
                        local data = {wandData, wandString}
                        if force then
                            table.insert(data, true)
                        end
                        if(user ~= nil)then
                            --steamutils.sendDataToPlayer({type = "wand_update", wandData = wandData}, user)
                            steamutils.sendToPlayer("wand_update", data, user, true)
                        else
                            --steamutils.sendData({type = "wand_update", wandData = wandData}, steamutils.messageTypes.OtherPlayers, lobby)
                            steamutils.send("wand_update", data, steamutils.messageTypes.OtherPlayers, lobby, true)
                        end
                    end
                    data.client.previous_wand = wandString
                end
            else
                if(force or (data.client.previous_wand ~= nil))then
                    
                    if(user ~= nil)then
                        --steamutils.sendDataToPlayer({type = "wand_update"}, user)
                        steamutils.sendToPlayer("wand_update", {}, user, true)
                    else
                        --steamutils.sendData({type = "wand_update"}, steamutils.messageTypes.OtherPlayers, lobby) 
                        steamutils.send("wand_update", {}, steamutils.messageTypes.OtherPlayers, lobby, true)
                    end
                    data.client.previous_wand = nil
                end
            end
        end,
        request_wand_update = function(lobby)
            steamutils.send("request_wand_update", {}, steamutils.messageTypes.OtherPlayers, lobby, true)
        end,
        input_update = function(lobby)
            local controls = player.GetControlsComponent()
            if(controls ~= nil)then
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
                    kick,
                    fire,
                    fire2,
                    leftClick,
                    rightClick,
                    aim_x,
                    aim_y,
                    aimNormal_x,
                    aimNormal_y,
                    aimNonZero_x,
                    aimNonZero_y,
                    mouse_x,
                    mouse_y,
                    mouseRaw_x,
                    mouseRaw_y,
                    mouseRawPrev_x,
                    mouseRawPrev_y,
                    mouseDelta_x,
                    mouseDelta_y,
                }

                steamutils.send("input_update", data, steamutils.messageTypes.OtherPlayers, lobby, false)

            end
        end,
        animation_update = function(lobby, data)
            local rectAnim = player.GetAnimationData()
            if(rectAnim ~= nil)then
                if(rectAnim ~= data.client.previous_anim)then
                    steamutils.send("animation_update", {rectAnim}, steamutils.messageTypes.OtherPlayers, lobby, true)
                    data.client.previous_anim = rectAnim
                end
            end
        end,
        switch_item = function(lobby, data, user, force)
            local held_item = player.GetActiveHeldItem()
            if(held_item ~= nil)then
                if(force or user ~= nil or held_item ~= data.client.previous_selected_item)then
                    local wand_id = tonumber(GlobalsGetValue(tostring(held_item).."_wand")) or -1
                    if(wand_id ~= -1)then
                        if(user == nil)then
                            steamutils.send("switch_item", {wand_id}, steamutils.messageTypes.OtherPlayers, lobby, true)
                            data.client.previous_selected_item = held_item
                        else
                            steamutils.sendToPlayer("switch_item", {wand_id}, user, true)
                        end
                    end
                end
            end
        end,
        sync_wand_stats = function(lobby, data)
            local held_item = player.GetActiveHeldItem()
            if(held_item ~= nil)then
                -- if has ability component
                local abilityComp = EntityGetFirstComponentIncludingDisabled(held_item, "AbilityComponent")
                if(abilityComp)then
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

                        local msg_data = {
                            mana,
                            GameGetFrameNum() - cast_delay_start_frame, 
                            mReloadFramesLeft = reload_frames_left,
                            mReloadNextFrameUsable = reload_next_frame_usable - GameGetFrameNum(),
                            mNextChargeFrame = next_charge_frame - GameGetFrameNum(),
                        }

                        steamutils.send("sync_wand_stats", msg_data, steamutils.messageTypes.OtherPlayers, lobby, false)
                    end

                    
                end
            end
        end,
        health_update = function(lobby, data, force)
            local health, max_health = player.GetHealthInfo()

            if((data.client.previous_max_hp ~= max_health or data.client.previous_hp ~= health) or force)then
                steamutils.send("health_update", {health, max_health}, steamutils.messageTypes.OtherPlayers, lobby, true)
                data.client.previous_max_hp = max_health
                data.client.previous_hp = health
            end
        end,
        perk_update = function(lobby, data)
            local perk_info = {}
            for i,perk_data in ipairs(perk_list) do
                local perk_id = perk_data.id
                local flag_name = get_perk_picked_flag_name( perk_id )

                local pickup_count = tonumber( GlobalsGetValue( flag_name .. "_PICKUP_COUNT", "0" ) )

                if GameHasFlagRun( flag_name ) or ( pickup_count > 0 ) then
                    --print("Has flag: " .. perk_id)
                    table.insert( perk_info, {perk_id, pickup_count} )
                end
            end

            if(#perk_info > 0)then
                local message_data = {perk_info}
                local perk_string = bitser.dumps(message_data)
                if(perk_string ~= data.client.previous_perk_string)then
                    print("Sent perk update!!")
                    steamutils.send("perk_update", message_data, steamutils.messageTypes.OtherPlayers, lobby, true)
                    data.client.previous_perk_string = perk_string
                end
            end
        end,
        fire_wand = function(lobby, rng, special_seed, cast_state)
            local player = player.Get()
            if(player)then
                local wand = EntityHelper.GetHeldItem(player)

                if(wand ~= nil)then

                    local x, y = EntityGetTransform(wand)
                    
                    local data = {
                        x,
                        y,
                        rng,
                        special_seed
                    }

                    steamutils.send("fire_wand", data, steamutils.messageTypes.OtherPlayers, lobby, false)

                end
            end
        end,
        death = function(lobby, killer)
            steamutils.send("death", {killer}, steamutils.messageTypes.OtherPlayers, lobby, true)
        end,
        zone_update = function(lobby, zone_size, shrink_time)
            steamutils.send("zone_update", {zone_size, shrink_time}, steamutils.messageTypes.OtherPlayers, lobby, false)
        end,
    },
}

return networking