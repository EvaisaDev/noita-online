dofile_once("data/scripts/gun/procedural/gun_action_utils.lua");

function ShootProjectile( who_shot, entity_file, x, y, vx, vy, send_message )
    local entity = EntityLoad( entity_file, x, y );
    local genome = EntityGetFirstComponent( who_shot, "GenomeDataComponent" );
    -- this is the herd id string
    --local herd_id = ComponentGetValue2( genome, "herd_id" );
    local herd_id = ComponentGetValueInt( genome, "herd_id" );
    if send_message == nil then send_message = true end

	GameShootProjectile( who_shot, x, y, x+vx, y+vy, entity, send_message );

    local projectile = EntityGetFirstComponent( entity, "ProjectileComponent" );
    if projectile ~= nil then
        ComponentSetValue2( projectile, "mWhoShot", who_shot );
        -- NOTE the returned herd id actually breaks the herd logic, so don't bother
        --ComponentSetValue2( projectile, "mShooterHerdId", herd_id );
    end

    local velocity = EntityGetFirstComponent( entity, "VelocityComponent" );
    if velocity ~= nil then
	    ComponentSetValue2( velocity, "mVelocity", vx, vy )
    end

	return entity;
end

function WandGetActive( entity )
    local chosen_wand = nil;
    local wands = {};
    local children = EntityGetAllChildren( entity )  or {};
    for key, child in pairs( children ) do
        if EntityGetName( child ) == "inventory_quick" then
            wands = EntityGetChildrenWithTag( child, "wand" );
            break;
        end
    end
    if #wands > 0 then
        local inventory2 = EntityGetFirstComponent( entity, "Inventory2Component" );
        local active_item = ComponentGetValue2( inventory2, "mActiveItem" );
        for _,wand in pairs( wands ) do
            if wand == active_item then
                chosen_wand = wand;
                break;
            end
        end
        return chosen_wand;
    end
end

function WandGetActiveOrRandom( entity )
    local chosen_wand = nil;
    local wands = {};
    local children = EntityGetAllChildren( entity )  or {};
    for key, child in pairs( children ) do
        if EntityGetName( child ) == "inventory_quick" then
            wands = EntityGetChildrenWithTag( child, "wand" );
            break;
        end
    end
    if #wands > 0 then
        local inventory2 = EntityGetFirstComponent( entity, "Inventory2Component" );
        local active_item = ComponentGetValue2( inventory2, "mActiveItem" );
        for _,wand in pairs( wands ) do
            if wand == active_item then
                chosen_wand = wand;
                break;
            end
        end
        if chosen_wand == nil then
            chosen_wand =  random_from_array( wands );
        end
        return chosen_wand;
    end
end

function benchmark( callback, iterations )
    if iterations == nil then
        iterations = 1;
    end
    local t = GameGetRealWorldTimeSinceStarted();
    for i=1,iterations do
        callback();
    end
    return GameGetRealWorldTimeSinceStarted() - t;
end

function map(func, array)
    local new_array = {};
    for i,v in ipairs(array) do
        new_array[i] = func(v);
    end
    return new_array;
end


function DoFileEnvironment( filepath, environment )
    if environment == nil then environment = {} end
    local f = loadfile( filepath );
    local set_f = setfenv( f, setmetatable( environment, { __index = _G } ) );
    local status,result = pcall( set_f );
    if status == false then print_error( "do file environment for "..filepath..": "..result ); end
    return environment;
end

function ModTextFileAppend( left, right )
    ModTextFileSetContent( left, (ModTextFileGetContent( left ) or "") .. "\r\n" .. (ModTextFileGetContent( right ) or "") );
end

function ModTextFilePrepend( left, right )
    ModTextFileSetContent( left, (ModTextFileGetContent( right ) or "") .. "\r\n" .. (ModTextFileGetContent( left ) or "") );
end

function PackString( separator, ... )
	local string = {};
	for n=1,select( '#' , ... ) do
		local j = select( n, ... );
		local text = nil;
		if type(j) == "boolean" then
			if j then
			   text = "true";
			else
				text = "false";
			end
        else
            if type(j) == "string" and #j == 0 then
                text = "\"\"";
            else
                text = tostring( j ) or "nil";
            end
        end
		string[n] = text;
	end
	return table.concat( string, separator or "" );
end

function Log( ... )
    print( PackString(" ", ... ) );
end

function LogCompact( ... )
    local length = 0;
    local log = {};
    for k,v in pairs( {...} ) do
        table.insert( log, v );
        length = length + #v;
        if length > 80 then
            table.insert(log,"\n");
            length = 0;
        end
    end
    Log( unpack( log ) );
end

local screen_log_queue = {};
local screen_log_max = 20;
local screen_log_interval = 0.333;
function LogScreen( ... )
    table.insert( screen_log_queue, PackString( " ", ... ) );
end

function RenderLog( gui )
    local start_index = math.floor(GameGetRealWorldTimeSinceStarted()/screen_log_interval);
    for i=1,screen_log_max do
        local adjusted_index = (i + start_index) % #screen_log_queue;
        if screen_log_queue[adjusted_index] ~= nil then
            GuiText( gui, 0,0, tostring(screen_log_queue[adjusted_index]) );
        end
        GuiLayoutAddVerticalSpacing( gui );
    end
    screen_log_queue = {};
end

function LogTable( t )
    if type(t) == "table" then
        for k,v in pairs ( t ) do
            Log( k,v );
        end
    else
        Log( t );
    end
end

function LogTableCompact( t, show_keys )
    if type(t) == "table" then
        local length = 0;
        local log = {};
        for k,v in pairs( t ) do
            local join = PackString( "=", k, v );
            table.insert( log, join );
            length = length + #join;
            if length > 80 then
                table.insert(log,"\n");
                length = 0;
            end
        end
        Log( unpack( log ) );
    else
        Log( t );
    end
end

function ExploreGlobals()
    local g = {};
    for k,v in pairs(_G) do
        if type(v) ~= "function" then
            g[k] = v;
        end
    end
    LogTable(g);
end

function ListEntityComponents( entity )
    local components = EntityGetAllComponents( entity );
    for i, component_id in ipairs( components ) do
        Log( i, component_id );
    end
end

function ListEntityComponentObjects( entity, component_type_name, component_object_name )
    local component = EntityGetFirstComponent( entity, component_type_name );
    local members = ComponentObjectGetMembers( component, component_object_name );
    for member in pairs(members) do
        Log( member, ComponentObjectGetValue2( component, component_object_name, member ) );
    end
end

function CopyEntityComponentList( component_type_name, base_entity, copy_entity, keys )
    local base_component = EntityGetFirstComponent( base_entity, component_type_name );
    local copy_component = EntityGetFirstComponent( copy_entity, component_type_name );
    if base_component ~= nil and copy_component ~= nil then
        for index,key in pairs( keys ) do
            ComponentSetValue2( copy_component, key, ComponentGetValue2( base_component, key ) );
        end
    end
end

function CopyComponentMembers( base_component, copy_component )
    if base_component ~= nil and copy_component ~= nil then
        for key,value in pairs( ComponentGetMembers( base_component ) ) do
            ComponentSetValue2( copy_component, key, ComponentGetValue2( copy_component, key, value ) );
        end
    end
end

function CopyListedComponentMembers( base_component, copy_component, ... )
    if base_component ~= nil and copy_component ~= nil then
        for index,key in pairs( {...} ) do
            ComponentSetValue2( copy_component, key, ComponentGetValue2( base_component, key ) );
        end
    end
end

function CopyComponentObjectMembers( base_component, copy_component, component_object_name )
    if base_component ~= nil and copy_component ~= nil then
        for object_key in pairs( ComponentObjectGetMembers( base_component, component_object_name ) ) do
            ComponentObjectSetValue2( copy_component, component_object_name, object_key, ComponentObjectGetValue2( base_component, component_object_name, object_key ) );
        end
    end
end

function CopyEntityComponent( component_type_name, base_entity, copy_entity )
    local base_component = EntityGetFirstComponent( base_entity, component_type_name );
    local copy_component = EntityGetFirstComponent( copy_entity, component_type_name );
    CopyComponentMembers( base_component, copy_component );
end

function WandGetAbilityComponent( wand )
    local components = EntityGetAllComponents( wand ) or {};
    for _, component in pairs( components ) do
        if ComponentGetTypeName( component ) == "AbilityComponent" then
            return component;
        end
    end
end

function EnableWandAbilityComponent(wand_id)
    local components = EntityGetAllComponents( wand_id );
    for i, component_id in ipairs( components ) do
        for k, v2 in pairs( ComponentGetMembers( component_id ) ) do
            if k == "mItemRecoil" then
                EntitySetComponentIsEnabled( wand_id, component_id, true );
                break;
            end
        end
    end
end

function EntityComponentGetValue( entity_id, component_type_name, component_key, default_value )
    local component = EntityGetFirstComponent( entity_id, component_type_name );
    if component ~= nil then return ComponentGetValue2( component, component_key ); end
    return default_value;
end

function EntityGetNamedChild( entity_id, name )
    local children = EntityGetAllChildren( entity_id ) or {};
	if children ~= nil then
		for index,child_entity in pairs( children ) do
			local child_entity_name = EntityGetName( child_entity );
			
			if child_entity_name == name then
				return child_entity;
            end
        end
    end
end

function EntityGetChildrenWithTag( entity_id, tag )
    local valid_children = {};
    local children = EntityGetAllChildren( entity_id ) or {};
    for index, child in pairs( children ) do
        if EntityHasTag( child, tag ) then
            table.insert( valid_children, child );
        end
    end
    return valid_children;
end



function FindComponentByType( entity_id, component_type_name )
    local components = EntityGetAllComponents( entity_id ) or {};
    local valid_components = {};
    for _,component in pairs( components ) do
        if ComponentGetTypeName( component ) == component_type_name then
            table.insert( valid_components, component );
        end
    end
    return valid_components;
end

function FindComponentThroughTags( entity_id, ... )
    local matching_components = EntityGetAllComponents( entity_id ) or {};
    local valid_components = {};
    for _,tag in pairs( {...} ) do
        for index,component in pairs( matching_components ) do
            if ComponentGetValue2( component, tag ) ~= "" and ComponentGetValue2( component, tag ) ~= nil then
                table.insert( valid_components, component );
            end
        end
        matching_components = valid_components;
        valid_components = {};
    end
    return matching_components;
end

function FindFirstComponentThroughTags( entity_id, ... )
    return FindComponentThroughTags( entity_id, ...)[1];
end

function ComponentGetValueDefault( component_id, key, default )
    local value = ComponentGetValue2( component_id, key );
    if value ~= nil then
        return value;
    end
    return default;
end

function GetEntityCustomVariable( entity_id, variable_storage_tag, key, default )
   local variable_storage = EntityGetFirstComponent( entity_id, "VariableStorage", variable_storage_tag );
   if variable_storage ~= nil then
        return ComponentGetValue2( variable_storage, "value_string" );
   end
   return default;
end

function SetEntityCustomVariable( entity_id, variable_storage_tag, variable_name, value )
    local variable_storage = EntityGetFirstComponent( entity_id, "VariableStorage", variable_storage_tag );
    if variable_storage == nil then
        EntityAddComponent( entity_id, "VariableStorage", {
            _tags=tag,
            name=variable_name,
            value_string=tostring(value),
        });
    else
        ComponentSetValue2( variable_storage, "value_string", tostring(value) );
    end
end

function GetWandActions( wand )
    local actions = {};
    local children = EntityGetAllChildren( wand ) or {};
    for i,v in ipairs( children ) do
        local item = EntityGetFirstComponentIncludingDisabled( v, "ItemComponent" );
        local item_action = EntityGetFirstComponentIncludingDisabled( v, "ItemActionComponent" );
        if item and item_action then
            local action_id = ComponentGetValue2( item_action, "action_id" );
            local permanent = ComponentGetValue2( item, "permanently_attached" );
            local x, y = ComponentGetValue2( item, "inventory_slot" );
            if action_id ~= nil then
                table.insert( actions, { action_id = action_id, permanent = permanent, x = x, y = y } );
            end
        end
    end
    return actions;
end

function CopyWandActions( base_wand, copy_wand )
    local actions = GetWandActions( base_wand );
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
    --[[
        if action_data.permanent ~= "1" then
            AddGunAction( copy_wand, action_data.action_id );
        else
            AddGunActionPermanent( copy_wand, action_data.action_id );
        end
        ]]
    end
end

function FindEntityInInventory( inventory, entity )
    local inventory_items = EntityGetAllChildren( inventory )  or {};
		
    -- remove default items
    if inventory_items ~= nil then
        for i,item_entity in ipairs( inventory_items ) do
            --Log( i, item_entity );
        end
        --    GameKillInventoryItem( player_entity, item_entity )
        --end
    end
end

function TryGivePerk( player_entity_id, ... )
    for index,perk_id in pairs( {...} ) do
        local perk_entity = perk_spawn( x, y, perk_id );
        if perk_entity ~= nil then
            perk_pickup( perk_entity, player_entity_id, EntityGetName( perk_entity ), false, false );
        end
    end
end

function TryAdjustDamageMultipliers( entity, resistances )
    local damage_models = EntityGetComponent( entity, "DamageModelComponent" );
    if damage_models ~= nil then
        for index,damage_model in pairs( damage_models ) do
            for damage_type,multiplier in pairs( resistances ) do
                local resistance = ComponentObjectGetValue2( damage_model, "damage_multipliers", damage_type );
                resistance = resistance * multiplier;
                ComponentObjectSetValue2( damage_model, "damage_multipliers", damage_type, resistance );
            end
        end
    end
end


--[[
    ice
    electricity
    radioactive
    slice
    projectile
    healing
    physics_hit
    explosion
    poison
    melee
    drill
    fire
]]

function TryAdjustMaxHealth( entity, callback )
    local damage_models = EntityGetComponent( entity, "DamageModelComponent" );
    if damage_models ~= nil then
        for index,damage_model in pairs( damage_models ) do
            local current_hp = ComponentGetValue2( damage_model, "hp" );
            local max_hp = ComponentGetValue2( damage_model, "max_hp" );
            local new_max = callback( max_hp, current_hp );
            local regained = new_max - current_hp;
            ComponentSetValue2( damage_model, "max_hp", new_max );
            ComponentSetValue2( damage_model, "hp", current_hp + regained );
        end
    end
end

function GetInventoryQuickActiveItem( entity )
    if entity ~= nil then
        local component = EntityGetFirstComponent( entity, "Inventory2Component" );
        if component ~= nil then
            return ComponentGetValue2( component, "mActiveItem" );
        end
    end
end

function EntityIterateComponentsByType( entity, component_type_name, callback )
    local matched_components = {};
    local components = EntityGetAllComponents( entity ) or {};
    for _,component in pairs(components) do
        if ComponentGetTypeName( component ) == component_type_name then
            table.insert( matched_components, component );
        end
    end
    if callback ~= nil then
        for _,component in pairs(matched_components) do
            callback( component );
        end
    end
    return matched_components;
end

function EntityGetHitboxCenter( entity )
    local tx, ty = EntityGetTransform( entity );
    local hitbox = EntityGetFirstComponent( entity, "HitboxComponent" );
    if hitbox ~= nil then
        local width = ComponentGetValue2( hitbox, "aabb_max_x" ) - ComponentGetValue2( hitbox, "aabb_min_x" );
        local height = ComponentGetValue2( hitbox, "aabb_max_y" ) - ComponentGetValue2( hitbox, "aabb_min_y" );
        tx = tx + ComponentGetValue2( hitbox, "aabb_min_x" ) + width * 0.5;
        ty = ty + ComponentGetValue2( hitbox, "aabb_min_y" ) + height * 0.5;
    end
    return tx, ty;
end

function EntityGetFirstHitboxSize( entity, fallbackWidth, fallbackHeight )
    local hitbox = EntityGetFirstComponent( entity, "HitboxComponent" );

    local width = fallbackWidth or 0;
    local height = fallbackHeight or 0;
    if hitbox ~= nil then
        width =  ComponentGetValue2( hitbox, "aabb_max_x" ) - ComponentGetValue2( hitbox, "aabb_min_x" );
        height =  ComponentGetValue2( hitbox, "aabb_max_y" ) - ComponentGetValue2( hitbox, "aabb_min_y" );
    end
    return width, height;
end

function EntitySetVelocity( entity, x, y )
    EntityIterateComponentsByType( entity, "VelocityComponent", function( component )
        ComponentSetValue2( component, "mVelocity", x, y );
    end );
end


function EaseAngle( angle, target_angle, easing )
    local dir = (angle - target_angle) / (math.pi*2);
    dir = dir - math.floor(dir + 0.5);
    dir = dir * (math.pi*2);
    return angle - dir * easing;
end

function WeightedRandom( items, weights, sum )
    if weights == nil  then
        weights = {};
        for k,v in pairs( items ) do 
            weights[k] = 1;
        end
        sum = items.length;
    end
    if sum == nil then
        sum = 0;
        for k,v in pairs( weights ) do
            sum = sum + v;
        end
    end
    if sum <= 0 then
        return nil;
    end
    local random = Random() * sum;
    for k,v in pairs(items) do
        local weight = weights[k];
        if random <= weight then
            return items[k];
        end
        random = random - weight;
    end
end

function WeightedRandomTable( entries )
    local sum = 0;
    for k,v in pairs( entries ) do
        sum = sum + v;
    end
    if sum <= 0 then
        return nil;
    end
    local random = Random() * sum;
    for k,v in pairs( entries ) do
        if random <= v then
            return k;
        end
        random = random - v;
    end
end


function EntityHasScript( entity, filepath, script_type )
    if script_type == nil then
        script_type = "script_source_file";
    end
    for _,lua_component in pairs( EntityGetComponentIncludingDisabled(entity,"LuaComponent") or {}) do
        if ComponentGetValue2( lua_component, script_type ) == filepath then
            return true;
        end
    end
    return false;
end