local player = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/player.lua")
dofile_once("data/scripts/gun/procedural/gun_action_utils.lua")
dofile_once("data/scripts/gun/gun_enums.lua")
dofile( "data/scripts/perks/perk.lua" )
local rng = dofile_once("mods/evaisa.arena/lib/rng.lua")

local a, b, c, d, e, f = GameGetDateAndTimeLocal()

local function is_wand(entity_id)
    local ability_component = EntityGetFirstComponentIncludingDisabled(entity_id, "AbilityComponent")
    if ability_component == nil then return false end
	return ComponentGetValue2(ability_component, "use_gun_script") == true
end

local function get_all_wands()
    local player_entity = player.Get()
    if(player_entity == nil)then return {} end
    local items = GameGetAllInventoryItems(player_entity)
    local wands = {}
    for _, item in ipairs(items) do
        if(is_wand(item))then
            table.insert(wands, item)
        end
    end
    return wands
end

local function get_active_or_random_wand()
    local player_entity = player.Get()
    if(player_entity == nil)then return {} end

    local chosen_wand = nil;
    local wands = {};
    local items = GameGetAllInventoryItems( player_entity );
    for key, item in pairs( items ) do
        if is_wand( item ) then
            table.insert( wands, item );
        end
    end
    if #wands > 0 then
        local inventory2 = EntityGetFirstComponent( player_entity, "Inventory2Component" );
        local active_item = ComponentGetValue2( inventory2, "mActiveItem" );
        for _,wand in pairs( wands ) do
            if wand == active_item then
                chosen_wand = wand;
                break;
            end
        end
        if chosen_wand == nil then
            chosen_wand =  wands[Random( 1, #wands )];
        end
        return chosen_wand;
    end
end

upgrades = {
    -- increase max mana all wands
    --[[{
		id = "MAX_MANA_ALL",
		ui_name = "$arena_upgrades_max_mana_all_name",
		ui_description = "$arena_upgrades_max_mana_all_description",
		card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/max_mana.png",
        card_background = "mods/evaisa.arena/files/sprites/ui/upgrades/card_blank.png",
        card_border = "mods/evaisa.arena/files/sprites/ui/upgrades/border_default.png",
        card_border_tint = {0.52, 0.31, 0.52},
        card_symbol_tint = {0.52, 0.31, 0.52},
        weight = 0.2,
		func = function( entity_who_picked )
			local x,y = EntityGetTransform( entity_who_picked )
			
            local wands = get_all_wands()

            for k, wand in ipairs(wands)do
            
                SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), wand + y + GameGetFrameNum() )

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local mana_max = ComponentGetValue2( comp, "mana_max" )
                    
                    mana_max = math.min( mana_max + Random( 5, 15 ) * Random( 5, 15 ), 20000 )

                    ComponentSetValue2( comp, "mana_max", mana_max )
                end
 
            end
		end,
	},
    -- increase mana recharge all wands
    {
        id = "MANA_RECHARGE_ALL",
        ui_name = "$arena_upgrades_mana_recharge_all_name",
        ui_description = "$arena_upgrades_mana_recharge_all_description",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/mana_recharge.png",
        card_background = "mods/evaisa.arena/files/sprites/ui/upgrades/card_blank.png",
        card_border = "mods/evaisa.arena/files/sprites/ui/upgrades/border_default.png",
        card_border_tint = {0.52, 0.31, 0.52},
        card_symbol_tint = {0.52, 0.31, 0.52},
        weight = 0.2,
        func = function( entity_who_picked )
            local x,y = EntityGetTransform( entity_who_picked )
            
            local wands = get_all_wands()

            for k, wand in ipairs(wands)do
            
                SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), wand + y + GameGetFrameNum() )

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local mana_charge_speed = ComponentGetValue2( comp, "mana_charge_speed" )
                    
                    mana_charge_speed = math.min( math.min( mana_charge_speed * Random( 100, 175 ) * 0.01, mana_charge_speed + Random( 50, 150 ) ), 20000 )

                    ComponentSetValue2( comp, "mana_charge_speed", mana_charge_speed )
                end
            end
        end,
    },
    -- reduce cast delay all wands
    {
        id = "CAST_DELAY_ALL",
        ui_name = "$arena_upgrades_cast_delay_all_name",
        ui_description = "$arena_upgrades_cast_delay_all_description",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/cast_delay.png",
        card_background = "mods/evaisa.arena/files/sprites/ui/upgrades/card_blank.png",
        card_border = "mods/evaisa.arena/files/sprites/ui/upgrades/border_default.png",
        card_border_tint = {0.52, 0.31, 0.52},
        card_symbol_tint = {0.52, 0.31, 0.52},
        weight = 0.2,
        func = function( entity_who_picked )
            local x,y = EntityGetTransform( entity_who_picked )
            
            local wands = get_all_wands()

            for k, wand in ipairs(wands)do
            
                SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), wand + y + GameGetFrameNum() )

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local cast_delay = ComponentObjectGetValue2( comp, "gunaction_config", "fire_rate_wait" )
                    cast_delay = cast_delay * 0.8 - 5
                    ComponentObjectSetValue2( comp, "gunaction_config", "fire_rate_wait", cast_delay )
                end
            end
        end,
    },
    -- reduce reload time all wands
    {
        id = "RELOAD_TIME_ALL",
        ui_name = "$arena_upgrades_reload_time_all_name",
        ui_description = "$arena_upgrades_reload_time_all_description",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/reload.png",
        card_background = "mods/evaisa.arena/files/sprites/ui/upgrades/card_blank.png",
        card_border = "mods/evaisa.arena/files/sprites/ui/upgrades/border_default.png",
        card_border_tint = {0.52, 0.31, 0.52},
        card_symbol_tint = {0.52, 0.31, 0.52},
        weight = 0.2,
        func = function( entity_who_picked )
            local x,y = EntityGetTransform( entity_who_picked )
            
            local wands = get_all_wands()

            for k, wand in ipairs(wands)do
            
                SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), wand + y + GameGetFrameNum() )

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local recharge_time = ComponentObjectGetValue2( comp, "gunaction_config", "reload_time" )
                    recharge_time = recharge_time * 0.8 - 5
                    ComponentObjectSetValue2( comp, "gunaction_config", "reload_time", recharge_time)
                end
            end
        end,
    },
    -- increase spread all wands
    {
        id = "INCREASE_SPREAD_ALL",
        ui_name = "$arena_upgrades_increase_spread_all_name",
        ui_description = "$arena_upgrades_increase_spread_all_description",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/high_spread.png",
        card_background = "mods/evaisa.arena/files/sprites/ui/upgrades/card_blank.png",
        card_border = "mods/evaisa.arena/files/sprites/ui/upgrades/border_default.png",
        card_border_tint = {0.52, 0.31, 0.52},
        card_symbol_tint = {0.52, 0.31, 0.52},
        weight = 0.2,
        func = function( entity_who_picked )
            local x,y = EntityGetTransform( entity_who_picked )
            
            local wands = get_all_wands()

            for k, wand in ipairs(wands)do
            
                SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), wand + y + GameGetFrameNum() )

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local spread_degrees = ComponentObjectGetValue2( comp, "gunaction_config", "spread_degrees" )

                    spread_degrees = spread_degrees + Random( 5, 15 )

                    ComponentObjectSetValue2( comp, "gunaction_config", "spread_degrees", spread_degrees )
                end
            end
        end,
    },
    -- reduce spread all wands
    {
        id = "REDUCE_SPREAD_ALL",
        ui_name = "$arena_upgrades_reduce_spread_all_name",
        ui_description = "$arena_upgrades_reduce_spread_all_description",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/low_spread.png",
        card_background = "mods/evaisa.arena/files/sprites/ui/upgrades/card_blank.png",
        card_border = "mods/evaisa.arena/files/sprites/ui/upgrades/border_default.png",
        card_border_tint = {0.52, 0.31, 0.52},
        card_symbol_tint = {0.52, 0.31, 0.52},
        weight = 0.2,
        func = function( entity_who_picked )
            local x,y = EntityGetTransform( entity_who_picked )
            
            local wands = get_all_wands()

            for k, wand in ipairs(wands)do
            
                SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), wand + y + GameGetFrameNum() )

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local spread_degrees = ComponentObjectGetValue2( comp, "gunaction_config", "spread_degrees" )

                    spread_degrees = spread_degrees - Random( 5, 15 )

                    ComponentObjectSetValue2( comp, "gunaction_config", "spread_degrees", spread_degrees )
                end
            end
        end,
    },
    -- increase multicast count all wands
    {
        id = "INCREASE_MULTICAST_ALL",
        ui_name = "$arena_upgrades_increase_multicast_all_name",
        ui_description = "$arena_upgrades_increase_multicast_all_description",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/multicast.png",
        card_background = "mods/evaisa.arena/files/sprites/ui/upgrades/card_blank.png",
        card_border = "mods/evaisa.arena/files/sprites/ui/upgrades/border_default.png",
        card_border_tint = {0.52, 0.31, 0.52},
        card_symbol_tint = {0.52, 0.31, 0.52},
        weight = 0.2,
        func = function( entity_who_picked )
            local x,y = EntityGetTransform( entity_who_picked )
            
            local wands = get_all_wands()

            for k, wand in ipairs(wands)do
            
                SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), wand + y + GameGetFrameNum() )

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local multicast_count = ComponentObjectGetValue( comp, "gun_config", "actions_per_round" )

                    multicast_count = multicast_count + 1

                    ComponentObjectSetValue2( comp, "gun_config", "actions_per_round", multicast_count )
                end
            end
        end,
    },
    -- reduce multicast count all wands
    {
        id = "REDUCE_MULTICAST_ALL",
        ui_name = "$arena_upgrades_reduce_multicast_all_name",
        ui_description = "$arena_upgrades_reduce_multicast_all_description",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/anti_multicast.png",
        card_background = "mods/evaisa.arena/files/sprites/ui/upgrades/card_rare.png",
        card_symbol_tint = {0.52, 0.31, 0.52},
        weight = 0.2,
        func = function( entity_who_picked )
            local x,y = EntityGetTransform( entity_who_picked )
            
            local wands = get_all_wands()

            for k, wand in ipairs(wands)do
            
                SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), wand + y + GameGetFrameNum() )

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local multicast_count = ComponentObjectGetValue2( comp, "gun_config", "actions_per_round" )

                    multicast_count = multicast_count - 1

                    if(multicast_count < 1)then
                        multicast_count = 1
                    end

                    ComponentObjectSetValue2( comp, "gun_config", "actions_per_round", multicast_count )
                end
            end
        end,
    },
    -- increase slot count all wands
    {
        id = "SLOTS_ALL",
        ui_name = "$arena_upgrades_slots_all_name",
        ui_description = "$arena_upgrades_slots_all_description",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/slots.png",
        card_background = "mods/evaisa.arena/files/sprites/ui/upgrades/card_blank.png",
        card_border = "mods/evaisa.arena/files/sprites/ui/upgrades/border_default.png",
        card_border_tint = {0.52, 0.31, 0.52},
        card_symbol_tint = {0.52, 0.31, 0.52},
        weight = 0.2,
        func = function(entity_who_picked)
            local x,y = EntityGetTransform( entity_who_picked )
            
            local wands = get_all_wands()

            for k, wand in ipairs(wands)do
            
                SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), wand + y + GameGetFrameNum() )

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local deck_capacity = ComponentObjectGetValue2( comp, "gun_config", "deck_capacity" )

                    deck_capacity = deck_capacity + 1

                    ComponentObjectSetValue2( comp, "gun_config", "deck_capacity", deck_capacity)
                end
            end
        end,
    },]]
    -- add always cast all wands
    {
        id = "ADD_ALWAYS_CAST_ALL",
        ui_name = "$arena_upgrades_add_always_cast_all_name",
        ui_description = "$arena_upgrades_add_always_cast_all_description",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/always_cast.png",
        card_background = "mods/evaisa.arena/files/sprites/ui/upgrades/card_blank.png",
        card_border = "mods/evaisa.arena/files/sprites/ui/upgrades/border_default.png",
        card_border_tint = {0.52, 0.31, 0.52},
        card_symbol_tint = {0.52, 0.31, 0.52},
        weight = 0.2,
        func = function( entity_who_picked )
            local x,y = EntityGetTransform( entity_who_picked )
            
            local wands = get_all_wands()

            for k, wand in ipairs(wands)do
            
                SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), wand + y + GameGetFrameNum() )

                dofile("mods/evaisa.arena/files/scripts/misc/random_action.lua")
                GetRandomActionWithType = function( x, y, level, type, i)
                    --print("Custom get action called!")
                    return RandomActionWithType( level, type ) or "LIGHT_BULLET"
                end
    
                local good_cards = {}
                local good_cards_init = { "DAMAGE", "CRITICAL_HIT", "HOMING", "SPEED", "ACID_TRAIL", "SINEWAVE" }
                
                for k, v in ipairs(good_cards_init)do
                    if(not GameHasFlagRun("spell_blacklist_"..v))then
                        table.insert(good_cards, v)
                    end
                end
                
                local r = Random( 1, 100 )
                local level = 6
    
                local card = good_cards[ Random( 1, #good_cards ) ] or RandomAction(level)
    
                if( r <= 50 ) then
                    local p = Random(1,100)
    
                    if( p <= 86 ) then
                        card = GetRandomActionWithType( x + Random(-1000, 1000), y + Random(-1000, 1000), level, ACTION_TYPE_MODIFIER, 666 )
                    elseif( p <= 93 ) then
                        card = GetRandomActionWithType( x + Random(-1000, 1000), y + Random(-1000, 1000), level, ACTION_TYPE_STATIC_PROJECTILE, 666 )
                    elseif ( p < 100 ) then
                        card = GetRandomActionWithType( x + Random(-1000, 1000), y + Random(-1000, 1000), level, ACTION_TYPE_PROJECTILE, 666 )
                    else
                        card = GetRandomActionWithType( x + Random(-1000, 1000), y + Random(-1000, 1000), level, ACTION_TYPE_UTILITY, 666 )
                    end
                end

                if(card == nil)then
                    goto continue
                end

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local deck_capacity = ComponentObjectGetValue2( comp, "gun_config", "deck_capacity" )
                    local deck_capacity2 = EntityGetWandCapacity( wand )
                    
                    local always_casts = deck_capacity - deck_capacity2
                    
                    if ( always_casts < 4 ) then
                        AddGunActionPermanent( wand, card )
                    else
                        GamePrintImportant( "$log_always_cast_failed", "$logdesc_always_cast_failed" )
                    end
                end
                ::continue::
            end
        end,
    },
    -- unshuffle all wands
    --[[{
        id = "UNSHUFFLE_ALL",
        ui_name = "$arena_upgrades_unshuffle_all_name",
        ui_description = "$arena_upgrades_unshuffle_all_description",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/unshuffle.png",
        card_background = "mods/evaisa.arena/files/sprites/ui/upgrades/card_blank.png",
        card_border = "mods/evaisa.arena/files/sprites/ui/upgrades/border_default.png",
        card_border_tint = {0.52, 0.31, 0.52},
        card_symbol_tint = {0.52, 0.31, 0.52},
        weight = 0.2,
        func = function(entity_who_picked)
            local x,y = EntityGetTransform( entity_who_picked )
            
            local wands = get_all_wands()

            for k, wand in ipairs(wands)do
            
                SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), wand + y + GameGetFrameNum() )

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    ComponentObjectSetValue2( comp, "gun_config", "shuffle_deck_when_empty", false )
                end
            end
        end,
    },
    -- increase max mana current wand
    {
		id = "MAX_MANA",
		ui_name = "$arena_upgrades_max_mana_name",
		ui_description = "$arena_upgrades_max_mana_description",
		card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/max_mana.png",
        weight = 0.8,
		func = function( entity_who_picked )
			local x,y = EntityGetTransform( entity_who_picked )
			
            -- increase max mana of only active wand
            SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), y + GameGetFrameNum() )

            local wand = get_active_or_random_wand()

            if(wand ~= nil)then
                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local mana_max = ComponentGetValue2( comp, "mana_max" )
                    
                    mana_max = math.min( mana_max + Random( 5, 15 ) * Random( 5, 15 ), 20000 )

                    ComponentSetValue2( comp, "mana_max", mana_max )
                end
            end
		end,
    },
    -- increase mana recharge current wand
    {
        id = "MANA_RECHARGE",
        ui_name = "$arena_upgrades_mana_recharge_name",
        ui_description = "$arena_upgrades_mana_recharge_description",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/mana_recharge.png",
        weight = 0.8,
        func = function( entity_who_picked )
            local x,y = EntityGetTransform( entity_who_picked )
            
            SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), y + GameGetFrameNum() )

            local wand = get_active_or_random_wand()

            if(wand ~= nil)then

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local mana_charge_speed = ComponentGetValue2( comp, "mana_charge_speed" )
                    
                    mana_charge_speed = math.min( math.min( mana_charge_speed * Random( 100, 175 ) * 0.01, mana_charge_speed + Random( 50, 150 ) ), 20000 )

                    ComponentSetValue2( comp, "mana_charge_speed", mana_charge_speed )
                end
            end
        end,
    },
    -- reduce cast delay current wand
    {
        id = "CAST_DELAY",
        ui_name = "$arena_upgrades_cast_delay_name",
        ui_description = "$arena_upgrades_cast_delay_description",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/cast_delay.png",
        weight = 0.8,
        func = function( entity_who_picked )
            local x,y = EntityGetTransform( entity_who_picked )
            
            SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), y + GameGetFrameNum() )

            local wand = get_active_or_random_wand()

            if(wand ~= nil)then

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local cast_delay = ComponentObjectGetValue2( comp, "gunaction_config", "fire_rate_wait" )
                    cast_delay = cast_delay * 0.8 - 5
                    ComponentObjectSetValue2( comp, "gunaction_config", "fire_rate_wait", cast_delay )
                end
            end
        end,
    },
    -- reduce reload time current wand
    {
        id = "RELOAD_TIME",
        ui_name = "$arena_upgrades_reload_time_name",
        ui_description = "$arena_upgrades_reload_time_description",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/reload.png",
        weight = 0.8,
        func = function( entity_who_picked )
            local x,y = EntityGetTransform( entity_who_picked )
            
            SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), y + GameGetFrameNum() )

            local wand = get_active_or_random_wand()

            if(wand ~= nil)then

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local recharge_time = ComponentObjectGetValue2( comp, "gun_config", "reload_time" )
                    recharge_time = recharge_time * 0.8 - 5
                    ComponentObjectSetValue2( comp, "gun_config", "reload_time", recharge_time)
                end
            end
        end,
    },    
    -- increase spread current wand
    {
        id = "INCREASE_SPREAD",
        ui_name = "$arena_upgrades_increase_spread_name",
        ui_description = "$arena_upgrades_increase_spread_description",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/high_spread.png",
        weight = 0.8,
        func = function( entity_who_picked )
            local x,y = EntityGetTransform( entity_who_picked )
            
            SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), y + GameGetFrameNum() )

            local wand = get_active_or_random_wand()

            if(wand ~= nil)then

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local spread_degrees = ComponentObjectGetValue2( comp, "gunaction_config", "spread_degrees" )

                    spread_degrees = spread_degrees + Random( 5, 15 )

                    ComponentObjectSetValue2( comp, "gunaction_config", "spread_degrees", spread_degrees )
                end
            end
        end,
    },
    -- reduce spread all wands
    {
        id = "REDUCE_SPREAD",
        ui_name = "$arena_upgrades_reduce_spread_name",
        ui_description = "$arena_upgrades_reduce_spread_description",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/low_spread.png",
        weight = 0.8,
        func = function( entity_who_picked )
            local x,y = EntityGetTransform( entity_who_picked )
            
            SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), y + GameGetFrameNum() )

            local wand = get_active_or_random_wand()

            if(wand ~= nil)then

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local spread_degrees = ComponentObjectGetValue2( comp, "gunaction_config", "spread_degrees" )

                    spread_degrees = spread_degrees - Random( 5, 15 )

                    ComponentObjectSetValue2( comp, "gunaction_config", "spread_degrees", spread_degrees )
                end
            end
        end,
    },    
    -- increase multicast count all wands
    {
        id = "INCREASE_MULTICAST",
        ui_name = "$arena_upgrades_increase_multicast_name",
        ui_description = "$arena_upgrades_increase_multicast_description",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/multicast.png",
        weight = 0.8,
        func = function( entity_who_picked )
            local x,y = EntityGetTransform( entity_who_picked )
            
            SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), y + GameGetFrameNum() )

            local wand = get_active_or_random_wand()

            if(wand ~= nil)then

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local multicast_count = ComponentObjectGetValue( comp, "gun_config", "actions_per_round" )

                    multicast_count = multicast_count + 1

                    ComponentObjectSetValue2( comp, "gun_config", "actions_per_round", multicast_count )
                end
            end
        end,
    },
    -- reduce multicast count all wands
    {
        id = "REDUCE_MULTICAST",
        ui_name = "$arena_upgrades_reduce_multicast_name",
        ui_description = "$arena_upgrades_reduce_multicast_description",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/anti_multicast.png",
        weight = 0.8,
        func = function( entity_who_picked )
            local x,y = EntityGetTransform( entity_who_picked )
            
            SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), y + GameGetFrameNum() )

            local wand = get_active_or_random_wand()

            if(wand ~= nil)then

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local multicast_count = ComponentObjectGetValue2( comp, "gun_config", "actions_per_round" )

                    multicast_count = multicast_count - 1

                    if(multicast_count < 1)then
                        multicast_count = 1
                    end

                    ComponentObjectSetValue2( comp, "gun_config", "actions_per_round", multicast_count )
                end
            end
        end,
    },
    -- increase slot count all wands
    {
        id = "SLOTS",
        ui_name = "$arena_upgrades_slots_name",
        ui_description = "$arena_upgrades_slots_description",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/slots.png",
        weight = 0.8,
        func = function(entity_who_picked)
            local x,y = EntityGetTransform( entity_who_picked )
            
            SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), y + GameGetFrameNum() )

            local wand = get_active_or_random_wand()

            if(wand ~= nil)then

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local deck_capacity = ComponentObjectGetValue2( comp, "gun_config", "deck_capacity" )

                    deck_capacity = deck_capacity + 1

                    ComponentObjectSetValue2( comp, "gun_config", "deck_capacity", deck_capacity)
                end
            end
        end,
    },
    -- add always cast all wands
    {
        id = "ADD_ALWAYS_CAST",
        ui_name = "$arena_upgrades_add_always_cast_name",
        ui_description = "$arena_upgrades_add_always_cast_description",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/always_cast.png",
        weight = 0.8,
        func = function( entity_who_picked )
            local x,y = EntityGetTransform( entity_who_picked )
            
            --SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), y + GameGetFrameNum() )

            local random = rng.new(entity_who_picked + x + (GameGetFrameNum() + GameGetRealWorldTimeSinceStarted() + a + b + c + d + e + f) / 2)

            local wand = get_active_or_random_wand()

            if(wand ~= nil)then

                dofile("mods/evaisa.arena/files/scripts/misc/random_action.lua")
                GetRandomActionWithType = function( x, y, level, type, i)
                    --print("Custom get action called!")
                    return RandomActionWithType( level, type ) or "LIGHT_BULLET"
                end
    
                local good_cards = {}
                local good_cards_init = { "DAMAGE", "CRITICAL_HIT", "HOMING", "SPEED", "ACID_TRAIL", "SINEWAVE" }
                
                for k, v in ipairs(good_cards_init)do
                    if(not GameHasFlagRun("spell_blacklist_"..v))then
                        table.insert(good_cards, v)
                    end
                end
                
                local r = Random( 1, 100 )
                local level = 6
    
                local card = good_cards[ Random( 1, #good_cards ) ] or RandomAction(level)
    
                if( r <= 50 ) then
                    local p = random.range(1,100)
    
                    if( p <= 86 ) then
                        card = GetRandomActionWithType( x + random.range(-1000, 1000), y + random.range(-1000, 1000), level, ACTION_TYPE_MODIFIER, 666 )
                    elseif( p <= 93 ) then
                        card = GetRandomActionWithType( x + random.range(-1000, 1000), y + random.range(-1000, 1000), level, ACTION_TYPE_STATIC_PROJECTILE, 666 )
                    elseif ( p < 100 ) then
                        card = GetRandomActionWithType( x + random.range(-1000, 1000), y + random.range(-1000, 1000), level, ACTION_TYPE_PROJECTILE, 666 )
                    else
                        card = GetRandomActionWithType( x + random.range(-1000, 1000), y + random.range(-1000, 1000), level, ACTION_TYPE_UTILITY, 666 )
                    end
                end

                if(card == nil)then
                    goto continue
                end

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local deck_capacity = ComponentObjectGetValue2( comp, "gun_config", "deck_capacity" )
                    local deck_capacity2 = EntityGetWandCapacity( wand )
                    
                    local always_casts = deck_capacity - deck_capacity2
                    
                    if ( always_casts < 4 ) then
                        AddGunActionPermanent( wand, card )
                    else
                        GamePrintImportant( "$log_always_cast_failed", "$logdesc_always_cast_failed" )
                    end
                end
                ::continue::
            end
        end,
    },
    -- unshuffle all wands
    {
        id = "UNSHUFFLE",
        ui_name = "$arena_upgrades_unshuffle_name",
        ui_description = "$arena_upgrades_unshuffle_description",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/unshuffle.png",
        weight = 0.8,
        func = function(entity_who_picked)
            local x,y = EntityGetTransform( entity_who_picked )
            
            SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), y + GameGetFrameNum() )

            local wand = get_active_or_random_wand()

            if(wand ~= nil)then

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    ComponentObjectSetValue2( comp, "gun_config", "shuffle_deck_when_empty", false )
                end
            end
        end,
    },    
    {
        id = "GOLD",
        ui_name = "Payday",
        ui_description = "You gain an additional set of gold this round.",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/gold.png",
        weight = 1.0,
        func = function(entity_who_picked)
            local rounds = tonumber(GlobalsGetValue("holyMountainCount", "0")) or 0
            -- Give gold
            local rounds_limited = math.max(0, math.min(math.ceil(rounds / 2), 7))

            local extra_gold_count = tonumber( GlobalsGetValue( "EXTRA_MONEY_COUNT", "0" ) )

            extra_gold_count = extra_gold_count + 1

            local extra_gold = 400 + (extra_gold_count * (70 * (rounds_limited * rounds_limited)))

            player.GiveGold( extra_gold )
        end,
    },
    {
        id = "RANDOM_PERK",
        ui_name = "Random Perk",
        ui_description = "You gain a random perk.",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/random_perk.png",
        weight = 1.0,
        func = function(entity_who_picked)


            local x,y = EntityGetTransform( entity_who_picked )
            local pid = perk_spawn_random(x,y)
            perk_pickup(pid, entity_who_picked, "", false, false )

        end,
    },
    {
        id = "HEALTH",
        ui_name = "Health",
        ui_description = "You gain 25% extra max health.",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/health.png",
        weight = 1.0,
        func = function(entity_who_picked)

            local x,y = EntityGetTransform( entity_who_picked )
            local damagemodels = EntityGetComponent( entity_who_picked, "DamageModelComponent" )
            
            if( damagemodels ~= nil ) then
                for i,damagemodel in ipairs(damagemodels) do
                    local max_hp = tonumber( ComponentGetValue( damagemodel, "max_hp" ) )
                    local max_hp_new = max_hp * 1.25
                    ComponentSetValue( damagemodel, "max_hp", max_hp_new )
                    ComponentSetValue( damagemodel, "hp", max_hp_new )
                end
            end

        end,
    }]]
}