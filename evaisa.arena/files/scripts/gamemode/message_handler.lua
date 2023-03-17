local steamutils = dofile_once("mods/evaisa.mp/lib/steamutils.lua")
local player = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/player.lua")
local playerinfo = dofile("mods/evaisa.arena/files/scripts/gamemode/playerinfo.lua")
local healthbar = dofile("mods/evaisa.arena/files/scripts/utilities/health_bar.lua")
local tween = dofile("mods/evaisa.arena/lib/tween.lua")
local Vector = dofile("mods/evaisa.arena/lib/vector.lua")
local json = dofile("mods/evaisa.arena/lib/json.lua")
local EZWand = dofile("mods/evaisa.arena/files/scripts/utilities/EZWand.lua")
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
                    EntityInflictDamage(data.players[tostring(user)].entity, damage, "DAMAGE_SLICE", "damage_fake", "NORMAL", 0, 0, nil)
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
            gameplay_handler.AllowFiring()
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
            
            local platformShooterPlayerComponent = EntityGetFirstComponentIncludingDisabled(data.players[tostring(user)].entity, "PlatformShooterPlayerComponent")
            ComponentSetValue2(platformShooterPlayerComponent, "mForceFireOnNextUpdate", true)

            data.players[tostring(user)].next_rng = message.rng
            if(message.target)then
                data.players[tostring(user)].target = message.target
            end
        end,
        character_update = function(lobby, message, user, data)
            if(not gameplay_handler.CheckPlayer(lobby, user, data))then
                return
            end

            local entity = data.players[tostring(user)].entity
            if(entity ~= nil and EntityGetIsAlive(entity))then
                local x, y = EntityGetTransform(entity)
                local characterData = EntityGetFirstComponentIncludingDisabled(entity, "CharacterDataComponent")

                --local vel_x, vel_y = ComponentGetValue2(characterData, "mVelocity")

                --EntitySetTransform(entity, message.x, message.y, message.r, message.w, message.h)
                --EntityApplyTransform(entity, message.x, message.y, message.r, message.w, message.h)

                ComponentSetValue2(characterData, "mVelocity", message.vel_x, message.vel_y)

                
                local positionTween = tween.vector(Vector.new(x, y), Vector.new(message.x, message.y), 2, function(value)
                    local newPlayerEntity = data.players[tostring(user)].entity
                    if(newPlayerEntity ~= nil and EntityGetIsAlive(newPlayerEntity))then
                        EntitySetTransform(newPlayerEntity, value.x, value.y, message.r, message.w, message.h)
                        EntityApplyTransform(newPlayerEntity, value.x, value.y, message.r, message.w, message.h)
                        --GamePrint("Updating client position")
                    end
                end)
    
                positionTween.id = tostring(user)

                table.insert(data.tweens, positionTween)

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
        end,
        wand_update = function(lobby, message, user, data)
            --print(message.wandData)

            if(not gameplay_handler.CheckPlayer(lobby, user, data))then
                return
            end

            local x, y = EntityGetTransform(data.players[tostring(user)].entity)

            local wand = EZWand(message.wandData, x, y)
            if(wand == nil)then
                return
            end

            -- kill old held item
            if(data.players[tostring(user)].entity and EntityGetIsAlive(data.players[tostring(user)].entity))then
                local items = GameGetAllInventoryItems( data.players[tostring(user)].entity ) or {}
                for i,item_id in ipairs(items) do
                    GameKillInventoryItem( data.players[tostring(user)].entity, item_id )
                    EntityKill(item_id)
                end
            end

            data.players[tostring(user)].held_item = wand.entity_id
            
            --local x, y = EntityGetTransform(data.players[tostring(user)].entity)

            GamePrint("Picking up wand for " .. tostring(user) .. " (" .. tostring(wand.entity_id) .. ")")

            --EntityAddTag(data.players[tostring(user)].entity, "player_unit")
            wand:PickUp(data.players[tostring(user)].entity)
            --GamePickUpInventoryItem(data.players[tostring(user)].entity, wand.entity_id, false)
            --EntityRemoveTag(data.players[tostring(user)].entity, "player_unit")

            -- set mActiveItem
            --[[
            local inventory2 = EntityGetFirstComponentIncludingDisabled(data.players[tostring(user)].entity, "Inventory2Component")
            if(inventory2 ~= nil)then
                ComponentSetValue2(inventory2, "mActiveItem", wand.entity_id)
                ComponentSetValue2(inventory2, "mActualActiveItem", wand.entity_id)
                ComponentSetValue2( inventory2, "mInitialized", false );
                ComponentSetValue2( inventory2, "mForceRefresh", true );
            end
            ]]

            if(DebugGetIsDevBuild())then
                EntitySave(data.players[tostring(user)].entity, "player_" .. tostring(user) .. ".xml")
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

                        GamePlayAnimation( entity, message.rectAnim, 1 )
                        --GamePrint("Animation set to " .. message.rectAnim)
                    end
                end
            end
        end,
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
        perk_info = function(lobby, message, user, data)
            --print("Received perk info: "..json.stringify(message.perks))
            data.players[tostring(user)].perks = message.perks
        end,
    },
    send = {
        Handshake = function(lobby)
            steamutils.sendData({type = "handshake"}, steamutils.messageTypes.OtherPlayers, lobby)
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
        WandFired = function(lobby, rng, target)
            steamutils.sendData({type = "wand_fired", rng = rng, target = target}, steamutils.messageTypes.OtherPlayers, lobby)
        end,
        CharacterUpdate = function(lobby)
            local player = player.Get()
            if(player)then
                local x, y, r, w, h = EntityGetTransform(player)
                local characterData = EntityGetFirstComponentIncludingDisabled(player, "CharacterDataComponent")
                local vel_x, vel_y = ComponentGetValue2(characterData, "mVelocity")
                
                steamutils.sendData({type = "character_update", x = x, y = y, r = r, w = w, h = h, vel_x = vel_x, vel_y = vel_y}, steamutils.messageTypes.OtherPlayers, lobby)
            end
        end,
        WandUpdate = function(lobby, data)
            local wandData = player.GetWandData()
            if(wandData ~= nil)then
                if(wandData ~= data.client.previous_wand)then
                    local wandDataMana = player.GetWandDataMana()
                    steamutils.sendData({type = "wand_update", wandData = wandDataMana}, steamutils.messageTypes.OtherPlayers, lobby)
                    data.client.previous_wand = wandData
                end
            end
        end,
        AnimationUpdate = function(lobby, data)
            local rectAnim = player.GetAnimationData()
            if(rectAnim ~= nil)then
                if(rectAnim ~= data.client.previous_anim)then
                    steamutils.sendData({type = "animation_update", rectAnim = rectAnim}, steamutils.messageTypes.OtherPlayers, lobby)
                    data.client.previous_anim = rectAnim
                end
            end
        end,
        AimUpdate = function(lobby)
            local aim = player.GetAimData()
            if(aim ~= nil)then
                steamutils.sendData({type = "aim_update", aimData = aim}, steamutils.messageTypes.OtherPlayers, lobby)
            end
        end,
        SendPerks = function(lobby)
            --GamePrint("Sending perks!")
            local perk_info = {}
            for i,perk_data in ipairs(perk_list) do
                local perk_id = perk_data.id
                if(perks_allowed[perk_id] == nil or perks_allowed[perk_id] ~= false)then
                    if (((( perk_data.one_off_effect == nil ) or ( perk_data.one_off_effect == false )) and perk_data.usable_by_enemies) or perks_allowed[perk_id] == true) then
                        local flag_name = get_perk_picked_flag_name( perk_id )

                        --print("Checking flag " .. flag_name)
                        
                        local pickup_count = tonumber( GlobalsGetValue( flag_name .. "_PICKUP_COUNT", "0" ) )
                        
                        --print(tostring(GameHasFlagRun( flag_name )))

                        if GameHasFlagRun( flag_name ) or ( pickup_count > 0 ) then
                            --print("Has flag: " .. perk_id)
                            table.insert( perk_info, { perk_id, pickup_count } )
                        end
                    end
                end
            end
            if(#perk_info > 0)then
                steamutils.sendData({type = "perk_info", perks = perk_info}, steamutils.messageTypes.OtherPlayers, lobby)
            end
        end,
        UpdateHp = function(lobby)
            local health, max_health = player.GetHealthInfo()
            steamutils.sendData({type = "update_hp", health = health, max_health = max_health}, steamutils.messageTypes.OtherPlayers, lobby)
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