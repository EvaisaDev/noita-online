local reapply_fix_list = {
    EXTRA_PERK = true,
    PERKS_LOTTERY = true,
    EXTRA_SHOP_ITEM = true,
    HEARTS_MORE_EXTRA_HP = true,
    GAMBLE = true,
}

local remove_list = {
    PEACE_WITH_GODS = true,
    ATTRACT_ITEMS = true,
    UNLIMITED_SPELLS = true,
    ABILITY_ACTIONS_MATERIALIZED = true,
    NO_WAND_EDITING = true,
    MEGA_BEAM_STONE = true,
    GOLD_IS_FOREVER = true,
    EXPLODING_GOLD = true,
    TRICK_BLOOD_MONEY = true,
    EXPLODING_CORPSES = true,
    INVISIBILITY = true,
    GLOBAL_GORE = true,
    REMOVE_FOG_OF_WAR = true,
    VAMPIRISM = true,
    WORM_ATTRACTOR = true,
    RADAR_ENEMY = true,
    FOOD_CLOCK = true,
    IRON_STOMACH = true,
    WAND_RADAR = true,
    ITEM_RADAR = true,
    MOON_RADAR = true,
    MAP = true,
    REVENGE_RATS = true,
    ATTACK_FOOT = true,
    LEGGY_FEET = true,
    PLAGUE_RATS = true,
    VOMIT_RATS = true,
    MOLD = true,
    WORM_SMALLER_HOLES = true,
    HOMUNCULUS = true,
    LUKKI_MINION = true,
    GENOME_MORE_HATRED = true,
    GENOME_MORE_LOVE = true,
    ANGRY_GHOST = true,
    HUNGRY_GHOST = true,
    DEATH_GHOST = true,
}

local allow_on_clients = {
    PERSONAL_LASER = true,
    EXTRA_MONEY_TRICK_KILL = true,
    HOVER_BOOST = true,
    FASTER_LEVITATION = true,
    STRONG_KICK = true,
    TELEKINESIS = true,
    EXTRA_HP = false,
    CORDYCEPS = true,
    RISKY_CRITICAL = true,
    FUNGAL_DISEASE = true,
    PROJECTILE_REPULSION_SECTOR = true,
    PROJECTILE_EATER_SECTOR = true,
    LOW_RECOIL = true,
    NO_MORE_KNOCKBACK = true,
    MANA_FROM_KILLS = true,
    ANGRY_LEVITATION = true,
    LASER_AIM = true,
}   

local skip_function_list = {
    
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
	},
    EXTRA_MONEY = {
		id = "EXTRA_MONEY",
		ui_name = "$perk_extra_money",
		ui_description = "You gain double gold.",
		ui_icon = "data/ui_gfx/perk_icons/extra_money.png",
		perk_icon = "data/items_gfx/perks/extra_money.png",
		stackable = true,
        skip_functions_on_load = true,
        game_effect = "EXTRA_MONEY",
        func = function( entity_perk_item, entity_who_picked, item_name )
            local extra_gold_count = tonumber( GlobalsGetValue( "EXTRA_MONEY_COUNT", "0" ) )
            extra_gold_count = extra_gold_count + 1
            GlobalsSetValue( "EXTRA_MONEY_COUNT", tostring( extra_gold_count ) )
        end
	},
    SAVING_GRACE = {
		id = "SAVING_GRACE",
		ui_name = "$perk_saving_grace",
		ui_description = "$perkdesc_saving_grace",
		ui_icon = "data/ui_gfx/perk_icons/saving_grace.png",
		perk_icon = "data/items_gfx/perks/saving_grace.png",
		stackable = STACKABLE_NO,
		func = function( entity_perk_item, entity_who_picked, item_name )
			GameAddFlagRun( "saving_grace" )
		end,
	},
    LEVITATION_TRAIL = {
		id = "LEVITATION_TRAIL",
		ui_name = "$perk_levitation_trail",
		ui_description = "$perkdesc_levitation_trail",
		ui_icon = "data/ui_gfx/perk_icons/levitation_trail.png",
		perk_icon = "data/items_gfx/perks/levitation_trail.png",
		stackable = STACKABLE_YES,
		stackable_is_rare = true,
		max_in_perk_pool = 2,
		func = function( entity_perk_item, entity_who_picked, item_name )
			EntityAddComponent( entity_who_picked, "LuaComponent", 
			{
				_tags="perk_component",
				script_source_file="mods/evaisa.arena/files/scripts/misc/levitation_trail.lua",
				execute_every_n_frame="3"
			} )
		end,
	},
    RESPAWN = {
		id = "RESPAWN",
		ui_name = "$perk_respawn",
		ui_description = "$perkdesc_respawn",
		ui_icon = "data/ui_gfx/perk_icons/respawn.png",
		perk_icon = "data/items_gfx/perks/respawn.png",
        --game_effect = "RESPAWN",
        skip_functions_on_load = true,
		do_not_remove = true,
		stackable = STACKABLE_YES,
		stackable_is_rare = true,
		func = function( entity_perk_item, entity_who_picked, item_name )
            local extra_gold_count = tonumber( GlobalsGetValue( "RESPAWN_COUNT", "0" ) )
            extra_gold_count = extra_gold_count + 1
            GlobalsSetValue( "RESPAWN_COUNT", tostring( extra_gold_count ) )
		end,
	},
}

-- loop backwards through perk_list so we can remove entries
for i=#perk_list,1,-1 do
    local perk = perk_list[i]
    if remove_list[perk.id] then
        table.remove(perk_list, i)
    else
        if rewrites[perk.id] then
            perk_list[i] = rewrites[perk.id]
        end
        
        if reapply_fix_list[perk.id] then
            perk_list[i].do_not_reapply = true
        end

        if allow_on_clients[perk.id] then
            perk_list[i].run_on_clients = true
        elseif allow_on_clients[perk.id] ~= nil and allow_on_clients[perk.id] == false then
            perk_list[i].run_on_clients = false
            perk_list[i].usable_by_enemies = false
        end

        if skip_function_list[perk.id] then
            perk_list[i].skip_functions_on_load = true
        end
    end
end