dofile_once("data/scripts/lib/utilities.lua")
steamutils = dofile_once("mods/evaisa.mp/lib/steamutils.lua")
tween = dofile_once("mods/evaisa.arena/lib/tween.lua")
Vector = dofile_once("mods/evaisa.arena/lib/vector.lua")
json = dofile_once("mods/evaisa.arena/lib/json.lua")
arenaPlayerData = {}
arenaPlayerEntities = {}
activeTweens = {}
selfReady = false
local arenaGameState = "lobby"

local function addTween(start_value, end_value, num_frames, callback)
    table.insert(activeTweens, tween.basic(start_value, end_value, num_frames, callback))
end

local function addVectorTween(start_value, end_value, num_frames, callback)
    table.insert(activeTweens, tween.vector(start_value, end_value, num_frames, callback))
end

local function updateTweens()
    -- iterate backwards so we can remove tweens
    for i = #activeTweens, 1, -1 do
        local tween = activeTweens[i]
        if tween:update() then
            table.remove(activeTweens, i)
        end
    end
end

local function KillPlayerData(user)
    if(arenaPlayerData[tostring(user)] ~= nil)then
        EntityKill(arenaPlayerData[tostring(user)].entity)
        if(arenaPlayerData[tostring(user)].item)then
            EntityKill(arenaPlayerData[tostring(user)].item)
        end
        arenaPlayerData[tostring(user)] = nil
        arenaPlayerEntities[tostring(user)] = nil
    end
end

local function spawnPlayer(user, data)
    KillPlayerData(user)
    local client = EntityLoad("mods/evaisa.arena/files/entities/client.xml", data.x, data.y)
    EntitySetName(client, tostring(user))
    ModSettingSet("projectile_count_" .. tostring(user), 0)
    local usernameSprite = EntityGetFirstComponentIncludingDisabled(client, "SpriteComponent", "username")
    local name = steam.friends.getFriendPersonaName(user)
    ComponentSetValue2(usernameSprite, "text", name)
    ComponentSetValue2(usernameSprite, "offset_x", string.len(name) * (1.8))
    arenaPlayerData[tostring(user)] = {entity = client, item = nil, ready = false, alive = true}
    arenaPlayerEntities[tostring(user)] = client
end



local function killInactiveUsers(lobby)
    local members = steamutils.getLobbyMembers(lobby)
    for k, v in pairs(arenaPlayerData)do
        local found = false
        for k2, v2 in pairs(members)do
            if(tostring(v2.id) == k)then
                found = true
                break
            end
        end
        if(not found)then
            KillPlayerData(k)
        end
    end
end
local function IsUserActive(lobby, user)
    local members = steamutils.getLobbyMembers(lobby)
    for k, v in pairs(members)do
        if(v.id == user)then
            return true
        end
    end
    return false
end

local function GetPlayerPosition()
    local player = EntityGetWithTag("player_unit")
    if(player == nil or #player == 0)then
        return 0, 0
    end
    local x, y = EntityGetTransform(player[1])
    return x, y
end

local function GetAnimationData(component)
    local rectAnim = ComponentGetValue2(component, "rect_animation")

    return rectAnim
end

local function SetAnimationData(entity, component, rectAnim)
    local lastRect = ComponentGetValue2(component, "rect_animation")

    if (lastRect == rectAnim) then
        return
    end
    --[[
    ComponentSetValue2(component, "rect_animation", rectAnim)
    EntityRefreshSprite(entity, component)
    ]]

    GamePlayAnimation( entity, rectAnim, 1 )
end

local function GetArmData()
    local player = EntityGetWithTag("player_unit")
    if(player == nil or #player == 0)then
        return nil
    end
    local children = EntityGetAllChildren(player[1])
    local rectAnim = nil
    local x, y, r, w, h;
    for k, v in pairs(children)do
        local name = EntityGetName(v)
        if(name == "arm_r")then
            local arm = v
            local armSprite = EntityGetFirstComponentIncludingDisabled(arm, "SpriteComponent", "with_item")
            rectAnim = ComponentGetValue2(armSprite, "rect_animation")

            x, y, r, w, h = EntityGetTransform(arm)
            break
        end
    end

    if (rectAnim == nil) then
        return nil
    end
    
    return {rectAnim = rectAnim, x = x, y = y, r = r, w = w, h = h}
end

local function SetArmData(entity, arm_data)
    local children = EntityGetAllChildren(entity)
    for k, v in pairs(children)do
        local name = EntityGetName(v)
        if(name == "arm_r")then
            local arm = v
            local armSprite = EntityGetFirstComponentIncludingDisabled(arm, "SpriteComponent", "with_item")
            SetAnimationData(arm, armSprite, arm_data.rectAnim)
            EntitySetTransform(arm, arm_data.x, arm_data.y, arm_data.r, arm_data.w, arm_data.h)
            EntityRefreshSprite(entity, armSprite)
            break
        end
    end
end

local function GetAimData(entity)
    local controlsComp = EntityGetFirstComponentIncludingDisabled(entity, "ControlsComponent")
    local x, y = ComponentGetValue2(controlsComp, "mAimingVector")

    return x and {x = x, y = y} or 0
end

local function SetAimData(entity, aim_data)
    local controlsComp = EntityGetFirstComponentIncludingDisabled(entity, "ControlsComponent")
    ComponentSetValue2(controlsComp, "mAimingVector", aim_data.x, aim_data.y)
end

local function GetLastProjectileData(id)

    print("whar?")

    local id = tostring(id)
    local projectile_count = ModSettingGet("projectile_count_" .. id) or 0

    print("projectile_count: " .. projectile_count)

    if(projectile_count == 0)then
        return nil
    end

    local projectile_data = {
        velocity_x = ModSettingGet("projectile_" .. id .. tostring(projectile_count) .. "velocity_x"),
        velocity_y = ModSettingGet("projectile_" .. id .. tostring(projectile_count) .. "velocity_y"),
        position_x = ModSettingGet("projectile_" .. id .. tostring(projectile_count) .. "position_x"),
        position_y = ModSettingGet("projectile_" .. id .. tostring(projectile_count) .. "position_y")
    }

    ModSettingSet("projectile_count_" .. id, projectile_count - 1)

    print(json.stringify(projectile_data))
    
    return projectile_data
end

local function SetLastProjectileData(user, data)
    local id = tostring(user)
    local projectile_count = ModSettingGet("projectile_count_" .. id) or 0

    projectile_count = projectile_count + 1

    ModSettingSet("projectile_" .. id .. tostring(projectile_count) .. "velocity_x", data.velocity_x)
    ModSettingSet("projectile_" .. id .. tostring(projectile_count) .. "velocity_y", data.velocity_y)
    ModSettingSet("projectile_" .. id .. tostring(projectile_count) .. "position_x", data.position_x)
    ModSettingSet("projectile_" .. id .. tostring(projectile_count) .. "position_y", data.position_y)

    ModSettingSet("projectile_count_" .. id, projectile_count)
end

local EZWand = dofile("mods/evaisa.arena/files/scripts/EZWand.lua")

local function GetWandData()
    local wand = EZWand.GetHeldWand()
    if(wand == nil)then
        return nil
    end
    local wandData = wand:Serialize()
    return wandData
end

local function GetWandDataMana()
    local wand = EZWand.GetHeldWand()
    if(wand == nil)then
        return nil
    end
    local wandData = wand:Serialize(true)
    return wandData
end

local function SetWandData(user, entity, wand_data)
    
    local wand = EZWand(wand_data)
    if(wand == nil)then
        return
    end
    -- kill old wand
    if(arenaPlayerData[tostring(user)].item )then
        GameKillInventoryItem(entity, arenaPlayerData[tostring(user)].item)
        EntityKill(arenaPlayerData[tostring(user)].item)
    end

    arenaPlayerData[tostring(user)].item = wand.entity_id
    
    local x, y = EntityGetTransform(entity)

    wand:PlaceAt(x, y)

    wand:PickUp(entity)
end

local function HandleData(lobby, data, user)
    if(data.type)then
        local playerData = arenaPlayerData[tostring(user)]
        if(playerData == nil)then
            spawnPlayer(user, {x = data.x, y = data.y})
            return
        end
        local playerEntity = playerData.entity
        if(data.type == "character_update")then

            local x, y = EntityGetTransform(playerEntity)
            local characterData = EntityGetFirstComponentIncludingDisabled(playerEntity, "CharacterDataComponent")
            
            local vel_x, vel_y = ComponentGetValue2(characterData, "mVelocity")

            --[[ComponentSetValue2(characterData, "mVelocity", data.velocity_x, data.velocity_y)
            
            EntitySetTransform(playerEntity, data.x, data.y, data.r, data.w, data.h)
            EntityApplyTransform(playerEntity, data.x, data.y, data.r, data.w, data.h)]]

            addVectorTween(Vector.new(x, y), Vector.new(data.x, data.y), 5, function(value)
                EntitySetTransform(playerEntity, value.x, value.y, data.r, data.w, data.h)
                EntityApplyTransform(playerEntity, value.x, value.y, data.r, data.w, data.h)
            end)

            addVectorTween(Vector.new(vel_x, vel_y), Vector.new(data.velocity_x, data.velocity_y), 5, function(value)
                ComponentSetValue2(characterData, "mVelocity", value.x, value.y)
            end)

        elseif(data.type == "character_animation")then

            local sprite = EntityGetFirstComponentIncludingDisabled(playerEntity, "SpriteComponent", "character")
            if(data.rectAnim)then
                SetAnimationData(playerEntity, sprite, data.rectAnim)
            end
            --[[
            if(data.armData)then
                SetArmData(playerEntity, data.armData)
            end
            ]]



        elseif (data.type == "aim_data")then
            if(data.aimData)then
                SetAimData(playerEntity, data.aimData)
            end
        elseif(data.type == "wand_update")then
            --GamePrint("Wand data changed")
            print(data.wandData)

            SetWandData(user, playerEntity, data.wandData)
        elseif(data.type == "player_fired_wand")then
            --GamePrint("Player: " .. tostring(user) .. " fired wand")
            local platformShooterPlayerComponent = EntityGetFirstComponentIncludingDisabled(playerEntity, "PlatformShooterPlayerComponent")
            ComponentSetValue2(platformShooterPlayerComponent, "mForceFireOnNextUpdate", true)
            --[[
            if(data.projectileData ~= nil)then

                print(json.stringify(data.projectileData))

                SetLastProjectileData(user, data.projectileData)
            end
            ]]

            --EntitySave(playerEntity, "player_client.xml")
        elseif(data.type == "player_ready_state")then
            arenaPlayerData[tostring(user)].ready = data.state
            GamePrint("Player: " .. tostring(user) .. " ready state: " .. tostring(data.state))
        end
    end
end

local function KillPlayer()
    -- kill any entity with tag "player_unit"
    local player = EntityGetWithTag("player_unit") or {}
    if(player == nil or #player == 0)then
        return
    end
    for k, v in pairs(player)do
        EntityKill(v)
    end
end

local function CleanAndLockPlayer()
    local player = EntityGetWithTag("player_unit") or {}
    if(player == nil or #player == 0)then
        return
    end
    for k, v in pairs(player)do
        GameDestroyInventoryItems( v )
        -- disable controls component
        local controls = EntityGetFirstComponentIncludingDisabled(v, "ControlsComponent")
        if(controls ~= nil)then
            ComponentSetValue2(controls, "enabled", false)
        end
        local characterDataComponent = EntityGetFirstComponentIncludingDisabled(v, "CharacterDataComponent")
        if(characterDataComponent ~= nil)then
            EntitySetComponentIsEnabled(v, characterDataComponent, false)
        end
        local platformShooterPlayerComponent = EntityGetFirstComponentIncludingDisabled(v, "PlatformShooterPlayerComponent")
        if(platformShooterPlayerComponent ~= nil)then
            EntitySetComponentIsEnabled(v, platformShooterPlayerComponent, false)
        end
    end
end

local function UnlockPlayer()
    local player = EntityGetWithTag("player_unit") or {}
    if(player == nil or #player == 0)then
        return
    end
    for k, v in pairs(player)do
        -- disable controls component
        local controls = EntityGetFirstComponentIncludingDisabled(v, "ControlsComponent")
        if(controls ~= nil)then
            ComponentSetValue2(controls, "enabled", true)
        end
        local characterDataComponent = EntityGetFirstComponentIncludingDisabled(v, "CharacterDataComponent")
        if(characterDataComponent ~= nil)then
            EntitySetComponentIsEnabled(v, characterDataComponent, true)
        end
        local platformShooterPlayerComponent = EntityGetFirstComponentIncludingDisabled(v, "PlatformShooterPlayerComponent")
        if(platformShooterPlayerComponent ~= nil)then
            EntitySetComponentIsEnabled(v, platformShooterPlayerComponent, true)
        end
    end
end

local function GiveStartingGear()
    local player = EntityGetWithTag("player_unit") or {}
    if(player == nil or #player == 0)then
        return
    end
    for k, v in pairs(player)do
        local x, y = EntityGetTransform(v)
        local wand = EntityLoad("data/entities/items/starting_wand_rng.xml", x, y)
        GamePickUpInventoryItem(v, wand, false)
        print("Wand: " .. tostring(wand))
    end

end

local function SpawnPlayer(x, y)
    --[[KillPlayer()

    local player = EntityLoad("data/entities//player.xml", x, y)
    EntitySetName(player, tostring(steam.user.getSteamID()))
    ModSettingSet("projectile_count_" .. tostring(steam.user.getSteamID()), 0)]]

    UnlockPlayer()

    local player = EntityGetWithTag("player_unit") or {}
    if(player == nil or #player == 0)then
        return
    end

    for k, v in pairs(player)do
        EntitySetTransform(v, x, y)
        EntityApplyTransform(v, x, y)
    end
    --EntityLoadToEntity("mods/evaisa.arena/files/entities/player.xml", player)
end

local function LoadArena()
    SpawnPlayer(0, 0)
    BiomeMapLoad_KeepPlayer( "mods/evaisa.arena/files/scripts/biome_map_arena.lua", "mods/evaisa.arena/files/biome/arena_scenes.xml" )
    --BiomeMapLoad_KeepPlayer( "mods/evaisa.arena/files/scripts/biome_map_arena.lua", "mods/evaisa.arena/files/biome/arena_scenes.xml" )
    --[[local players = EntityGetWithTag("player_unit") or {}
    if(players[1])then
        EntityApplyTransform(players[1], 0, 0 )
    end]]
end

local function LoadHolyMountain()
    SpawnPlayer(174, 133)
    BiomeMapLoad_KeepPlayer( "mods/evaisa.arena/files/scripts/biome_map_holymountain.lua", "mods/evaisa.arena/files/biome/holymountain_scenes.xml" )
    --BiomeMapLoad_KeepPlayer( "mods/evaisa.arena/files/scripts/biome_map_holymountain.lua", "mods/evaisa.arena/files/biome/holymountain_scenes.xml" )
    --[[local players = EntityGetWithTag("player_unit") or {}
    if(players[1])then
        EntityApplyTransform(players[1], 0, 0 )
    end]]
end

function HidePlayer(player)
    -- disable controls component
    local controls = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")
    if(controls ~= nil)then
        ComponentSetValue(controls, "enabled", "0")
    end

    local characterDataComponent = EntityGetFirstComponent(player, "CharacterDataComponent")
    if(characterDataComponent ~= nil)then
        EntitySetComponentIsEnabled(player, characterDataComponent, false)
    end

    EntitySetComponentsWithTagEnabled(player, "character", false)
end

function CheckReadyState()
    local ready = selfReady
    for k, v in pairs(arenaPlayerData)do
        if(v.ready == false)then
            ready = false
            break
        end
    end
    return ready
end

arenaMode = {
    name = "Arena",
    version = 1,
    enter = function(lobby) -- Runs when the player enters a lobby
        for k, v in pairs(arenaPlayerData)do
            KillPlayerData(k)
        end
        
        lastWandData = nil

        arenaPlayerData = {}
        game_in_progress = steam.matchmaking.getLobbyData(lobby, "in_progress") == "true"
        if(game_in_progress)then
            arenaMode.start(lobby)
        end
    end,
    start = function(lobby) -- Runs when the host presses the start game button.
        local owner = steam.matchmaking.getLobbyOwner(lobby)

        GamePrint("Starting game...")

        --if(owner == steam.user.getSteamID())then
        --    steam.matchmaking.setLobbyData(lobby, "arena_state", "lobby")
        --end


        arenaGameState = "lobby"
        --[[
        local lobby_state = steam.matchmaking.getLobbyData(lobby, "arena_state")
        --LoadArena()
        if(lobby_state == "arena")then
            LoadArena()
        elseif(lobby_state == "lobby")then
            LoadHolyMountain()
        end
        ]]
        LoadHolyMountain()

        GiveStartingGear()

        local year, month, day, hour, minute, second = GameGetDateAndTimeLocal()

        local num = year + month + day + hour + minute + second

        

        --SetRandomSeed(GameGetFrameNum() + num + tonumber(tostring(steam.user.getSteamID())), GameGetFrameNum() + num + tonumber(tostring(steam.user.getSteamID())))

        --ModSettingSet("projectile_identifier", Random(0, 10000000))

        lastWandData = nil
        lastRectAnim = nil

        local self_x, self_y = GetPlayerPosition()
        local seed = tonumber(steam.matchmaking.getLobbyData(lobby, "seed") or 1)
        for k, v in pairs(arenaPlayerData)do
            KillPlayerData(k)
        end
        local members = steamutils.getLobbyMembers(lobby)
		for k, member in pairs(members)do
            if(member.id ~= steam.user.getSteamID() and arenaPlayerData[tostring(member.id)] == nil)then
                GamePrint("Player spawned: "..tostring(member.id))
                spawnPlayer(member.id, {x = self_x, y = self_y})
            end
        end
    end,
    update = function(lobby) -- Runs every frame while the game is in progress.
        local owner = steam.matchmaking.getLobbyOwner(lobby)
        
        killInactiveUsers(lobby)
        local game_funcs = dofile("mods/evaisa.mp/files/scripts/game_functions.lua")

        if(arenaGameState == "arena")then
            game_funcs.RenderOffScreenMarkers(arenaPlayerEntities)
            game_funcs.RenderAboveHeadMarkers(arenaPlayerEntities, 0, 27)
        --[[else
            for k, v in ipairs(arenaPlayerEntities)do
                EntitySetTransform(v, -100, -100)
                EntityApplyTransform(v, -100, -100)
            end]]
        end

        if(arenaGameState == "lobby")then
            if(CheckReadyState())then
                LoadArena()
                arenaGameState = "arena"
            end
        end

        updateTweens()

        if(GameHasFlagRun("player_ready"))then
            GameRemoveFlagRun("player_ready")
            selfReady = true
            steamutils.sendData({type = "player_ready_state", state = true}, steamutils.messageTypes.OtherPlayers, lobby)
        end

        if(GameHasFlagRun("player_unready"))then
            GameRemoveFlagRun("player_unready")
            selfReady = false
            steamutils.sendData({type = "player_ready_state", state = false}, steamutils.messageTypes.OtherPlayers, lobby)
        end

        --if(lobby_state == "arena")then
            local players = EntityGetWithTag("player_unit")
            if(players ~= nil and #players > 0)then
                local px, py = EntityGetTransform(players[1])

                
                if(GameHasFlagRun("player_fired_wand"))then
                    GameRemoveFlagRun("player_fired_wand")
                    
                    --local projectileData = GetLastProjectileData(steam.user.getSteamID())

                    steamutils.sendData({type = "player_fired_wand", --[[projectile_data = projectileData]]}, steamutils.messageTypes.OtherPlayers, lobby)
                end

                steamutils.sendData({type = "aim_data", aimData = GetAimData(players[1])}, steamutils.messageTypes.OtherPlayers, lobby)
            end
            if(GameGetFrameNum() % 5 == 0)then
                
                if(players ~= nil and #players > 0)then
                    local x, y, r, w, h = EntityGetTransform(players[1])
    
                    local characterData = EntityGetFirstComponentIncludingDisabled(players[1], "CharacterDataComponent")
                    local velocity_x, velocity_y = ComponentGetValue2(characterData, "mVelocity")

                    local rectAnim = GetAnimationData(EntityGetFirstComponentIncludingDisabled(players[1], "SpriteComponent", "character"))
                    lastRectAnim = lastRectAnim or nil
                    lastWandData = lastWandData or nil
                    if(x and y and velocity_x and velocity_y)then
                        steamutils.sendData({
                            is_multi = true,
                            data = {
                                {
                                    type = "character_update", 
                                    x = x, 
                                    y = y, 
                                    r = r, 
                                    w = w, 
                                    h = h, 
                                    velocity_x = velocity_x, 
                                    velocity_y = velocity_y
                                },
                                {
                                    type = "character_animation", 
                                    rectAnim = rectAnim ~= lastRectAnim and rectAnim or nil, 
                                }
                            }
                        }, steamutils.messageTypes.OtherPlayers, lobby)
                    end

                    --local arm_data = GetArmData()


                    local wandData = GetWandData()


                    if(wandData ~= nil)then
                        if(wandData ~= lastWandData)then
                            local wandDataMana = GetWandDataMana()
                            steamutils.sendData({type = "wand_update", wandData = wandDataMana}, steamutils.messageTypes.OtherPlayers, lobby)
                        end
                        lastWandData = wandData
                    end
                    lastRectAnim = rectAnim
                    

                end
            end
        --end
    end,
    late_update = function (lobby)
        if(GameHasFlagRun("player_fired_wand"))then
            GameRemoveFlagRun("player_fired_wand")
                
            --local projectileData = GetLastProjectileData(steam.user.getSteamID())

            steamutils.sendData({type = "player_fired_wand", --[[projectile_data = projectileData]]}, steamutils.messageTypes.OtherPlayers, lobby)
        end
    end,
    leave = function(lobby)
        --KillPlayer()
        CleanAndLockPlayer()
    end,
    message = function(lobby, data, user)
        if(IsUserActive(lobby, user))then
            killInactiveUsers(lobby)

            
            if(data.is_multi)then
                for i, v in ipairs(data.data)do
                    HandleData(lobby, v, user)
                end
            else
                HandleData(lobby, data, user)
            end

            
        end
    end,
}

table.insert(gamemodes, arenaMode)