local steamutils = dofile_once("mods/evaisa.mp/lib/steamutils.lua")
local player = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/player.lua")
local entity = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/entity.lua")
local counter = dofile_once("mods/evaisa.arena/files/scripts/utilities/ready_counter.lua")
local countdown = dofile_once("mods/evaisa.arena/files/scripts/utilities/countdown.lua")
local json = dofile("mods/evaisa.arena/lib/json.lua")
dofile_once("mods/evaisa.arena/content/data.lua")

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
        player.Deserialize(data.client.serialized_player)
        np.RegisterPlayerEntityId(current_player)
    end,
    AllowFiring = function()
        GameRemoveFlagRun("no_shooting")
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

            if(data.deaths == 0)then
                GameAddFlagRun("first_death")
                print("You will be compensated for your being the first one to die.")
            end

            data.deaths = data.deaths + 1
            data.client.alive = false

            message_handler.send.Death(lobby, killer)

            GameRemoveFlagRun("player_died")

            GamePrintImportant("You died!")

            GameSetCameraFree(true)

            player.Lock()
            player.Immortal(true)
            player.Move(-3000, -3000)

            ArenaGameplay.WinnerCheck(lobby, data)
        end
    end,
    LoadLobby = function(lobby, data, show_message, first_entry)
        show_message = show_message or false
        first_entry = first_entry or false

        local current_player = player.Get()

        if(current_player == nil)then
            ArenaGameplay.LoadPlayer(lobby, data)
        end

        if(first_entry and player.Get())then
            GameDestroyInventoryItems( player.Get() )
        end

        -- clean other player's data
        ArenaGameplay.CleanMembers(lobby, data)

        -- manage flags
        GameRemoveFlagRun("player_ready")
        GameRemoveFlagRun("ready_check")
        GameRemoveFlagRun("player_unloaded")
        GameAddFlagRun("in_hm")

        -- destroy active tweens
        data.tweens = {}
        
        -- clean local data
        data.client.ready = false
        data.client.alive = true
        data.client.previous_wand = nil
        data.client.previous_anim = nil
        data.client.projectile_seeds = {}
        data.client.projectile_homing = {}

        -- set state
        data.state = "lobby"

        -- clean and unlock player entity
        player.Clean(first_entry)
        player.Unlock()

        -- grant immortality
        player.Immortal(true)

        -- move player to correct position
        player.Move(174, 133)

        -- get rounds
        local rounds = ArenaGameplay.GetNumRounds()

        -- Give gold
        local rounds_limited = math.max(0, math.min(math.ceil(rounds / 2), 7))
        player.GiveGold(400 + (70 * (rounds_limited * rounds_limited)))

        -- increment holy mountain count
        ArenaGameplay.AddRound()

        -- give starting gear if first entry
        if(first_entry)then
            player.GiveStartingGear()
        end

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
        show_message = show_message or false

        playermenu:Close()

        -- manage flags
        GameRemoveFlagRun("ready_check")
        GameRemoveFlagRun("first_death")
        GameRemoveFlagRun("in_hm")

        data.state = "arena"
        data.preparing = true
        data.players_loaded = false
        data.deaths = 0

        message_handler.send.SendPerks(lobby)

        ArenaGameplay.PreventFiring()

        -- load map
        local arena = arena_list[data.random.range(1, #arena_list)]
        BiomeMapLoad_KeepPlayer( arena.biome_map, arena.pixel_scenes )

        player.Lock()

        -- move player to correct position
        data.spawn_point = arena.spawn_points[data.random.range(1, #arena.spawn_points)]

        ArenaGameplay.LoadClientPlayers(lobby, data)

        GamePrint("Loading arena")
    end,
    ReadyCheck = function(lobby, data)
        return ArenaGameplay.ReadyAmount(data, lobby) >= ArenaGameplay.TotalPlayers(lobby)
    end,
    CleanMembers = function(lobby, data)
        local members = steamutils.getLobbyMembers(lobby)
        
        for _, member in pairs(members)do
            if(member.id ~= steam.user.getSteamID())then
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
            message_handler.send.UpdateHp(lobby)
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
            ArenaGameplay.AllowFiring()
            data.countdown = nil
        end)
    end,
    SpawnClientPlayer = function(lobby, user, data)
        local client = EntityLoad("mods/evaisa.arena/files/entities/client.xml", 0, 0)
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
                local spawn_point = spawn_points[Random(1, #spawn_points)]
                local x, y = EntityGetTransform(spawn_point)

                data.preparing = false
                player.Move(x, y)

                GamePrint("Spawned!!")
                
                if(not steamutils.IsOwner(lobby))then
                    message_handler.send.Loaded(lobby)
                end

                message_handler.send.Health(lobby)
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
        game_funcs.RenderOffScreenMarkers(player_entities)
        game_funcs.RenderAboveHeadMarkers(player_entities, 0, 27)
        ArenaGameplay.UpdateHealthbars(data)
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
        if(GameGetFrameNum() % 2 == 0)then
            message_handler.send.CharacterUpdate(lobby)
        end
        if(GameGetFrameNum() % 60 == 0)then
            steamutils.sendData({type = "handshake"}, steamutils.messageTypes.OtherPlayers, lobby)
            ArenaGameplay.DamageZoneCheck(0, 0, 600, 800)
        end
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
        for k, v in ipairs(data.players)do
            if(v.entity ~= nil and EntityGetIsAlive(v.entity))then
                local controls_comp = EntityGetFirstComponentIncludingDisabled(v.entity, "ControlsComponent")
                if(controls_comp ~= nil)then
                    local controls = ComponentGetValue2(controls_comp, "mControls")
                    if(controls ~= nil)then
                        ComponentSetValue2(controls, "mButtonDownKick", false)
                        ComponentSetValue2(controls, "mButtonDownFire", false)
                        ComponentSetValue2(controls, "mButtonDownFire2", false)
                        ComponentSetValue2(controls, "mButtonDownLeftClick", false)
                        ComponentSetValue2(controls, "mButtonDownRightClick", false)
                    end
                end
            end
        end


        if((not GameHasFlagRun("player_unloaded")) and player.Get() and (GameGetFrameNum() % 30 == 0))then
            data.client.serialized_player = player.Serialize()

        end

        if(data.state == "lobby")then
            ArenaGameplay.LobbyUpdate(lobby, data)
        elseif(data.state == "arena")then
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
    OnProjectileFired = function(lobby, data, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message)
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

                        local homingComponents = EntityGetComponentIncludingDisabled(projectile_id, "HomingComponent")

                        if(homingComponents ~= nil)then
                            -- pick a random target player
                            local targetPlayer = ArenaGameplay.ClosestPlayer(position_x, position_y)

                            --GamePrint("targetPlayer: "..tostring(targetPlayer))

                            if(targetPlayer ~= nil)then
                                local targetPlayerEntity = data.players[targetPlayer].entity
                                for k, v in pairs(homingComponents)do
                                    local target_who_shot = ComponentGetValue2(v, "target_who_shot")
                                    if(target_who_shot == false)then
                                        if(targetPlayerEntity ~= nil)then
                                            ComponentSetValue2(v, "predefined_target", targetPlayerEntity)
                                            ComponentSetValue2(v, "target_tag", "mortal")
                                        end
                                    end
                                    --GamePrint("Setting homing target to: "..tostring(targetPlayerEntity))
                                end
                                data.client.projectile_homing[projectile_id] = targetPlayerEntity
                                --steamutils.sendData({type = "player_fired_wand", rng = rng, target = targetPlayer}, steamutils.messageTypes.OtherPlayers, lobby)
                                message_handler.send.WandFired(lobby, rng, targetPlayer)
                            else
                                --steamutils.sendData({type = "player_fired_wand", rng = rng}, steamutils.messageTypes.OtherPlayers, lobby)
                                message_handler.send.WandFired(lobby, rng)
                            end
                            
                        else
                            --steamutils.sendData({type = "player_fired_wand", rng = rng}, steamutils.messageTypes.OtherPlayers, lobby)
                            message_handler.send.WandFired(lobby, rng)
                        end
                    else
                        if(data.client.projectile_seeds[entity_that_shot])then
                            local new_seed = data.client.projectile_seeds[entity_that_shot] + 10
                            np.SetProjectileSpreadRNG(new_seed)
                            data.client.projectile_seeds[entity_that_shot] = data.client.projectile_seeds[entity_that_shot] + 1
                            data.client.projectile_seeds[projectile_id] = new_seed
                        end
                        if(data.client.projectile_homing[entity_that_shot])then
                            local homingComponents = EntityGetComponentIncludingDisabled(projectile_id, "HomingComponent")

                            if(homingComponents ~= nil)then
                                for k, v in pairs(homingComponents)do
                                    local target_who_shot = ComponentGetValue2(v, "target_who_shot")
                                    if(target_who_shot == false)then
                                        if(data.client.projectile_homing[entity_that_shot] ~= nil)then
                                            ComponentSetValue2(v, "predefined_target", data.client.projectile_homing[entity_that_shot])
                                            ComponentSetValue2(v, "target_tag", "mortal")
                                        end
                                    end
                                end
                                data.client.projectile_homing[projectile_id] = data.client.projectile_homing[entity_that_shot]
                            end
                        end
                    end
                    return
                end
            end

            if(EntityGetName(shooter_id) ~= nil and tonumber(EntityGetName(shooter_id)))then
                if(data.players[EntityGetName(shooter_id)] and data.players[EntityGetName(shooter_id)].next_rng)then
                    --GamePrint("Setting RNG: "..tostring(arenaPlayerData[EntityGetName(shooter_id)].next_rng))
                    local projectileComponent = EntityGetFirstComponentIncludingDisabled(projectile_id, "ProjectileComponent")

                    local who_shot = ComponentGetValue2(projectileComponent, "mWhoShot")
                    local entity_that_shot  = ComponentGetValue2(projectileComponent, "mEntityThatShot")
                    if(entity_that_shot == 0)then
                        np.SetProjectileSpreadRNG(data.players[EntityGetName(shooter_id)].next_rng)
                        data.client.projectile_seeds[projectile_id] = data.players[EntityGetName(shooter_id)].next_rng
                        local target = data.players[EntityGetName(shooter_id)].target
                        
                        if(target)then
                            --GamePrint("Setting homing target to: "..tostring(target))
                            local homingComponents = EntityGetComponentIncludingDisabled(projectile_id, "HomingComponent")

                            if(homingComponents ~= nil and data.players[target])then
                                local targetPlayerEntity = data.players[target].entity
                                for k, v in pairs(homingComponents)do
                                    local target_who_shot = ComponentGetValue2(v, "target_who_shot")
                                    if(target_who_shot == false)then
                                        if(targetPlayerEntity ~= nil)then
                                            ComponentSetValue2(v, "predefined_target", targetPlayerEntity)
                                            ComponentSetValue2(v, "target_tag", "mortal")
                                        end
                                    end
                                end
                                data.client.projectile_homing[projectile_id] = targetPlayerEntity
                            end
                        end
                    else
                        if(data.client.projectile_seeds[entity_that_shot])then
                            local new_seed = data.client.projectile_seeds[entity_that_shot] + 10
                            np.SetProjectileSpreadRNG(new_seed)
                            data.client.projectile_seeds[entity_that_shot] = data.client.projectile_seeds[entity_that_shot] + 1
                        end
                        if(data.client.projectile_homing[entity_that_shot])then
                            local homingComponents = EntityGetComponentIncludingDisabled(projectile_id, "HomingComponent")

                            if(homingComponents ~= nil)then
                                for k, v in pairs(homingComponents)do
                                    local target_who_shot = ComponentGetValue2(v, "target_who_shot")
                                    if(target_who_shot == false)then
                                        if(data.client.projectile_homing[entity_that_shot] ~= nil)then
                                            ComponentSetValue2(v, "predefined_target", data.client.projectile_homing[entity_that_shot])
                                            ComponentSetValue2(v, "target_tag", "mortal")
                                        end
                                    end
                                end
                                data.client.projectile_homing[projectile_id] = data.client.projectile_homing[entity_that_shot]
                            end
                        end
                    end
                end
                return
            end
        end
    end,
    OnProjectileFiredPost = function(lobby, data, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message)
        if(data.client.projectile_homing[projectile_id])then
            local homingComponents = EntityGetComponentIncludingDisabled(projectile_id, "HomingComponent")

            if(homingComponents ~= nil)then
                for k, v in pairs(homingComponents)do
                    local target_who_shot = ComponentGetValue2(v, "target_who_shot")
                    if(target_who_shot == false)then
                        ComponentSetValue2(v, "predefined_target", data.client.projectile_homing[projectile_id])
                        ComponentSetValue2(v, "target_tag", "mortal")
                    end
                end
            end
        end
    end,
    LateUpdate = function(lobby, data)
        if(data.state == "arena")then
            ArenaGameplay.KillCheck(lobby, data)
        end
        local current_player = player.Get()

        if((not GameHasFlagRun("player_unloaded")) and current_player == nil)then
            ArenaGameplay.LoadPlayer(lobby, data)
        end

        if(data.current_player ~= current_player)then
            data.current_player = current_player
            np.RegisterPlayerEntityId(current_player)
        end

        for k, v in ipairs(data.players)do
            if(v.entity ~= nil and EntityGetIsAlive(v.entity))then
                local controls_comp = EntityGetFirstComponentIncludingDisabled(v.entity, "ControlsComponent")
                if(controls_comp ~= nil)then
                    local controls = ComponentGetValue2(controls_comp, "mControls")
                    if(controls ~= nil)then
                        if(ComponentGetValue2(controls, "mButtonDownKick") == false)then
                            data.players.controls.kick = false
                        end
                        -- mButtonDownFire
                        if(ComponentGetValue2(controls, "mButtonDownFire") == false)then
                            data.players.controls.fire = false
                        end
                        -- mButtonDownFire2
                        if(ComponentGetValue2(controls, "mButtonDownFire2") == false)then
                            data.players.controls.fire2 = false
                        end
                        -- mButtonDownLeft
                        if(ComponentGetValue2(controls, "mButtonDownLeftClick") == false)then
                            data.players.controls.leftClick = false
                        end
                        -- mButtonDownRight
                        if(ComponentGetValue2(controls, "mButtonDownRightClick") == false)then
                            data.players.controls.rightClick = false
                        end
                    end
                end
            end
        end
    end,
}

return ArenaGameplay