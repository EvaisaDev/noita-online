local entity = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/entity.lua")
local EZWand = dofile("mods/evaisa.arena/files/scripts/utilities/EZWand.lua")
dofile_once( "data/scripts/perks/perk_list.lua" )

local player_helper = {}

player_helper.Get = function()
    local player = EntityGetWithTag("player_unit") or {}
    if(player == nil or #player == 0)then
        return
    end
    return player[1]
end

player_helper.Clean = function(clear_inventory)
    local player = player_helper.Get()
    if(player == nil)then
        return
    end
    if(clear_inventory)then
        GameDestroyInventoryItems( player )
    end
    entity.ClearGameEffects(player)
end

player_helper.Lock = function()
    local player = player_helper.Get()
    if(player == nil)then
        return
    end
    local controls = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")
    if(controls ~= nil)then
        ComponentSetValue2(controls, "enabled", false)
    end
    local characterDataComponent = EntityGetFirstComponentIncludingDisabled(player, "CharacterDataComponent")
    if(characterDataComponent ~= nil)then
        EntitySetComponentIsEnabled(player, characterDataComponent, false)
    end
    local platformShooterPlayerComponent = EntityGetFirstComponentIncludingDisabled(player, "PlatformShooterPlayerComponent")
    if(platformShooterPlayerComponent ~= nil)then
        EntitySetComponentIsEnabled(player, platformShooterPlayerComponent, false)
    end
end

player_helper.Unlock = function()
    local player = player_helper.Get()
    if(player == nil)then
        return
    end
    GameSetCameraFree(false)
    local controls = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")
    if(controls ~= nil)then
        ComponentSetValue2(controls, "enabled", true)
    end
    local characterDataComponent = EntityGetFirstComponentIncludingDisabled(player, "CharacterDataComponent")
    if(characterDataComponent ~= nil)then
        EntitySetComponentIsEnabled(player, characterDataComponent, true)
    end
    local platformShooterPlayerComponent = EntityGetFirstComponentIncludingDisabled(player, "PlatformShooterPlayerComponent")
    if(platformShooterPlayerComponent ~= nil)then
        EntitySetComponentIsEnabled(player, platformShooterPlayerComponent, true)
    end
end

player_helper.Move = function( x, y )
    local player = player_helper.Get()
    if(player == nil)then
        return
    end
    EntitySetTransform( player, x, y )
    EntityApplyTransform( player, x, y )
end

player_helper.GiveGold = function( amount )
    local player = player_helper.Get()
    if(player == nil)then
        return
    end
    local wallet_component = EntityGetFirstComponentIncludingDisabled(player, "WalletComponent")
    local money = ComponentGetValue2(wallet_component, "money")
    local add_amount = amount
    ComponentSetValue2(wallet_component, "money", money + add_amount)
end

player_helper.GetGold = function()
    local player = player_helper.Get()
    if(player == nil)then
        return
    end
    local wallet_component = EntityGetFirstComponentIncludingDisabled(player, "WalletComponent")
    local money = ComponentGetValue2(wallet_component, "money")
    return money
end

player_helper.GiveStartingGear = function ()
    local player = player_helper.Get()
    if(player == nil)then
        return
    end
    local x, y = EntityGetTransform(player)
    local wand = EntityLoad("data/entities/items/starting_wand_rng.xml", x, y)
    print("Starting gear granted.")
    GamePickUpInventoryItem(player, wand, false)
end

player_helper.Immortal = function( immortal )
    if(immortal)then
        GameAddFlagRun("Immortal")
    else
        GameRemoveFlagRun("Immortal")
    end
end

player_helper.GetWandData = function()
    --[[
    local wand = EZWand.GetHeldWand()
    if(wand == nil)then
        return nil
    end
    local wandData = wand:Serialize()
    return wandData
    ]]
    local wands = EZWand.GetAllWands()
    if(wands == nil or #wands == 0)then
        return nil
    end

    local player = player_helper.Get()
    local inventory2Comp = EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component")
    local mActiveItem = ComponentGetValue2(inventory2Comp, "mActiveItem")
    local wandData = {}
    for k, v in pairs(wands)do
        local wand_entity = v.entity_id
        local item_comp = EntityGetFirstComponentIncludingDisabled(wand_entity, "ItemComponent")
        local slot_x, slot_y = ComponentGetValue2(item_comp, "inventory_slot")

        GlobalsSetValue(tostring(wand_entity).."_wand", tostring(k))

        table.insert(wandData, {data = v:Serialize(true), id = k, slot_x = slot_x, slot_y = slot_y, active = (mActiveItem == wand_entity)})
    end
    return wandData
end

player_helper.SetWandData = function(wand_data)
    local player = player_helper.Get()
    if(player == nil)then
        return
    end

    if(wand_data ~= nil)then
        for k, wandInfo in ipairs(wand_data)do
    
            local x, y = EntityGetTransform(player)
    
            local wand = EZWand(wandInfo.data, x, y)
            if(wand == nil)then
                return
            end
    
            wand:PickUp(player)
            
            local itemComp = EntityGetFirstComponentIncludingDisabled(wand.entity_id, "ItemComponent")
            if(itemComp ~= nil)then
                ComponentSetValue2(itemComp, "inventory_slot", wandInfo.slot_x, wandInfo.slot_y)
            end
    
            if(wandInfo.active)then
                game_funcs.SetActiveHeldEntity(player, wand.entity_id, false, false)
            end
    
            GlobalsSetValue(tostring(wand.entity_id).."_wand", tostring(wandInfo.id))
            
        end
    end
end

player_helper.GetWandString = function()
    local wands = EZWand.GetAllWands()
    if(wands == nil or #wands == 0)then
        return nil
    end
    local wandDataString = ""
    for k, v in pairs(wands)do
        wandDataString = wandDataString .. v:Serialize()
    end
    return wandDataString
end

player_helper.GetControlsComponent = function()
    local player = player_helper.Get()
    if(player == nil)then
        return
    end
    local controls = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")
    if(controls == nil)then
        return
    end
    return controls
end

player_helper.GetWandDataMana = function()
    --[[
    local wand = EZWand.GetHeldWand()
    if(wand == nil)then
        return nil
    end
    local wandData = wand:Serialize(true)
    return wandData
    ]]
end

player_helper.DidKick = function()
    local player = player_helper.Get()
    if(player == nil)then
        return
    end
    local controls = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")
    if(controls == nil)then
        return
    end
    local mButtonDownKick = ComponentGetValue2(controls, "mButtonDownKick")
    return mButtonDownKick
end

player_helper.GetActiveHeldItem = function()
    local player = player_helper.Get()
    if(player == nil)then
        return
    end
    local inventory2Comp = EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component")
    local mActiveItem = ComponentGetValue2(inventory2Comp, "mActiveItem")
    return mActiveItem
end

player_helper.GetAnimationData = function()
    local player = player_helper.Get()
    if(player == nil)then
        return
    end
    local spriteComp = EntityGetFirstComponent(player, "SpriteComponent", "character")
    if(spriteComp == nil)then
        return
    end
    local rectAnim = ComponentGetValue2(spriteComp, "rect_animation")
    return rectAnim
end

player_helper.GetAimData = function()
    local player = player_helper.Get()
    if(player == nil)then
        return
    end
    local controlsComp = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")
    if(controlsComp == nil)then
        return
    end
    local x, y = ComponentGetValue2(controlsComp, "mAimingVector")

    return x and {x = x, y = y} or nil
end

player_helper.Hide = function( hide )
    local player = player_helper.Get()
    if(player == nil)then
        return
    end
    local spriteComps = EntityGetComponentIncludingDisabled(player, "SpriteComponent", "character")
    if(hide)then
        for k, v in pairs(spriteComps)do
            ComponentSetValue2(v, "visible", false)
        end
        -- hide cape

    else
        for k, v in pairs(spriteComps)do
            ComponentSetValue2(v, "visible", true)
        end
    end
end

player_helper.GetHealthInfo = function()
    local player = player_helper.Get()
    if(player == nil)then
        return
    end
    local health = 100
    local maxHealth = 100
    local healthComponent = EntityGetFirstComponentIncludingDisabled(player, "DamageModelComponent")
    if(healthComponent ~= nil)then
        health = ComponentGetValue2(healthComponent, "hp")
        maxHealth = ComponentGetValue2(healthComponent, "max_hp")
    end
    return health, maxHealth
end

player_helper.GetSpells = function()
    local player = player_helper.Get()
    if(player == nil)then
        return {}
    end

    local spells = {}
    --ItemActionComponent
    local items = GameGetAllInventoryItems(player)
    for k, v in pairs(items)do
        local itemComp = EntityGetFirstComponentIncludingDisabled(v, "ItemComponent")
        if(itemComp ~= nil)then
            local itemActionComp = EntityGetFirstComponentIncludingDisabled(v, "ItemActionComponent")
            if(itemActionComp ~= nil)then
                local action = ComponentGetValue2(itemActionComp, "action_id")
                table.insert(spells, action)
            end
        end
    end

    return spells
end

player_helper.SetSpells = function(spells)
    local player = player_helper.Get()
    if(player == nil)then
        return
    end
    if(spells == nil)then
        return
    end

    local x, y = EntityGetTransform(player)

    for k, v in ipairs(spells)do
        local action = CreateItemActionEntity(v, x, y)
        GamePickUpInventoryItem( player, action, false )
    end
end

player_helper.GetPerks = function()
    local perk_info = {}
    for i,perk_data in ipairs(perk_list) do
        local perk_id = perk_data.id
        local flag_name = get_perk_picked_flag_name( perk_id )

        local pickup_count = tonumber( GlobalsGetValue( flag_name .. "_PICKUP_COUNT", "0" ) )


        if GameHasFlagRun( flag_name ) or ( pickup_count > 0 ) then
            table.insert( perk_info, { id = perk_id, count = pickup_count} )
        end

    end

    return perk_info
end

player_helper.GivePerk = function( entity_who_picked, perk_id, amount )
    -- fetch perk info ---------------------------------------------------

    local pos_x, pos_y

    pos_x, pos_y = EntityGetTransform( entity_who_picked )

    local perk_data = get_perk_with_id( perk_list, perk_id )
    if perk_data == nil then
        return
    end

	local flag_name = get_perk_picked_flag_name( perk_id )
	
	-- update how many times the perk has been picked up this run -----------------
	
	local pickup_count = tonumber( GlobalsGetValue( flag_name .. "_PICKUP_COUNT", "0" ) )
	pickup_count = pickup_count + 1
	GlobalsSetValue( flag_name .. "_PICKUP_COUNT", tostring( pickup_count ) )

	-- load perk for entity_who_picked -----------------------------------
	local add_progress_flags = not GameHasFlagRun( "no_progress_flags_perk" )
	
	if add_progress_flags then
		local flag_name_persistent = string.lower( flag_name )
		if ( not HasFlagPersistent( flag_name_persistent ) ) then
			GameAddFlagRun( "new_" .. flag_name_persistent )
		end
		AddFlagPersistent( flag_name_persistent )
	end
	GameAddFlagRun( flag_name )

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

    -- certain other perks may be marked as picked-up
	if perk_data.remove_other_perks ~= nil then
		for i,v in ipairs( perk_data.remove_other_perks ) do
			local f = get_perk_picked_flag_name( v )
			GameAddFlagRun( f )
		end
	end

    local fake_perk_ent = EntityCreateNew()
    EntitySetTransform( fake_perk_ent, pos_x, pos_y )

    perk_data.func( fake_perk_ent, entity_who_picked, perk_id, amount )

    perk_name = GameTextGetTranslatedOrNot( perk_data.ui_name )
	perk_desc = GameTextGetTranslatedOrNot( perk_data.ui_description )

	-- add ui icon etc
	local entity_ui = EntityCreateNew( "" )
	EntityAddComponent( entity_ui, "UIIconComponent", 
	{ 
		name = perk_data.ui_name,
		description = perk_data.ui_description,
		icon_sprite_file = perk_data.ui_icon
	})
	
	if ( no_remove == false ) then
		EntityAddTag( entity_ui, "perk_entity" )
	end
	
	EntityAddChild( entity_who_picked, entity_ui )

    

    EntityKill( fake_perk_ent )

    --GamePrint( "Picked up perk: " .. perk_data.name )
end

player_helper.SetPerks = function(perks)
    local player = player_helper.Get()
    if(player == nil)then
        return
    end
    if(perks == nil)then
        return
    end

    for k, v in ipairs(perks)do
        local perk_id = v.id
        local pickup_count = v.count

        for i = 1, pickup_count do
            entity.GivePerk(player, perk_id, i)
        end
    end
end

player_helper.Serialize = function()
    local player = player_helper.Get()
    if(player == nil)then
        return
    end
    local data = {
        health = 100,
        max_health = 100,
        wand_data = player_helper.GetWandData(),
        spells = player_helper.GetSpells(),
        perks = player_helper.GetPerks(),
        gold = player_helper.GetGold(),
    }
    local healthComponent = EntityGetFirstComponentIncludingDisabled(player, "DamageModelComponent")
    if(healthComponent ~= nil)then
        data.health = ComponentGetValue2(healthComponent, "hp")
        data.max_health = ComponentGetValue2(healthComponent, "max_hp")
    end

    return bitser.dumps(data)
end

player_helper.Deserialize = function(data)
    local player = player_helper.Get()
    if(player == nil)then
        return
    end
    if(data == nil)then
        return
    end

    data = bitser.loads(data)

    -- kill items
    for k, v in pairs(GameGetAllInventoryItems(player) or {})do
        GameKillInventoryItem( player, v )
        EntityKill(v)
    end

    if(data.wand_data ~= nil)then
        player_helper.SetWandData(data.wand_data)
    end
    if(data.spells ~= nil)then
        player_helper.SetSpells(data.spells)
    end
    if(data.perks ~= nil)then
        player_helper.SetPerks(data.perks)
    end
    if(data.gold ~= nil)then
        player_helper.GiveGold(data.gold)
    end
    if(data.health ~= nil and data.max_health ~= nil)then
        local healthComponent = EntityGetFirstComponentIncludingDisabled(player, "DamageModelComponent")
        if(healthComponent ~= nil)then
            ComponentSetValue2(healthComponent, "hp", data.health)
            ComponentSetValue2(healthComponent, "max_hp", data.max_health)
        end
    end
end

return player_helper