-------------------------------------------------------------
----- SPAGHETTI AHEAD ------ BE WARNED ----------------------
-------------------------------------------------------------
------ I am sorry but noita API is pain ---------------------
-------------------------------------------------------------


dofile_once("data/scripts/lib/utilities.lua")
steamutils = dofile_once("mods/evaisa.mp/lib/steamutils.lua")
local tween = dofile_once("mods/evaisa.arena/lib/tween.lua")
Vector = dofile_once("mods/evaisa.arena/lib/vector.lua")
local json = dofile_once("mods/evaisa.arena/lib/json.lua")
local countdown = dofile_once("mods/evaisa.arena/files/scripts/utils/countdown.lua")
local counter = dofile_once("mods/evaisa.arena/files/scripts/utils/ready_counter.lua")
local rng = dofile_once("mods/evaisa.arena/lib/rng.lua")
local healthbar = dofile_once("mods/evaisa.arena/files/scripts/utils/health_bar.lua")
locked = true

dofile_once( "data/scripts/perks/perk_list.lua" )

local random = nil
dofile_once("mods/evaisa.arena/files/scripts/utils/utilities.lua")
arenaPlayerData = {}
arenaPlayerEntities = {}
playerPerks = {}
activeTweens = {}
selfReady = false
selfAlive = true
deaths = 0
seed = 0
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
        if(arenaPlayerData[tostring(user)].hp_bar)then
            arenaPlayerData[tostring(user)].hp_bar:destroy()
            arenaPlayerData[tostring(user)].hp_bar = nil
        end
    end
end

local function CreatePlayerData(user)
    arenaPlayerData[tostring(user)] = {item = nil, ready = false, alive = true}
    if(arenaPlayerData[tostring(user)].hp_bar)then
        arenaPlayerData[tostring(user)].hp_bar:destroy()
        arenaPlayerData[tostring(user)].hp_bar = nil
    end
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

function give_perk( entity_who_picked, perk_id, amount )
	-- fetch perk info ---------------------------------------------------
	
    local pos_x, pos_y

    pos_x, pos_y = EntityGetTransform( entity_who_picked )

	local perk_data = get_perk_with_id( perk_list, perk_id )
	if perk_data == nil then
		return
	end

	local no_remove = perk_data.do_not_remove or false

	-- add a game effect or two
	if perk_data.game_effect ~= nil then
		local game_effect_comp,game_effect_entity = GetGameEffectLoadTo( entity_who_picked, perk_data.game_effect, true )
		if game_effect_comp ~= nil then
			ComponentSetValue( game_effect_comp, "frames", "-1" )
			
			if ( no_remove == false ) then
				ComponentAddTag( game_effect_comp, "perk_component" )
				EntityAddTag( game_effect_entity, "perk_entity" )
			end
		end
	end
	
	if perk_data.game_effect2 ~= nil then
		local game_effect_comp,game_effect_entity = GetGameEffectLoadTo( entity_who_picked, perk_data.game_effect2, true )
		if game_effect_comp ~= nil then
			ComponentSetValue( game_effect_comp, "frames", "-1" )
			
			if ( no_remove == false ) then
				ComponentAddTag( game_effect_comp, "perk_component" )
				EntityAddTag( game_effect_entity, "perk_entity" )
			end
		end
	end
	
	-- particle effect only applied once
	if perk_data.particle_effect ~= nil and ( amount <= 1 ) then
		local particle_id = EntityLoad( "data/entities/particles/perks/" .. perk_data.particle_effect .. ".xml" )
		
		if ( no_remove == false ) then
			EntityAddTag( particle_id, "perk_entity" )
		end
		
		EntityAddChild( entity_who_picked, particle_id )
	end
	

	if perk_data.func ~= nil then
		perk_data.func( entity_item, entity_who_picked, perk_id, amount )
	end
	
    --GamePrint( "Picked up perk: " .. perk_data.name )
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
    if(playerPerks[tostring(user)])then
        GamePrint("Giving perks to " .. tostring(user))
        for k, v in ipairs(playerPerks[tostring(user)])do
            local perk = v[1]
            local count = v[2]
            
            for i = 1, count do
                give_perk(client, perk, i)
            end
        end
    end
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
        locked = true
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
        --print("Wand: " .. tostring(wand))
    end

end


local function SpawnPlayer(x, y, randomize)
    randomize = randomize or false

    if(randomize)then
        x, y = get_spawn_pos(0, 100, x, y)
    end

    --[[KillPlayer()

    local player = EntityLoad("data/entities//player.xml", x, y)
    EntitySetName(player, tostring(steam.user.getSteamID()))
    ModSettingSet("projectile_count_" .. tostring(steam.user.getSteamID()), 0)]]

    local player = EntityGetWithTag("player_unit") or {}
    if(player == nil or #player == 0)then
        return
    end

    for k, v in pairs(player)do
        ClearGameEffects(v)
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

active_ready_counter = nil

local function LobbyCounter(lobby)
    active_ready_counter = counter.create("Players ready: ", function()
        local playersReady = AmountReady()
        local totalPlayers = TotalPlayers(lobby)
        
        return playersReady, totalPlayers
    end, function()
        active_ready_counter = nil
    end)
end

local function SendPerkData(lobby)
    local perk_info = {}
	for i,perk_data in ipairs(perk_list) do
		local perk_id = perk_data.id
		if ((( perk_data.one_off_effect == nil ) or ( perk_data.one_off_effect == false )) and perk_data.usable_by_enemies) then

			local flag_name = get_perk_picked_flag_name( perk_id )
			local pickup_count = tonumber( GlobalsGetValue( flag_name .. "_PICKUP_COUNT", "0" ) )
			
			if GameHasFlagRun( flag_name ) or ( pickup_count > 0 ) then
				table.insert( perk_info, { perk_id, pickup_count } )
			end
		end
	end
    if(#perk_info > 0)then
        steamutils.sendData({type = "perk_info", perks = perk_info}, steamutils.messageTypes.OtherPlayers, lobby)
    end
end

local PrepareForSpawn = false

local function LoadArena(lobby)
    GameRemoveFlagRun("first_death")
    arenaGameState = "arena"
    GamePrint("Attempting to load arena")
    GameRemoveFlagRun("in_hm")
    deaths = 0
    selfAlive = true
    lastWandData = nil
    lastRectAnim = nil
    FixReadyState(lobby)
    BiomeMapLoad_KeepPlayer( "mods/evaisa.arena/files/scripts/biome_map_arena.lua", "mods/evaisa.arena/files/biome/arena_scenes.xml" )
    SpawnPlayer(0, 0)
    PrepareForSpawn = true

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

    local holyMountainCount = tonumber(GlobalsGetValue("holyMountainCount", "0"))
    holyMountainCount = holyMountainCount + 1
    GlobalsSetValue("holyMountainCount", tostring(holyMountainCount))

    local owner = steam.matchmaking.getLobbyOwner(lobby)
    if(owner == steam.user.getSteamID())then
        steam.matchmaking.setLobbyData(lobby, "round", holyMountainCount)
    end

    GameRemoveFlagRun("ready_check")
    GameAddFlagRun("Immortal")
    arenaGameState = "lobby"
    lastWandData = nil
    lastRectAnim = nil
    activeTweens = {}
    playerPerks = {}
    show_message = show_message or false
    PreparePlayers(lobby)
    UnlockPlayer()
    SpawnPlayer(174, 133)
    KillPlayers()
    BiomeMapLoad_KeepPlayer( "mods/evaisa.arena/files/scripts/biome_map_holymountain.lua", "mods/evaisa.arena/files/biome/holymountain_scenes.xml" )
    
    local round = math.max(0, math.min(math.ceil(holyMountainCount / 2), 7) - 1)


    
    GiveGold(400 + (40 * (round * round)))
    if(show_message)then
        GamePrintImportant("You have entered the holy mountain", "Prepare to enter the arena.")
    end
    LobbyCounter(lobby)
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

function AmountReady()
    local amount = selfReady and 1 or 0
    for k, v in pairs(arenaPlayerData)do
        if(v.ready)then
            amount = amount + 1
        end
    end
    return amount
end

function TotalPlayers(lobby)
    local amount = 0
    for k, v in pairs(steamutils.getLobbyMembers(lobby))do
        amount = amount + 1
    end
    return amount
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

        GamePrintImportant(steam.friends.getFriendPersonaName(winner) .. " won this round!", "Prepare for the next round in your holy mountain.")

        LoadHolyMountain(lobby)
        selfAlive = true
    elseif(alive == 0)then

        GamePrintImportant("Nobody won this round!", "Prepare for the next round in your holy mountain.")

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

        if(deaths == 0)then
            GameAddFlagRun("first_death")
            print("You will be compensated for your being the first one to die.")
        end

        deaths = deaths + 1

        steamutils.sendData({type = "player_died", killer = killer}, steamutils.messageTypes.OtherPlayers, lobby)
        GameRemoveFlagRun("player_died")
        ModSettingRemove("killer")
        GamePrintImportant("You died!")
        selfAlive = false
        GameAddFlagRun("Immortal")
        GameSetCameraFree(true)
        LockPlayer()
        MovePlayerOut()
        CheckForWinner(lobby)
    end 
end

local function DamageZoneCheck(x, y, max_distance, distance_cap)
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
end

active_countdown = nil

local function FightCountdown(lobby)
    active_countdown = countdown.create({
        "mods/evaisa.arena/files/sprites/ui/countdown/ready.png",
        "mods/evaisa.arena/files/sprites/ui/countdown/3.png",
        "mods/evaisa.arena/files/sprites/ui/countdown/2.png",
        "mods/evaisa.arena/files/sprites/ui/countdown/1.png",
        "mods/evaisa.arena/files/sprites/ui/countdown/fight.png",
    }, 60, function()
        steamutils.sendData({type = "unlock"}, steamutils.messageTypes.OtherPlayers, lobby)
        if(locked)then
            UnlockPlayer()
            GameRemoveFlagRun("Immortal")
        end
        active_countdown = nil
    end)
end

local function HandleData(lobby, data, user)
    local username = steam.friends.getFriendPersonaName(user)
    if(data.type)then
        if(data.type == "seed")then
            local owner = steam.matchmaking.getLobbyOwner(lobby)
            if(owner == user)then
                seed = data.seed
                --GamePrint("Seed set to " .. tostring(seed))
            end
            return
        elseif(data.type == "perk_info")then
            --print(json.stringify(data))
            playerPerks[tostring(user)] = data.perks
            --GamePrint("Perk data received")
            return
        elseif(data.type == "unlock")then

            if(locked)then
                UnlockPlayer()
                GameRemoveFlagRun("Immortal")
            end
            
            GamePrint("Unlocked players")

            locked = false

        end
        local playerData = arenaPlayerData[tostring(user)]
        local function CheckPlayer()
            if(arenaPlayerEntities[tostring(user)] == nil and playerData and playerData.alive)then
                spawnPlayer(user, {x = data.x, y = data.y})
                return false
            end
            return true
        end
        local playerEntity = arenaPlayerEntities[tostring(user)]
        if(data.type == "character_update")then

            if(not CheckPlayer())then
                return
            end

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

            if(not CheckPlayer())then
                return
            end


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

            if(not CheckPlayer())then
                return
            end


            if(playerEntity ~= nil)then
                if(data.aimData)then
                    SetAimData(playerEntity, data.aimData)
                end
            end
        elseif(data.type == "wand_update")then

            if(not CheckPlayer())then
                return
            end


            --GamePrint("Wand data changed")
            if(playerEntity ~= nil)then
                --print(data.wandData)

                SetWandData(user, playerEntity, data.wandData)

            end
        elseif(data.type == "player_fired_wand")then

            if(not CheckPlayer())then
                return
            end


            --GamePrint("Player: " .. tostring(user) .. " fired wand")
            if(playerEntity ~= nil)then
                local platformShooterPlayerComponent = EntityGetFirstComponentIncludingDisabled(playerEntity, "PlatformShooterPlayerComponent")
                ComponentSetValue2(platformShooterPlayerComponent, "mForceFireOnNextUpdate", true)

                arenaPlayerData[tostring(user)].next_rng = data.rng
                if(data.target)then
                    arenaPlayerData[tostring(user)].target = data.target
                    GamePrint("Received target: " .. tostring(data.target))
                end
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

            if(not CheckPlayer())then
                return
            end


            local killer = data.killer
            activeTweens[tostring(user)] = nil
            KillPlayerData(user)
            deaths = deaths + 1
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
        elseif(data.type == "player_health")then
            if(not CheckPlayer())then
                return
            end

            local x, y = EntityGetTransform(playerEntity)

            local health = data.health
            local maxHealth = data.max_health

            --GamePrint(tostring(username) .. " health: " .. tostring(health) .. "/" .. tostring(maxHealth))

            if(arenaPlayerEntities[tostring(user)] ~= nil)then
                local last_health = maxHealth
                if(arenaPlayerData[tostring(user)].health ~= nil)then
                    last_health = arenaPlayerData[tostring(user)].health
                end
                -- if health is lower than last health, damage client entity
                if(health < last_health)then
                    local damage = last_health - health
                    EntityInflictDamage(arenaPlayerEntities[tostring(user)], damage, "DAMAGE_SLICE", "damage_fake", "BLOOD_SPRAY", 0, 0, nil)
                end
            end

            arenaPlayerData[tostring(user)].health = health

            if(arenaPlayerData[tostring(user)] ~= nil and arenaPlayerData[tostring(user)].hp_bar ~= nil)then
                arenaPlayerData[tostring(user)].hp_bar:setHealth(health, maxHealth)
            else
                local hp_bar = healthbar.create(health, maxHealth, 18, 2)
                arenaPlayerData[tostring(user)].hp_bar = hp_bar
            end
        end
    end
end


local function UpdateHealthbars()
    for k, v in pairs(arenaPlayerData)do
        if(v.hp_bar ~= nil)then
            local playerEntity = arenaPlayerEntities[k]
            if(playerEntity ~= nil)then
                local x, y = EntityGetTransform(playerEntity)
                y = y + 10
                v.hp_bar:update(x, y)
            end
        end
    end
end

local function pickRandomPlayer(include_self, only_alive)
    local players = {}
    if(include_self)then
        table.insert(players, tostring(steam.user.getSteamID()))
    end
    for k, v in pairs(arenaPlayerData)do
        if((v.alive and arenaPlayerEntities[k] ~= nil and EntityGetIsAlive(arenaPlayerEntities[k])) or not only_alive)then
            table.insert(players, k)
        end
    end

    if(#players > 0)then
        return players[random.range(1, #players)]
    end

    return nil
end

local function pickClosestPlayer(x, y)
    closest = EntityGetClosestWithTag(x, y, "client")
    if(closest ~= nil)then
        return EntityGetName(closest)
    end

    return nil
end

local projectile_seeds = {}
local projectile_homing = {}

arenaMode = {
    name = "Arena",
    version = 0.119,
    enter = function(lobby) -- Runs when the player enters a lobby
        local owner = steam.matchmaking.getLobbyOwner(lobby)

        GameRemoveFlagRun("ready_check")

        for k, v in pairs(arenaPlayerData)do
            KillPlayerData(k)
        end

        random = rng.new((os.time() + GameGetFrameNum()) / 2)

        
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
        local owner = steam.matchmaking.getLobbyOwner(lobby)
        if(owner == steam.user.getSteamID())then
            steam.matchmaking.setLobbyData(lobby, "round", "0")
        end

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

        local rounds = steam.matchmaking.getLobbyData(lobby, "round") or "0"

        GlobalsSetValue("holyMountainCount", rounds)


        
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
    on_projectile_fired = function(lobby, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message, unknown1, unknown2, unknown3)
        --GamePrint("fired!")
        if(arenaGameState == "arena")then
            -- check if entity is local player
            local playerEntity = EntityGetWithTag("player_unit")
            if(playerEntity ~= nil and #playerEntity > 0)then
                if(playerEntity[1] == shooter_id)then
                    -- get projectile component
                    local projectileComponent = EntityGetFirstComponentIncludingDisabled(projectile_id, "ProjectileComponent")

                    local who_shot = ComponentGetValue2(projectileComponent, "mWhoShot")
                    local entity_that_shot  = ComponentGetValue2(projectileComponent, "mEntityThatShot")
        
                    if(entity_that_shot == 0)then
                        --math.randomseed( tonumber(tostring(steam.user.getSteamID())) + ((os.time() + GameGetFrameNum()) / 2))
                        local rand = random.range(0, 100000)
                        local rng = math.floor(rand)
                        --GamePrint("Setting RNG: "..tostring(rng))
                        np.SetProjectileSpreadRNG(rng)

                        projectile_seeds[projectile_id] = rng
                        --GamePrint("generated_rng: "..tostring(rng))

                        local homingComponents = EntityGetComponentIncludingDisabled(projectile_id, "HomingComponent")

                        if(homingComponents ~= nil)then
                            -- pick a random target player
                            local targetPlayer = pickClosestPlayer(position_x, position_y)

                            --GamePrint("targetPlayer: "..tostring(targetPlayer))

                            if(targetPlayer ~= nil)then
                                local targetPlayerEntity = arenaPlayerEntities[targetPlayer]
                                for k, v in pairs(homingComponents)do
                                    local target_who_shot = ComponentGetValue2(v, "target_who_shot")
                                    if(target_who_shot == false)then
                                        ComponentSetValue2(v, "predefined_target", targetPlayerEntity)
                                        ComponentSetValue2(v, "target_tag", "mortal")
                                    end
                                    GamePrint("Setting homing target to: "..tostring(targetPlayerEntity))
                                end
                                projectile_homing[projectile_id] = targetPlayerEntity
                                steamutils.sendData({type = "player_fired_wand", rng = rng, target = targetPlayer}, steamutils.messageTypes.OtherPlayers, lobby)
                            else
                                steamutils.sendData({type = "player_fired_wand", rng = rng}, steamutils.messageTypes.OtherPlayers, lobby)
                            end
                            
                        else
                            steamutils.sendData({type = "player_fired_wand", rng = rng}, steamutils.messageTypes.OtherPlayers, lobby)
                        end

                        
                    else
                        if(projectile_seeds[entity_that_shot])then
                            local new_seed = projectile_seeds[entity_that_shot] + 10
                            np.SetProjectileSpreadRNG(new_seed)
                            projectile_seeds[entity_that_shot] = projectile_seeds[entity_that_shot] + 1
                            projectile_seeds[projectile_id] = new_seed
                        end
                        if(projectile_homing[entity_that_shot])then
                            local homingComponents = EntityGetComponentIncludingDisabled(projectile_id, "HomingComponent")

                            if(homingComponents ~= nil)then
                                for k, v in pairs(homingComponents)do
                                    local target_who_shot = ComponentGetValue2(v, "target_who_shot")
                                    if(target_who_shot == false)then
                                        ComponentSetValue2(v, "predefined_target", projectile_homing[entity_that_shot])
                                        ComponentSetValue2(v, "target_tag", "mortal")
                                    end
                                end
                                projectile_homing[projectile_id] = projectile_homing[entity_that_shot]
                            end
                        end
                    end
                    return
                end
            end

            if(tonumber(EntityGetName(shooter_id)))then
                if(arenaPlayerData[EntityGetName(shooter_id)] and arenaPlayerData[EntityGetName(shooter_id)].next_rng)then
                    --GamePrint("Setting RNG: "..tostring(arenaPlayerData[EntityGetName(shooter_id)].next_rng))
                    local projectileComponent = EntityGetFirstComponentIncludingDisabled(projectile_id, "ProjectileComponent")

                    local who_shot = ComponentGetValue2(projectileComponent, "mWhoShot")
                    local entity_that_shot  = ComponentGetValue2(projectileComponent, "mEntityThatShot")
                    if(entity_that_shot == 0)then
                        np.SetProjectileSpreadRNG(arenaPlayerData[EntityGetName(shooter_id)].next_rng)
                        projectile_seeds[projectile_id] = arenaPlayerData[EntityGetName(shooter_id)].next_rng
                        local target = arenaPlayerData[EntityGetName(shooter_id)].target
                        
                        if(target)then
                            GamePrint("Setting homing target to: "..tostring(target))
                            local homingComponents = EntityGetComponentIncludingDisabled(projectile_id, "HomingComponent")

                            if(homingComponents ~= nil)then
                                local targetPlayerEntity = arenaPlayerEntities[target]
                                for k, v in pairs(homingComponents)do
                                    local target_who_shot = ComponentGetValue2(v, "target_who_shot")
                                    if(target_who_shot == false)then
                                        ComponentSetValue2(v, "predefined_target", targetPlayerEntity)
                                        ComponentSetValue2(v, "target_tag", "mortal")
                                    end
                                end
                                projectile_homing[projectile_id] = targetPlayerEntity
                            end
                        end
                    else
                        if(projectile_seeds[entity_that_shot])then
                            local new_seed = projectile_seeds[entity_that_shot] + 10
                            np.SetProjectileSpreadRNG(new_seed)
                            projectile_seeds[entity_that_shot] = projectile_seeds[entity_that_shot] + 1
                        end
                        if(projectile_homing[entity_that_shot])then
                            local homingComponents = EntityGetComponentIncludingDisabled(projectile_id, "HomingComponent")

                            if(homingComponents ~= nil)then
                                for k, v in pairs(homingComponents)do
                                    local target_who_shot = ComponentGetValue2(v, "target_who_shot")
                                    if(target_who_shot == false)then
                                        ComponentSetValue2(v, "predefined_target", projectile_homing[entity_that_shot])
                                        ComponentSetValue2(v, "target_tag", "mortal")
                                    end
                                end
                                projectile_homing[projectile_id] = projectile_homing[entity_that_shot]
                            end
                        end
                    end
                end
                return
            end
            
        end
    end,
    on_projectile_fired_post = function(lobby, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message, unknown1, unknown2, unknown3)
        --GamePrint("testa: "..tostring(projectile_id))
        --EntitySave(projectile_id, "projectile_save.xml")
       
        if(projectile_homing[projectile_id])then
            local homingComponents = EntityGetComponentIncludingDisabled(projectile_id, "HomingComponent")

            if(homingComponents ~= nil)then
                for k, v in pairs(homingComponents)do
                    local target_who_shot = ComponentGetValue2(v, "target_who_shot")
                    if(target_who_shot == false)then
                        ComponentSetValue2(v, "predefined_target", projectile_homing[projectile_id])
                        ComponentSetValue2(v, "target_tag", "mortal")
                    end
                end
            end
        end
    end,
    update = function(lobby) -- Runs every frame while the game is in progress.
        local owner = steam.matchmaking.getLobbyOwner(lobby)
        
        killInactiveUsers(lobby)
        local game_funcs = dofile("mods/evaisa.mp/files/scripts/game_functions.lua")

        if(owner == steam.user.getSteamID())then
            if(GameGetFrameNum() % 2 == 0)then
                seed = tostring(math.random(1, 1000000))
                --GamePrint("Setting seed: "..seed)
                steamutils.sendData({type = "seed", seed = seed}, steamutils.messageTypes.OtherPlayers, lobby)
            end
        end

        if(arenaGameState == "arena")then
            
            if(GameGetFrameNum() % 5 == 0)then
                for k, v in pairs(projectile_seeds)do
                    if(not EntityGetIsAlive(k))then
                        projectile_seeds[k] = nil
                        projectile_homing[k] = nil
                    end
                end
            end

            if(active_countdown ~= nil)then
                active_countdown:update()
            end

            if(GameHasFlagRun("took_damage"))then
                GameRemoveFlagRun("took_damage")

                -- get player health
                local playerEntity = EntityGetWithTag("player_unit")
                if(playerEntity ~= nil and #playerEntity > 0)then
                    local healthComp = EntityGetFirstComponentIncludingDisabled(playerEntity[1], "DamageModelComponent")
                    local health = ComponentGetValue2(healthComp, "hp")
                    local max_health = ComponentGetValue2(healthComp, "max_hp")
                    steamutils.sendData({type = "player_health", health = health, max_health = max_health}, steamutils.messageTypes.OtherPlayers, lobby)
                end
            end

            if(PrepareForSpawn)then
                GameAddFlagRun("Immortal")
                local spawn_points = EntityGetWithTag("spawn_point") or {}
                if(spawn_points == nil or #spawn_points == 0)then
                    SpawnPlayer(0, 0)
                else
                    local spawn_point = spawn_points[Random(1, #spawn_points)]
                    local x, y = EntityGetTransform(spawn_point)
                    SpawnPlayer(x, y, true)
                    PrepareForSpawn = false
                    projectile_seeds = {}
                    projectile_homing = {}
                    LockPlayer()
                    FightCountdown(lobby)
                    local playerEntity = EntityGetWithTag("player_unit")
                    if(playerEntity ~= nil and #playerEntity > 0)then
                        local healthComp = EntityGetFirstComponentIncludingDisabled(playerEntity[1], "DamageModelComponent")
                        local health = ComponentGetValue2(healthComp, "hp")
                        local max_health = ComponentGetValue2(healthComp, "max_hp")
                        steamutils.sendData({type = "player_health", health = health, max_health = max_health}, steamutils.messageTypes.OtherPlayers, lobby)
                    end
                end
            end
            game_funcs.RenderOffScreenMarkers(arenaPlayerEntities)
            game_funcs.RenderAboveHeadMarkers(arenaPlayerEntities, 0, 27)

        end
 
        if(GameGetFrameNum() % 60 == 0)then
            steamutils.sendData({type = "handshake"}, steamutils.messageTypes.OtherPlayers, lobby)
            DamageZoneCheck(0, 0, 600, 800)
        end

        

        if(arenaGameState == "lobby")then
            if(GameGetFrameNum() % 3 == 0)then
                SendPerkData(lobby)
            end
            if(active_ready_counter ~= nil)then
                active_ready_counter:update()
            end
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
            UpdateHealthbars()
            updateTweens(lobby)
            if(selfAlive)then
                KillCheck(lobby)
                

                local players = EntityGetWithTag("player_unit")
                if(players ~= nil and #players > 0)then
                    local px, py = EntityGetTransform(players[1])


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