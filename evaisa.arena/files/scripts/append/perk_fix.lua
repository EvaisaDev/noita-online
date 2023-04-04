local reapply_fix_list = {
    EXTRA_PERK = true,
    PERKS_LOTTERY = true,
    EXTRA_SHOP_ITEM = true,
    HEARTS_MORE_EXTRA_HP = true,
}

local remove_list = {
    PEACE_WITH_GODS = true,
    ATTRACT_ITEMS = true,
    UNLIMITED_SPELLS = true,
    ABILITY_ACTIONS_MATERIALIZED = true,
    NO_WAND_EDITING = true,
}

local rewrites = {
    SHIELD = {
		id = "SHIELD",
		ui_name = "$perk_shield",
		ui_description = "$perkdesc_shield",
		ui_icon = "data/ui_gfx/perk_icons/shield.png",
		perk_icon = "data/items_gfx/perks/shield.png",
		stackable = STACKABLE_YES,
		stackable_how_often_reappears = 10,
		stackable_maximum = 5,
		max_in_perk_pool = 2,
		usable_by_enemies = true,
		func = function( entity_perk_item, entity_who_picked, item_name )
			local x,y = EntityGetTransform( entity_who_picked )
			local child_id = EntityLoad( "data/entities/misc/perks/shield.xml", x, y )
			
			local shield_num = tonumber( GlobalsGetValue( "PERK_SHIELD_COUNT_"..tostring(entity_who_picked), "0" ) )
			local shield_radius = 10 + shield_num * 2.5
			local charge_speed = math.max( 0.22 - shield_num * 0.05, 0.02 )
			shield_num = shield_num + 1
			GlobalsSetValue( "PERK_SHIELD_COUNT_"..tostring(entity_who_picked), tostring( shield_num ) )
			
			local comps = EntityGetComponent( child_id, "EnergyShieldComponent" )
			if( comps ~= nil ) then
				for i,comp in ipairs( comps ) do
					ComponentSetValue2( comp, "radius", shield_radius )
					ComponentSetValue2( comp, "recharge_speed", charge_speed )
				end
			end
			
			comps = EntityGetComponent( child_id, "ParticleEmitterComponent" )
			if( comps ~= nil ) then
				for i,comp in ipairs( comps ) do
					local minradius,maxradius = ComponentGetValue2( comp, "area_circle_radius" )
					
					if ( minradius ~= nil ) and ( maxradius ~= nil ) then
						if ( minradius == 0 ) then
							ComponentSetValue2( comp, "area_circle_radius", 0, shield_radius )
						elseif ( minradius == 10 ) then
							ComponentSetValue2( comp, "area_circle_radius", shield_radius, shield_radius )
						end
					end
				end
			end
			
			EntityAddTag( child_id, "perk_entity" )
			EntityAddChild( entity_who_picked, child_id )
		end,
		func_enemy = function( entity_perk_item, entity_who_picked )
			local x,y = EntityGetTransform( entity_who_picked )
			local child_id = EntityLoad( "data/entities/misc/perks/shield.xml", x, y )
			EntityAddChild( entity_who_picked, child_id )
		end,
		func_remove = function( entity_who_picked )
			local shield_num = 0
			GlobalsSetValue( "PERK_SHIELD_COUNT", tostring( shield_num ) )
		end,
	}
}

-- loop backwards through perk_list so we can remove entries
for i=#perk_list,1,-1 do
    local perk = perk_list[i]
    if remove_list[perk.id] then
        table.remove(perk_list, i)
    elseif rewrites[perk.id] then
        perk_list[i] = rewrites[perk.id]
    elseif reapply_fix_list[perk.id] then
        perk_list[i].do_not_reapply = true
    end
end