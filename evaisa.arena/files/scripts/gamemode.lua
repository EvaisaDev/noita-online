dofile_once("data/scripts/lib/utilities.lua")
steamutils = dofile_once("mods/evaisa.mp/lib/steamutils.lua")
arenaPlayerData = {}
arenaPlayerEntities = {}

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
    local usernameSprite = EntityGetFirstComponentIncludingDisabled(client, "SpriteComponent", "username")
    local name = steam.friends.getFriendPersonaName(user)
    ComponentSetValue2(usernameSprite, "text", name)
    ComponentSetValue2(usernameSprite, "offset_x", string.len(name) * (1.8))
    arenaPlayerData[tostring(user)] = {entity = client, item = nil}
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

local EZWand = dofile("mods/evaisa.arena/files/scripts/EZWand.lua")

local function GetWandData()
    local wand = EZWand.GetHeldWand()
    if(wand == nil)then
        return nil
    end
    local wandData = wand:Serialize()
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
            ComponentSetValue2(characterData, "mVelocity", data.velocity_x, data.velocity_y)
            
            EntitySetTransform(playerEntity, data.x, data.y, data.r, data.w, data.h)
            EntityApplyTransform(playerEntity, data.x, data.y, data.r, data.w, data.h)

        elseif(data.type == "character_animation")then

            local sprite = EntityGetFirstComponentIncludingDisabled(playerEntity, "SpriteComponent", "character")
            if(data.rectAnim)then
                SetAnimationData(playerEntity, sprite, data.rectAnim)
            end
        
            if(data.armData)then
                SetArmData(playerEntity, data.armData)
            end

            if(data.aimData ~= 0)then
                SetAimData(playerEntity, data.aimData)
            end

        elseif(data.type == "wand_update")then
            GamePrint("Wand data changed")
            print(data.wandData)

            SetWandData(user, playerEntity, data.wandData)

        end
    end
end

arenaMode = {
    name = "Arena",
    version = 1,
    enter = function(lobby) -- Runs when the player enters a lobby
        for k, v in pairs(arenaPlayerData)do
            KillPlayerData(k)
        end
        
        arenaPlayerData = {}
        game_in_progress = steam.matchmaking.getLobbyData(lobby, "in_progress") == "true"
        if(game_in_progress)then
            arenaMode.start(lobby)
        end
    end,
    start = function(lobby) -- Runs when the host presses the start game button.
        GamePrint("Starting game...")
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
        killInactiveUsers(lobby)
        local game_funcs = dofile("mods/evaisa.mp/files/scripts/game_functions.lua")

        game_funcs.RenderOffScreenMarkers(arenaPlayerEntities)
        game_funcs.RenderAboveHeadMarkers(arenaPlayerEntities, 0, 27)

        if(GameGetFrameNum() % 2 == 0)then
            local players = EntityGetWithTag("player_unit")
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
                                aimData = GetAimData(players[1])
                            }
                        }
                    }, steamutils.messageTypes.OtherPlayers, lobby)
                end

                --local arm_data = GetArmData()

                local wandData = GetWandData()

                if(wandData ~= nil)then
                    if(wandData ~= lastWandData)then
                        steamutils.sendData({type = "wand_update", wandData = wandData}, steamutils.messageTypes.OtherPlayers, lobby)
                    end
                    lastWandData = wandData
                end
                lastRectAnim = rectAnim
                

            end
        end
    end,
    leave = function(lobby)

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