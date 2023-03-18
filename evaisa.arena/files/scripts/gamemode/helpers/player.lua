local entity = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/entity.lua")
local EZWand = dofile("mods/evaisa.arena/files/scripts/utilities/EZWand.lua")

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

return player_helper