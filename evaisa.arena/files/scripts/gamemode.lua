-------------------------------------------------------------
----- SPAGHETTI AHEAD ------ BE WARNED ----------------------
-------------------------------------------------------------
------ I am sorry but noita API is pain ---------------------
-------------------------------------------------------------


dofile_once("data/scripts/lib/utilities.lua")
steamutils = dofile_once("mods/evaisa.mp/lib/steamutils.lua")
tween = dofile_once("mods/evaisa.arena/lib/tween.lua")
Vector = dofile_once("mods/evaisa.arena/lib/vector.lua")
json = dofile_once("mods/evaisa.arena/lib/json.lua")
arenaPlayerData = {}
arenaPlayerEntities = {}
activeTweens = {}
selfReady = false
selfAlive = true
local arenaGameState = "lobby"

local function updateTweens(lobby)
    local members = steamutils.getLobbyMembers(lobby)
    
    local validMembers = {}

    for _, member in pairs(members)do
        local memberid = tostring(member.id)
        
        validMembers[memberid] = true
    end

    -- iterate active tweens backwards and update
    for i = #activeTweens, 1, -1 do
        local tween = activeTweens[i]
        if(tween)then
            if(validMembers[tween.id] == nil)then
                table.remove(activeTweens, i)
            else
                if(tween:update())then
                    table.remove(activeTweens, i)
                end
            end
        end
    end
end

local function KillPlayerData(user)
    if(arenaPlayerData[tostring(user)] ~= nil)then
        if(arenaPlayerEntities[tostring(user)] and EntityGetIsAlive(arenaPlayerEntities[tostring(user)]))then
            EntityKill(arenaPlayerEntities[tostring(user)])
        end
        if(arenaPlayerData[tostring(user)].item)then
            EntityKill(arenaPlayerData[tostring(user)].item)
        end
        arenaPlayerData[tostring(user)].item = nil
        arenaPlayerEntities[tostring(user)] = nil
    end
end

local function CreatePlayerData(user)
    arenaPlayerData[tostring(user)] = {item = nil, ready = false, alive = true}
end


local function PreparePlayers(lobby)
    local members = steamutils.getLobbyMembers(lobby)
    for k, v in pairs(members)do
        if(v.id ~= steam.user.getSteamID())then
            if(arenaPlayerData[tostring(v.id)] == nil)then
                CreatePlayerData(v.id)
            end
        end
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
    arenaPlayerEntities[tostring(user)] = client
    arenaPlayerData[tostring(user)].alive = true
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
            arenaPlayerData[k] = nil
        end
    end
end

local function KillPlayers()
    for k, v in pairs(arenaPlayerData)do
        KillPlayerData(k)
    end

    arenaPlayerEntities = {}
    activeTweens = {}
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
    if(entity and EntityGetIsAlive(entity))then
        local controlsComp = EntityGetFirstComponentIncludingDisabled(entity, "ControlsComponent")
        ComponentSetValue2(controlsComp, "mAimingVector", aim_data.x, aim_data.y)
    end
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

local function findUser(lobby, user_string)
    local members = steamutils.getLobbyMembers(lobby)
    for k, member in pairs(members)do
        --print("Member: " .. tostring(member.id))
        if(tostring(member.id) == user_string)then
            return member.id
        end
    end
    return nil
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

local function LockPlayer()
    local player = EntityGetWithTag("player_unit") or {}
    if(player == nil or #player == 0)then
        return
    end
    for k, v in pairs(player)do
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

local function MovePlayerOut()
    local player = EntityGetWithTag("player_unit") or {}
    if(player == nil or #player == 0)then
        return
    end
    for k, v in pairs(player)do
        EntityApplyTransform(v, -1000, -1000)
        EntitySetTransform(v, -1000, -1000)
    end
end

local function UnlockPlayer()
    GameSetCameraFree(false)
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

local function LoadPlayers(lobby)
    local self_x, self_y = GetPlayerPosition()

    KillPlayers()

    GamePrintImportant("You have entered the arena", "FIGHT!")

    local members = steamutils.getLobbyMembers(lobby)
    for k, member in pairs(members)do
        if(member.id ~= steam.user.getSteamID() and arenaPlayerEntities[tostring(member.id)] == nil)then
            print("Player spawned: "..tostring(member.id))
            spawnPlayer(member.id, {x = self_x, y = self_y})
        end
    end
end

local function FixReadyState(lobby)
    selfReady = false
    GameRemoveFlagRun("ready_check")
    for k, v in pairs(arenaPlayerData)do
        arenaPlayerData[k].ready = false
    end
end

local function LoadArena(lobby)
    arenaGameState = "arena"
    GamePrint("Attempting to load arena")
    GameRemoveFlagRun("in_hm")
    selfAlive = true
    lastWandData = nil
    lastRectAnim = nil
    FixReadyState(lobby)
    SpawnPlayer(0, 0)
    BiomeMapLoad_KeepPlayer( "mods/evaisa.arena/files/scripts/biome_map_arena.lua", "mods/evaisa.arena/files/biome/arena_scenes.xml" )
    LoadPlayers(lobby)
    
    --[[local players = EntityGetWithTag("player_unit") or {}
    if(players[1])then
        EntityApplyTransform(players[1], 0, 0 )
    end]]
end

local function GiveGold(amount)
    local player = EntityGetWithTag("player_unit") or {}
    if(player == nil or #player == 0)then
        return
    end
    for k, v in pairs(player)do
        local wallet_component = EntityGetFirstComponentIncludingDisabled(v, "WalletComponent")
        local money = ComponentGetValue2(wallet_component, "money")
        local add_amount = amount
        ComponentSetValue2(wallet_component, "money", money + add_amount)
    end
end

local function LoadHolyMountain(lobby, show_message)
    selfReady = false
    GameAddFlagRun("in_hm")
    FixReadyState(lobby)
    GameRemoveFlagRun("ready_check")
    arenaGameState = "lobby"
    lastWandData = nil
    lastRectAnim = nil
    activeTweens = {}
    show_message = show_message or false
    PreparePlayers(lobby)
    SpawnPlayer(174, 133)
    KillPlayers()
    BiomeMapLoad_KeepPlayer( "mods/evaisa.arena/files/scripts/biome_map_holymountain.lua", "mods/evaisa.arena/files/biome/holymountain_scenes.xml" )
    GiveGold(400)
    if(show_message)then
        GamePrintImportant("You have entered the holy mountain", "Prepare to enter the arena.")
    end
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

local function CheckForWinner(lobby)
    local alive = selfAlive and 1 or 0
    local winner = steam.user.getSteamID()
    for k, v in pairs(arenaPlayerData)do
        if(v.alive)then
            alive = alive + 1
            winner = findUser(lobby, k)
        end
    end
    if(alive == 1)then
        local owner = steam.matchmaking.getLobbyOwner(lobby)

        GamePrintImportant(steam.friends.getFriendPersonaName(winner) .. " won this round!", "Prepare for the next round in your holy mountain.")
        if(owner == steam.user.getSteamID())then
            local round = steam.matchmaking.getLobbyData(lobby, "round") or "1"
            round = tonumber(round) + 1
            steam.matchmaking.setLobbyData(lobby, "round", tostring(round))
        end
        LoadHolyMountain(lobby)
        selfAlive = true
    end
end

function KillCheck(lobby)
    if(GameHasFlagRun("player_died"))then
        local killer = ModSettingGet("killer");
        local username = steam.friends.getFriendPersonaName(steam.user.getSteamID())
        if(killer == nil)then
                
            GamePrint(tostring(username) .. " died.")
        else
            local killer_id = findUser(lobby, killer)
            if(killer_id ~= nil)then
                GamePrint(tostring(username) .. " was killed by " .. steam.friends.getFriendPersonaName(killer_id))
            else
                GamePrint(tostring(username) .. " died.")
            end
        end

        steamutils.sendData({type = "player_died", killer = killer}, steamutils.messageTypes.OtherPlayers, lobby)
        GameRemoveFlagRun("player_died")
        ModSettingRemove("killer")
        GamePrintImportant("You died!")
        selfAlive = false
        GameSetCameraFree(true)
        LockPlayer()
        MovePlayerOut()
        CheckForWinner(lobby)
    end 
end



local function HandleData(lobby, data, user)
    local username = steam.friends.getFriendPersonaName(user)
    if(data.type)then
        local playerData = arenaPlayerData[tostring(user)]
        if(arenaPlayerEntities[tostring(user)] == nil and playerData and playerData.alive)then
            spawnPlayer(user, {x = data.x, y = data.y})
            return
        end
        local playerEntity = arenaPlayerEntities[tostring(user)]
        if(data.type == "character_update")then

            local x, y = EntityGetTransform(playerEntity)
            local characterData = EntityGetFirstComponentIncludingDisabled(playerEntity, "CharacterDataComponent")
            
            local vel_x, vel_y = ComponentGetValue2(characterData, "mVelocity")

            --[[
            ComponentSetValue2(characterData, "mVelocity", data.velocity_x, data.velocity_y)
            
            EntitySetTransform(playerEntity, data.x, data.y, data.r, data.w, data.h)
            EntityApplyTransform(playerEntity, data.x, data.y, data.r, data.w, data.h)
            ]]

          
            local positionTween = tween.vector(Vector.new(x, y), Vector.new(data.x, data.y), 2, function(value)
                local newPlayerEntity = arenaPlayerEntities[tostring(user)]
                if(newPlayerEntity ~= nil and EntityGetIsAlive(newPlayerEntity))then
                    EntitySetTransform(playerEntity, value.x, value.y, data.r, data.w, data.h)
                    EntityApplyTransform(playerEntity, value.x, value.y, data.r, data.w, data.h)
                end
            end)

            positionTween.id = tostring(user)

            table.insert(activeTweens, positionTween)

            local velocityTween = tween.vector(Vector.new(vel_x, vel_y), Vector.new(data.velocity_x, data.velocity_y), 2, function(value)
                local newPlayerEntity = arenaPlayerEntities[tostring(user)]
                if(newPlayerEntity ~= nil and EntityGetIsAlive(newPlayerEntity))then
                    local characterData = EntityGetFirstComponentIncludingDisabled(playerEntity, "CharacterDataComponent")
                    ComponentSetValue2(characterData, "mVelocity", value.x, value.y)
                end
            end)

            velocityTween.id = tostring(user)

            table.insert(activeTweens, velocityTween)
            

        elseif(data.type == "character_animation")then

            if(playerEntity ~= nil)then
                local sprite = EntityGetFirstComponentIncludingDisabled(playerEntity, "SpriteComponent", "character")
                if(data.rectAnim)then
                    SetAnimationData(playerEntity, sprite, data.rectAnim)
                end
            end
            --[[
            if(data.armData)then
                SetArmData(playerEntity, data.armData)
            end
            ]]



        elseif (data.type == "aim_data")then
            if(playerEntity ~= nil)then
                if(data.aimData)then
                    SetAimData(playerEntity, data.aimData)
                end
            end
        elseif(data.type == "wand_update")then
            --GamePrint("Wand data changed")
            if(playerEntity ~= nil)then
                --print(data.wandData)

                SetWandData(user, playerEntity, data.wandData)

            end
        elseif(data.type == "player_fired_wand")then
            --GamePrint("Player: " .. tostring(user) .. " fired wand")
            if(playerEntity ~= nil)then
                local platformShooterPlayerComponent = EntityGetFirstComponentIncludingDisabled(playerEntity, "PlatformShooterPlayerComponent")
                ComponentSetValue2(platformShooterPlayerComponent, "mForceFireOnNextUpdate", true)
            end
            --[[
            if(data.projectileData ~= nil)then

                print(json.stringify(data.projectileData))

                SetLastProjectileData(user, data.projectileData)
            end
            ]]

            --EntitySave(playerEntity, "player_client.xml")
        elseif(data.type == "player_ready_state")then
            arenaPlayerData[tostring(user)].ready = data.state
            if(data.state)then
                GamePrint(tostring(username) .. " is ready.")
            else
                GamePrint(tostring(username) .. " is no longer ready.")
            end
        elseif(data.type == "force_arena")then
            if(arenaGameState == "lobby")then
                LoadArena(lobby)
                arenaGameState = "arena"
            end
        elseif(data.type == "player_died")then
            local killer = data.killer
            activeTweens[tostring(user)] = nil
            KillPlayerData(user)
            arenaPlayerData[tostring(user)].alive = false
            if(killer == nil)then
                
                GamePrint(tostring(username) .. " died.")
            else
                local killer_id = findUser(lobby, killer)
                if(killer_id ~= nil)then
                    GamePrint(tostring(username) .. " was killed by " .. steam.friends.getFriendPersonaName(killer_id))
                else
                    GamePrint(tostring(username) .. " died.")
                end
            end
            CheckForWinner(lobby)
        end
    end
end


arenaMode = {
    name = "Arena",
    version = 1,
    enter = function(lobby) -- Runs when the player enters a lobby
        local owner = steam.matchmaking.getLobbyOwner(lobby)

        GameRemoveFlagRun("ready_check")

        for k, v in pairs(arenaPlayerData)do
            KillPlayerData(k)
        end
        
        if(owner == steam.user.getSteamID())then
            steam.matchmaking.setLobbyData(lobby, "round", tostring(1))
        end

        lastWandData = nil

        arenaPlayerData = {}
        game_in_progress = steam.matchmaking.getLobbyData(lobby, "in_progress") == "true"
        if(game_in_progress)then
            arenaMode.start(lobby)
        end
    end,
    start = function(lobby) -- Runs when the host presses the start game button.

        GamePrint("Starting game...")

        --if(owner == steam.user.getSteamID())then
        --    steam.matchmaking.setLobbyData(lobby, "arena_state", "lobby")
        --end

        --ModSettingSet("arena_round", tonumber(steam.matchmaking.getLobbyData(lobby, "round")))

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
        LoadHolyMountain(lobby)

        GiveStartingGear()

        local year, month, day, hour, minute, second = GameGetDateAndTimeLocal()

        local num = year + month + day + hour + minute + second

        steamutils.sendData({type = "handshake"}, steamutils.messageTypes.OtherPlayers, lobby)

        --SetRandomSeed(GameGetFrameNum() + num + tonumber(tostring(steam.user.getSteamID())), GameGetFrameNum() + num + tonumber(tostring(steam.user.getSteamID())))

        --ModSettingSet("projectile_identifier", Random(0, 10000000))

        lastWandData = nil
        lastRectAnim = nil
        local members = steamutils.getLobbyMembers(lobby)
        for k, member in pairs(members)do
            if(member.id ~= steam.user.getSteamID() and arenaPlayerData[tostring(member.id)] == nil)then
                CreatePlayerData(member.id)
            end
        end

    end,
    on_wand_fired = function(lobby, entity, rng)
        --local rng = tonumber(steam.matchmaking.getLobbyData(lobby, "update_seed") or 0)
        --np.SetWandSpreadRNG(rng)
    end,
    update = function(lobby) -- Runs every frame while the game is in progress.
        local owner = steam.matchmaking.getLobbyOwner(lobby)
        
        killInactiveUsers(lobby)
        local game_funcs = dofile("mods/evaisa.mp/files/scripts/game_functions.lua")

        if(arenaGameState == "arena")then
            game_funcs.RenderOffScreenMarkers(arenaPlayerEntities)
            game_funcs.RenderAboveHeadMarkers(arenaPlayerEntities, 0, 27)

        end
 
        if(GameGetFrameNum() % 60 == 0)then
            steamutils.sendData({type = "handshake"}, steamutils.messageTypes.OtherPlayers, lobby)
        end

        

        if(arenaGameState == "lobby")then
            if(CheckReadyState())then
                LoadArena(lobby)
                steamutils.sendData({type = "force_arena"}, steamutils.messageTypes.OtherPlayers, lobby)
                arenaGameState = "arena"
            end
        end

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


        if(arenaGameState == "arena")then

        
            updateTweens(lobby)
            if(selfAlive)then
                KillCheck(lobby)

                local players = EntityGetWithTag("player_unit")
                if(players ~= nil and #players > 0)then
                    local px, py = EntityGetTransform(players[1])

                    
                    if(GameHasFlagRun("player_fired_wand"))then
                        GameRemoveFlagRun("player_fired_wand")
                        
                        --local projectileData = GetLastProjectileData(steam.user.getSteamID())

                        steamutils.sendData({type = "player_fired_wand"}, steamutils.messageTypes.OtherPlayers, lobby)
                    end

                    steamutils.sendData({type = "aim_data", aimData = GetAimData(players[1])}, steamutils.messageTypes.OtherPlayers, lobby)
                end
                if(GameGetFrameNum() % 2 == 0)then
                    
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
            end
        end
    end,
    late_update = function (lobby)
        if(arenaGameState == "arena")then
            KillCheck(lobby)

            if(GameHasFlagRun("player_fired_wand"))then
                GameRemoveFlagRun("player_fired_wand")
                    
                --local projectileData = GetLastProjectileData(steam.user.getSteamID())

                steamutils.sendData({type = "player_fired_wand", --[[projectile_data = projectileData]]}, steamutils.messageTypes.OtherPlayers, lobby)
            end
        end
    end,
    leave = function(lobby)
        --KillPlayer()
        CleanAndLockPlayer()
        arenaPlayerData = {}
        arenaPlayerEntities = {}
        activeTweens = {}
        selfReady = false
        GameRemoveFlagRun("ready_check")
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