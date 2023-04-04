dofile_once( "data/scripts/gun/procedural/gun_procedural.lua" );
dofile_once( "mods/spell_lab/files/helper.lua" );
dofile_once( "mods/spell_lab/files/lib/variables.lua" );

local WAND_STAT_SETTER = {
    Direct = 1,
    Gun = 2,
    GunAction = 3
}

local WAND_STAT_SETTERS = {
    shuffle_deck_when_empty = WAND_STAT_SETTER.Gun,
    actions_per_round = WAND_STAT_SETTER.Gun,
    speed_multiplier = WAND_STAT_SETTER.GunAction,
    deck_capacity = WAND_STAT_SETTER.Gun,
    reload_time = WAND_STAT_SETTER.Gun,
    fire_rate_wait = WAND_STAT_SETTER.GunAction,
    spread_degrees = WAND_STAT_SETTER.GunAction,
    mana_charge_speed = WAND_STAT_SETTER.Direct,
    mana_max = WAND_STAT_SETTER.Direct,
    mana = WAND_STAT_SETTER.Direct,
}

local function wand_clear_actions( wand )
    local actions = {};
    local children = EntityGetAllChildren( wand ) or {};
    for i,v in ipairs( children ) do
        local item = EntityGetFirstComponentIncludingDisabled( v, "ItemComponent" );
        local item_action = EntityGetFirstComponentIncludingDisabled( v, "ItemActionComponent" );
        if item and item_action then
            EntityRemoveFromParent( v );
            EntityKill( v );
        end
    end
    return actions;
end

local function wand_get_actions( wand )
    local actions = {};
    local children = EntityGetAllChildren( wand ) or {};
    for i,v in ipairs( children ) do
        local item = EntityGetFirstComponentIncludingDisabled( v, "ItemComponent" );
        local item_action = EntityGetFirstComponentIncludingDisabled( v, "ItemActionComponent" );
        if item and item_action then
            local action_id = ComponentGetValue2( item_action, "action_id" );
            local permanent = ComponentGetValue2( item, "permanently_attached" );
            local locked = ComponentGetValue2( item, "is_frozen" );
            local x, y = ComponentGetValue2( item, "inventory_slot" );
            if action_id ~= nil then
                table.insert( actions, { action_id = action_id, permanent = permanent, locked = locked, x = x, y = y, entity = v, item = item } );
            end
        end
    end
    return actions;
end

-- TODO : Deduplicate
local function wand_get_actions_absolute( wand )
    local actions = {};
    local permanent_actions = {};
    local children = EntityGetAllChildren( wand ) or {};
    for i,v in ipairs( children ) do
        local item = EntityGetFirstComponentIncludingDisabled( v, "ItemComponent" );
        local item_action = EntityGetFirstComponentIncludingDisabled( v, "ItemActionComponent" );
        if item and item_action then
            local action_id = ComponentGetValue2( item_action, "action_id" );
            local permanent = ComponentGetValue2( item, "permanently_attached" );
            local locked = ComponentGetValue2( item, "is_frozen" );
            local x, y = ComponentGetValue2( item, "inventory_slot" );
            if action_id ~= nil then
                if not permanent then
                    actions[x] = { action_id = action_id, permanent = permanent, locked = locked, x = x, y = y, entity = v, item = item };
                else
                    table.insert( permanent_actions, { action_id = action_id, permanent = permanent, locked = locked, x = x, y = y, entity = v, item = item } );
                end
            end
        end
    end
    return actions, permanent_actions;
end

local function wand_set_actions( wand, actions_table )
    for _,action_id in pairs(actions_table) do
        AddGunAction( wand, action_id );
    end
end

local function wand_shuffle_actions( wand )
    local actions = {};
    local actions_data = {};
    local children = EntityGetAllChildren( wand ) or {};
    for i,v in ipairs( children ) do
        local item = EntityGetFirstComponentIncludingDisabled( v, "ItemComponent" );
        local item_action = EntityGetFirstComponentIncludingDisabled( v, "ItemActionComponent" );
        if item and item_action then
            local action_id = ComponentGetValue2( item_action, "action_id" );
            local permanent = ComponentGetValue2( item, "permanently_attached" );
            local locked = ComponentGetValue2( item, "is_frozen" );
            local x, y = ComponentGetValue2( item, "inventory_slot" );
            if action_id ~= nil and permanent ~= true and locked ~= true then
                table.insert( actions, { action_entity = v, item = item } );
                table.insert( actions_data, { x = x, y = y } );
            end
        end
    end
    local wx, wy = EntityGetTransform( wand );
    SetRandomSeed( GameGetFrameNum(), wx + wy );
    local actions_data_shuffled = {};
    for i, v in ipairs(actions_data) do
        local pos = Random( 1, #actions_data_shuffled + 1 );
        table.insert( actions_data_shuffled, pos, v )
    end
    for i=1,#actions do
        local action = actions[i];
        local action_data = actions_data_shuffled[i];
        ComponentSetValue2( action.item, "inventory_slot", action_data.x, action_data.y );
    end
end

local function wand_copy_actions( base_wand, copy_wand )
    local actions = wand_get_actions( base_wand );
    for index,action_data in pairs( actions ) do
        local action_entity = CreateItemActionEntity( action_data.action_id );
        local item = EntityGetFirstComponentIncludingDisabled( action_entity, "ItemComponent" );
        if action_data.permanent then
            ComponentSetValue2( item, "permanently_attached", true );
        end
        if ComponentSetValue2 and action_data.x ~= nil and action_data.y ~= nil then
            ComponentSetValue2( item, "inventory_slot", action_data.x, action_data.y );
        end
        EntitySetComponentsWithTagEnabled( action_entity, "enabled_in_world", false );
        EntityAddChild( copy_wand, action_entity );
    end
end

local function wand_copy_stats( base_wand, copy_wand )
    local base_ability = EntityGetFirstComponentIncludingDisabled( base_wand, "AbilityComponent" );
    local target_ability = EntityGetFirstComponentIncludingDisabled( copy_wand, "AbilityComponent" );
    if base_ability and target_ability then
        for stat,stat_type in pairs( WAND_STAT_SETTERS ) do
            ability_component_set_stat( target_ability, stat, ability_component_get_stat( base_ability, stat ) );
        end
    end
end

local function wand_copy( base_wand, copy_wand, copy_sprite, copy_actions )
    wand_copy_stats( base_wand, copy_wand );
    if copy_sprite ~= false then
        local base_ability = EntityGetFirstComponentIncludingDisabled( base_wand, "AbilityComponent" );
        local target_ability = EntityGetFirstComponentIncludingDisabled( copy_wand, "AbilityComponent" );
        ComponentSetValue2( target_ability, "sprite_file", ComponentGetValue2( base_ability, "sprite_file" ) );
        local base_sprite = EntityGetFirstComponentIncludingDisabled( base_wand, "SpriteComponent" )
        local copy_sprite = EntityGetFirstComponentIncludingDisabled( copy_wand, "SpriteComponent" )
        CopyListedComponentMembers( base_sprite, copy_sprite, "image_file","offset_x","offset_y");
        local base_hotspot = EntityGetFirstComponentIncludingDisabled( base_wand, "HotspotComponent", "shoot_pos" );
        local copy_hotspot = EntityGetFirstComponentIncludingDisabled( copy_wand, "HotspotComponent", "shoot_pos" );
        CopyComponentMembers( base_hotspot, copy_hotspot );
        local base_hotspot_x, base_hotspot_y = ComponentGetValue2( base_hotspot, "offset" );
        ComponentSetValue2( copy_hotspot, "offset", base_hotspot_x, base_hotspot_y );
    end
    if copy_actions ~= false then
        wand_copy_actions( base_wand, copy_wand );
    end
end

local function ability_component_get_stat( ability, stat )
    local setter = WAND_STAT_SETTERS[stat];
    if setter ~= nil then
        if setter == WAND_STAT_SETTER.Direct then
            return ComponentGetValue2( ability, stat );
        elseif setter == WAND_STAT_SETTER.Gun then
            return ComponentObjectGetValue2( ability, "gun_config", stat );
        elseif setter == WAND_STAT_SETTER.GunAction then
            return ComponentObjectGetValue2( ability, "gunaction_config", stat );
        end
    end
end

local function ability_component_set_stat( ability, stat, value )
    local setter = WAND_STAT_SETTERS[stat];
    if setter ~= nil then
        if setter == WAND_STAT_SETTER.Direct then
            ComponentSetValue2( ability, stat, value );
        elseif setter == WAND_STAT_SETTER.Gun then
            ComponentObjectSetValue2( ability, "gun_config", stat, value );
        elseif setter == WAND_STAT_SETTER.GunAction then
            ComponentObjectSetValue2( ability, "gunaction_config", stat, value );
        end
    end
end

local function ability_component_adjust_stat( ability, stat, callback )
    local setter = WAND_STAT_SETTERS[stat];
    if setter ~= nil then
        local current_value = nil;
        if setter == WAND_STAT_SETTER.Direct then
            current_value = ComponentGetValue2( ability, stat );
        elseif setter == WAND_STAT_SETTER.Gun then
            current_value = ComponentObjectGetValue2( ability, "gun_config", stat );
        elseif setter == WAND_STAT_SETTER.GunAction then
            current_value = ComponentObjectGetValue2( ability, "gunaction_config", stat );
        end
        local new_value = callback( current_value );
        if setter == WAND_STAT_SETTER.Direct then
            ComponentSetValue2( ability, stat, new_value );
        elseif setter == WAND_STAT_SETTER.Gun then
            ComponentObjectSetValue2( ability, "gun_config", stat, new_value );
        elseif setter == WAND_STAT_SETTER.GunAction then
            ComponentObjectSetValue2( ability, "gunaction_config", stat, new_value );
        end
    end
end

local function ability_component_get_stats( ability, stat )
    local stats = {};
    for k,v in pairs( WAND_STAT_SETTERS ) do
        stats[k] = ability_component_get_stat( ability, k );
    end
    return stats;
end

local function ability_component_set_stats( ability, stat_value_table )
    for stat,value in pairs(stat_value_table) do
        ability_component_set_stat( ability, stat, value );
    end
end

local function ability_component_adjust_stats( ability, stat_callback_table )
    for stat,callback in pairs(stat_callback_table) do
        ability_component_adjust_stat( ability, stat, callback );
    end
end

local function wand_get_stat( wand, stat )
    local ability = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" );
    if ability then return ability_component_get_stat( ability, stat ); end
end

local function wand_set_stat( wand, stat, value )
    local ability = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" );
    if ability then return ability_component_set_stat( ability, stat, value ); end
end

local function wand_adjust_stat( wand, stat, callback )
    local ability = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" );
    if ability then return ability_component_adjust_stat( ability, stat, callback ); end
end

local function wand_get_stats( wand, stat )
    local ability = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" );
    if ability then return ability_component_get_stats( ability, stat ); end
end

local function wand_set_stats( wand, stat_value_table )
    local ability = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" );
    if ability then return ability_component_set_stats( ability, stat_value_table ); end
end

local function wand_adjust_stats( wand, stat_callback_table )
    local ability = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" );
    if ability then return ability_component_adjust_stats( ability, stat_callback_table ); end
end

local function wand_get_dynamic_wand_data_from_stats( stats )
    local gun = {
        deck_capacity               = stats.deck_capacity;
        actions_per_round           = stats.actions_per_round;
        reload_time                 = stats.reload_time;
        shuffle_deck_when_empty     = stats.shuffle_deck_when_empty and 1 or 0;
        fire_rate_wait              = stats.fire_rate_wait;
        spread_degrees              = stats.spread_degrees;
        speed_multiplier            = stats.speed_multiplier;
        mana_charge_speed           = stats.mana_charge_speed;
        mana_max                    = stats.mana_max;
    };
    return GetWand( gun );
end

local function wand_get_dynamic_wand_data( wand )
    local ability = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" );
    if ability then
        return wand_get_dynamic_wand_data_from_stats( ability_component_get_stats( ability ) );
    end
end

local function initialize_wand( wand, wand_data, do_clear_actions )
    if do_clear_actions ~= false then wand_clear_actions( wand ); end
    local ability = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" );
    local item = EntityGetFirstComponent( wand, "ItemComponent" );
    if wand_data.name ~= nil then
        ComponentSetValue2( ability, "ui_name", wand_data.name );
        if item ~= nil then
            ComponentSetValue2( item, "item_name", wand_data.name );
            ComponentSetValue2( item, "always_use_item_name_in_ui", true );
        end
    end

    for stat,value in pairs( wand_data.stats or {} ) do
        ability_component_set_stat( ability, stat, value );
    end

    for stat,range in pairs( wand_data.stat_ranges or {} ) do
        ability_component_set_stat( ability, stat, Random( range[1], range[2] ) );
    end

    for stat,random_values in pairs( wand_data.stat_randoms or {} ) do
        ability_component_set_stat( ability, stat, random_values[ Random( 1, #random_values ) ] );
    end

    ability_component_set_stat( ability, "mana", ability_component_get_stat( ability, "mana_max" ) );

    for _,actions in pairs( wand_data.permanent_actions or {} ) do
        local random_action = actions[ Random( 1, #actions ) ];
        if random_action ~= nil then
            AddGunActionPermanent( wand, random_action );
        end
    end

    --for _,actions in pairs( wand_data.actions or {} ) do
    if wand_data.actions then
        for action_index=1,#wand_data.actions,1 do
            local actions = wand_data.actions[action_index];
            if actions ~= nil then
                local random_action = actions[ Random( 1, #actions ) ];
                if random_action ~= nil then
                    if type( random_action ) == "table" then
                        local amount = random_action.amount or 1;
                        for _=1,amount,1 do
                            local action_entity = CreateItemActionEntity( random_action.action );
                            if action_entity then
                                local item = EntityGetFirstComponentIncludingDisabled( action_entity, "ItemComponent" );
                                if random_action.locked == true then
                                    ComponentSetValue2( item, "is_frozen", true );
                                end
                                if random_action.permanent == true then
                                    ComponentSetValue2( item, "permanently_attached", true );
                                end
                                if random_action.x ~= nil then
                                    ComponentSetValue2( item, "inventory_slot", random_action.x, 0 );
                                else
                                    ComponentSetValue2( item, "inventory_slot", action_index - 1, 0 );
                                end
                                EntitySetComponentsWithTagEnabled( action_entity, "enabled_in_world", false );
                                EntityAddChild( wand, action_entity );
                            end
                        end
                    else
                        local action_entity = CreateItemActionEntity( random_action );
                        if action_entity then
                            local item = EntityGetFirstComponentIncludingDisabled( action_entity, "ItemComponent" );
                            if item ~= nil then
                                ComponentSetValue2( item, "inventory_slot", action_index - 1, 0 );
                            end
                            EntitySetComponentsWithTagEnabled( action_entity, "enabled_in_world", false );
                            EntityAddChild( wand, action_entity );
                            --AddGunAction( wand, random_action );
                        end
                    end
                end
            end
        end
    end

    if wand_data.absolute_actions then
        for x,action in pairs( wand_data.absolute_actions ) do
            local action_entity = CreateItemActionEntity( action.action_id );
            if action_entity then
                local item = EntityGetFirstComponentIncludingDisabled( action_entity, "ItemComponent" );
                if action.locked then
                    ComponentSetValue2( item, "is_frozen", true );
                end
                if action.permanent then
                    ComponentSetValue2( item, "permanently_attached", true );
                end
                ComponentSetValue2( item, "inventory_slot", action.x or x, 0 );
                EntitySetComponentsWithTagEnabled( action_entity, "enabled_in_world", false );
                EntityAddChild( wand, action_entity );
            end
        end
    end

    if wand_data.sprite ~= nil then
        if wand_data.sprite.file ~= nil then
            ComponentSetValue2( ability, "sprite_file", wand_data.sprite.file );
            -- TODO this takes a second to apply, probably worth fixing, but for now just prefer using custom file
            local sprite = EntityGetFirstComponent( wand, "SpriteComponent", "item" );
            if sprite ~= nil then
                ComponentSetValue2( sprite, "image_file", wand_data.sprite.file );
                EntityRefreshSprite( wand, sprite );
            end
        end
        if wand_data.sprite.hotspot ~= nil then
            local hotspot = EntityGetFirstComponent( wand, "HotspotComponent", "shoot_pos" );
            if hotspot ~= nil then
                ComponentSetValue2( hotspot, "offset", wand_data.sprite.hotspot.x, wand_data.sprite.hotspot.y );
            end
        end
    else
        local dynamic_wand = wand_get_dynamic_wand_data( wand );
        SetWandSprite( wand, ability, dynamic_wand.file, dynamic_wand.grip_x, dynamic_wand.grip_y, ( dynamic_wand.tip_x - dynamic_wand.grip_x ), ( dynamic_wand.tip_y - dynamic_wand.grip_y ) );
        EntityRefreshSprite( wand, EntityGetFirstComponent( wand, "SpriteComponent", "item" ) );
    end

    if wand_data.callback ~= nil then
        wand_data.callback( wand, ability );
    end
end

local function wand_explode_action( wand, x, include_permanent_actions, include_frozen_actions, ox, oy )
    local actions = wand_get_actions_absolute( wand );
    if actions then
        local action = actions[x];
        if action then
            local action_to_remove = action.entity;
            EntityRemoveFromParent( action_to_remove );
            EntityApplyTransform( action_to_remove, EntityGetTransform( wand ) );
            EntitySetComponentsWithTagEnabled( action_to_remove, "enabled_in_hand", false );
            EntitySetComponentsWithTagEnabled( action_to_remove, "enabled_in_inventory", false );
            EntitySetComponentsWithTagEnabled( action_to_remove, "enabled_in_world", true );
            ComponentSetValue2( EntityGetFirstComponent( action_to_remove, "VelocityComponent" ), "mVelocity", Random( -150, 150 ), Random( -250, -100 ) );
            return action_to_remove;
        end
    end
end

local function wand_explode_random_action( wand, include_permanent_actions, include_frozen_actions, ox, oy )
    local x, y = EntityGetTransform( wand );
    local actions = {};
    local children = EntityGetAllChildren( wand ) or {};
    for i,action in ipairs( children ) do
        local item_action = EntityGetFirstComponentIncludingDisabled( action, "ItemActionComponent" );
        if item_action ~= nil then
            local item = EntityGetFirstComponentIncludingDisabled( action, "ItemComponent" );
            if item ~= nil then
                local action_id = ComponentGetValue2( item_action, "action_id" );
                if action_id ~= nil then
                    if include_permanent_actions == true or ComponentGetValue2( item, "permanently_attached" ) == false then
                        if include_frozen_actions == true or ComponentGetValue2( item, "is_frozen" ) == false then
                            table.insert( actions, { action_id=action_id, permanent=permanent, entity=action } );
                        end
                    end
                end
            end
        end
    end
    if #actions > 0 then
        local r = math.ceil( math.random() * #actions );
        local action_to_remove = actions[ r ];
        local card = CreateItemActionEntity( action_to_remove.action_id, ox or x, oy or y );
        ComponentSetValue2( EntityGetFirstComponent( card, "VelocityComponent" ), "mVelocity", Random( -150, 150 ), Random( -250, -100 ) );
        EntityRemoveFromParent( action_to_remove.entity );
        return action_to_remove;
    end
end

local function wand_remove_first_action( wand, include_permanent_actions, include_frozen_actions )
    local x, y = EntityGetTransform( wand );
    local actions = {};
    local children = EntityGetAllChildren( wand ) or {};
    for _,action in pairs( children ) do
        local item_action = EntityGetFirstComponentIncludingDisabled( action, "ItemActionComponent" );
        if item_action ~= nil then
            local item = EntityGetFirstComponentIncludingDisabled( action, "ItemComponent" );
            if item ~= nil then
                if include_permanent_actions == true or ComponentGetValue2( item, "permanently_attached" ) == false then
                    if include_frozen_actions == true or ComponentGetValue2( item, "is_frozen" ) == false then
                        EntityRemoveFromParent( action );
                        EntitySetComponentsWithTagEnabled( action,  "enabled_in_world", true );
                        EntitySetComponentsWithTagEnabled( action,  "enabled_in_hand", false );
                        EntitySetComponentsWithTagEnabled( action,  "enabled_in_inventory", false );
                        EntitySetComponentsWithTagEnabled( action,  "item_unidentified", false );
                        EntitySetTransform( action, x, y );
                        return action;
                    end
                end
            end
        end
    end
end

local function wand_lock( wand, lock_spells, lock_wand )
    if lock_spells == nil then lock_spells = true; end
    if lock_wand == nil then lock_wand = true; end
    if lock_spells then
        local children = EntityGetAllChildren( wand ) or {};
        for i,action in ipairs( children ) do
            local item = EntityGetFirstComponentIncludingDisabled( action, "ItemComponent" );
            if item ~= nil then
                ComponentSetValue2( item, "is_frozen", true );
            end
        end
    end
    if lock_wand then
        local item = EntityGetFirstComponentIncludingDisabled( wand, "ItemComponent" );
        if item ~= nil then
            ComponentSetValue2( item, "is_frozen", true );
        end
    end
end

local function wand_attach_action( wand, action, permanent, locked )
    EntityAddChild( wand, action );
    local item_action = EntityGetFirstComponentIncludingDisabled( action, "ItemActionComponent" );
    if item_action ~= nil then
        EntitySetComponentsWithTagEnabled( action,  "enabled_in_world", false );
        EntitySetComponentsWithTagEnabled( action,  "enabled_in_hand", false );
        EntitySetComponentsWithTagEnabled( action,  "enabled_in_inventory", false );
    end
end

local function wand_is_always_cast_valid( wand )
    local children = EntityGetAllChildren( wand ) or {};
    for i,v in ipairs( children ) do
        local items = EntityGetComponentIncludingDisabled( v, "ItemComponent" )
        local has_a_valid_spell = false;
        for _,item in pairs( items or {}) do
            if ComponentGetValue2( item, "permanently_attached" ) == false then
                has_a_valid_spell = true;
                break;
            end
        end
        if has_a_valid_spell then
            return true;
        end
    end
    return false;
end

local function force_always_cast( wand, amount )
    if amount == nil then amount = 1 end
    local children = EntityGetAllChildren( wand ) or {};
    local always_cast_count = 0;
    for _,child in pairs( children ) do
        local item_component = EntityGetFirstComponentIncludingDisabled( child, "ItemComponent" );
        if item_component then
            if ComponentGetValue2( item_component, "permanently_attached" ) == true then
                always_cast_count = always_cast_count + 1;
                break;
            end
        end
    end
    while always_cast_count < amount do
        local random_child = children[ Random( 1,#children ) ];
        local item_component = EntityGetFirstComponentIncludingDisabled( random_child, "ItemComponent" );
        if item_component and ComponentGetValue2( item_component, "permanently_attached" ) ~= true then
            ComponentSetValue2( item_component, "permanently_attached", true );
            always_cast_count = always_cast_count + 1;
        end
    end
end
    
return {
    wand_clear_actions = wand_clear_actions,
    wand_get_actions = wand_get_actions,
    wand_get_actions_absolute = wand_get_actions_absolute,
    wand_set_actions = wand_set_actions,
    wand_shuffle_actions = wand_shuffle_actions,
    wand_copy_actions = wand_copy_actions,
    wand_copy_stats = wand_copy_stats,
    wand_copy = wand_copy,
    ability_component_get_stat = ability_component_get_stat,
    ability_component_set_stat = ability_component_set_stat,
    ability_component_adjust_stat = ability_component_adjust_stat,
    ability_component_get_stats = ability_component_get_stats,
    ability_component_set_stats = ability_component_set_stats,
    ability_component_adjust_stats = ability_component_adjust_stats,
    wand_get_stat = wand_get_stat,
    wand_set_stat = wand_set_stat,
    wand_adjust_stat = wand_adjust_stat,
    wand_get_stats = wand_get_stats,
    wand_set_stats = wand_set_stats,
    wand_adjust_stats = wand_adjust_stats,
    initialize_wand = initialize_wand,
    wand_get_dynamic_wand_data = wand_get_dynamic_wand_data,
    wand_get_dynamic_wand_data_from_stats = wand_get_dynamic_wand_data_from_stats,
    wand_explode_action = wand_explode_action,
    wand_explode_random_action = wand_explode_random_action,
    wand_remove_first_action = wand_remove_first_action,
    wand_lock = wand_lock,
    wand_attach_action = wand_attach_action,
    wand_is_always_cast_valid = wand_is_always_cast_valid,
    force_always_cast = force_always_cast,
}