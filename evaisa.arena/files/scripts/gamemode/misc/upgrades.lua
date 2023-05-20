local player = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/player.lua")
dofile_once("data/scripts/gun/procedural/gun_action_utils.lua")
dofile_once("data/scripts/gun/gun_enums.lua")
dofile( "data/scripts/perks/perk.lua" )

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

upgrades = {
    -- max mana
    -- mana regen
    -- cast delay
    -- recharge time
    -- spread up
    -- spread down
    -- projectile_speed_up
    -- projectile_speed_down
    -- cast count
    -- slots
    -- always cast
    -- shuffle / unshuffle
    -- additional gold
    -- random perk
    -- health x1.25
    {
		id = "MAX_MANA",
		ui_name = "Max Mana Upgrade",
		ui_description = "Upgrade the max mana of all your wands",
		card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/max_mana.png",
        weight = 1.0,
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
    {
        id = "MANA_RECHARGE",
        ui_name = "Mana Recharge Upgrade",
        ui_description = "Upgrade the mana recharge of all your wands",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/mana_recharge.png",
        weight = 1.0,
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
    {
        id = "CAST_DELAY",
        ui_name = "Cast Delay Upgrade",
        ui_description = "Upgrade the cast delay of all your wands",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/cast_delay.png",
        weight = 1.0,
        func = function( entity_who_picked )
            local x,y = EntityGetTransform( entity_who_picked )
            
            local wands = get_all_wands()

            for k, wand in ipairs(wands)do
            
                SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), wand + y + GameGetFrameNum() )

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local cast_delay = tonumber( ComponentObjectGetValue( comp, "gunaction_config", "fire_rate_wait" ) )
                    cast_delay = cast_delay * 0.8 - 5
                    ComponentObjectSetValue( comp, "gunaction_config", "fire_rate_wait", tostring( cast_delay ) )
                end
            end
        end,
    },
    {
        id = "RELOAD_TIME",
        ui_name = "Recharge Time Upgrade",
        ui_description = "Upgrade the recharge time of all your wands",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/reload.png",
        weight = 1.0,
        func = function( entity_who_picked )
            local x,y = EntityGetTransform( entity_who_picked )
            
            local wands = get_all_wands()

            for k, wand in ipairs(wands)do
            
                SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), wand + y + GameGetFrameNum() )

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local cast_delay = tonumber( ComponentObjectGetValue( comp, "gunaction_config", "fire_rate_wait" ) )
                    cast_delay = cast_delay * 0.8 - 5
                    ComponentObjectSetValue( comp, "gunaction_config", "fire_rate_wait", tostring( cast_delay ) )
                end
            end
        end,
    },
    {
        id = "INCREASE_SPREAD",
        ui_name = "Increase Spread",
        ui_description = "Increase the spread of all your wands",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/high_spread.png",
        weight = 1.0,
        func = function( entity_who_picked )
            local x,y = EntityGetTransform( entity_who_picked )
            
            local wands = get_all_wands()

            for k, wand in ipairs(wands)do
            
                SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), wand + y + GameGetFrameNum() )

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local spread_degrees = tonumber( ComponentObjectGetValue( comp, "gunaction_config", "spread_degrees" ) )

                    spread_degrees = spread_degrees + Random( 5, 15 )

                    ComponentObjectSetValue( comp, "gunaction_config", "spread_degrees", tostring( spread_degrees ) )
                end
            end
        end,
    },
    {
        id = "REDUCE_SPREAD",
        ui_name = "Reduce Spread",
        ui_description = "Reduce the spread of all your wands",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/low_spread.png",
        weight = 1.0,
        func = function( entity_who_picked )
            local x,y = EntityGetTransform( entity_who_picked )
            
            local wands = get_all_wands()

            for k, wand in ipairs(wands)do
            
                SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), wand + y + GameGetFrameNum() )

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local spread_degrees = tonumber( ComponentObjectGetValue( comp, "gunaction_config", "spread_degrees" ) )

                    spread_degrees = spread_degrees - Random( 5, 15 )

                    ComponentObjectSetValue( comp, "gunaction_config", "spread_degrees", tostring( spread_degrees ) )
                end
            end
        end,
    },
    {
        id = "INCREASE_MULTICAST",
        ui_name = "Increase Multicast Count",
        ui_description = "Increase the multicast count of all your wands",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/multicast.png",
        weight = 1.0,
        func = function( entity_who_picked )
            local x,y = EntityGetTransform( entity_who_picked )
            
            local wands = get_all_wands()

            for k, wand in ipairs(wands)do
            
                SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), wand + y + GameGetFrameNum() )

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local multicast_count = tonumber( ComponentObjectGetValue( comp, "gun_config", "actions_per_round" ) )

                    multicast_count = multicast_count + 1

                    ComponentObjectSetValue( comp, "gun_config", "actions_per_round", tostring( multicast_count ) )
                end
            end
        end,
    },
    {
        id = "REDUCE_MULTICAST",
        ui_name = "Reduce Multicast Count",
        ui_description = "Reduce the multicast count of all your wands",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/anti_multicast.png",
        weight = 1.0,
        func = function( entity_who_picked )
            local x,y = EntityGetTransform( entity_who_picked )
            
            local wands = get_all_wands()

            for k, wand in ipairs(wands)do
            
                SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), wand + y + GameGetFrameNum() )

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local multicast_count = tonumber( ComponentObjectGetValue( comp, "gun_config", "actions_per_round" ) )

                    multicast_count = multicast_count - 1

                    if(multicast_count < 1)then
                        multicast_count = 1
                    end

                    ComponentObjectSetValue( comp, "gun_config", "actions_per_round", tostring( multicast_count ) )
                end
            end
        end,
    },
    {
        id = "SLOTS",
        ui_name = "Slots Upgrade",
        ui_description = "Upgrade the slot count of all your wands",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/slots.png",
        weight = 1.0,
        func = function(entity_who_picked)
            local x,y = EntityGetTransform( entity_who_picked )
            
            local wands = get_all_wands()

            for k, wand in ipairs(wands)do
            
                SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), wand + y + GameGetFrameNum() )

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local deck_capacity = tonumber( ComponentObjectGetValue( comp, "gun_config", "deck_capacity" ) )

                    deck_capacity = deck_capacity + 1

                    ComponentObjectSetValue( comp, "gun_config", "deck_capacity", tostring( deck_capacity ) )
                end
            end
        end,
    },
    {
        id = "ADD_ALWAYS_CAST",
        ui_name = "Add Always Cast",
        ui_description = "Add an always cast to all your wands",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/always_cast.png",
        weight = 1.0,
        func = function( entity_who_picked )
            local x,y = EntityGetTransform( entity_who_picked )
            
            local wands = get_all_wands()

            for k, wand in ipairs(wands)do
            
                SetRandomSeed( entity_who_picked + x + GameGetFrameNum(), wand + y + GameGetFrameNum() )

                local good_cards = { "DAMAGE", "CRITICAL_HIT", "HOMING", "SPEED", "ACID_TRAIL", "SINEWAVE" }

       
                local card = good_cards[ Random( 1, #good_cards ) ]
    
                local r = Random( 1, 100 )
                local level = 6
    
                if( r <= 50 ) then
                    local p = Random(1,100)
    
                    if( p <= 86 ) then
                        card = GetRandomActionWithType( x, y, level, ACTION_TYPE_MODIFIER, 666 )
                    elseif( p <= 93 ) then
                        card = GetRandomActionWithType( x, y, level, ACTION_TYPE_STATIC_PROJECTILE, 666 )
                    elseif ( p < 100 ) then
                        card = GetRandomActionWithType( x, y, level, ACTION_TYPE_PROJECTILE, 666 )
                    else
                        card = GetRandomActionWithType( x, y, level, ACTION_TYPE_UTILITY, 666 )
                    end
                end

                local comp = EntityGetFirstComponentIncludingDisabled( wand, "AbilityComponent" )
                
                if ( comp ~= nil ) then
                    local deck_capacity = ComponentObjectGetValue( comp, "gun_config", "deck_capacity" )
                    local deck_capacity2 = EntityGetWandCapacity( wand )
                    
                    local always_casts = deck_capacity - deck_capacity2
                    
                    if ( always_casts < 4 ) then
                        AddGunActionPermanent( wand, card )
                    else
                        GamePrintImportant( "$log_always_cast_failed", "$logdesc_always_cast_failed" )
                    end
                end
      
            end
        end,
    },
    {
        id = "UNSHUFFLE",
        ui_name = "Unshuffle",
        ui_description = "All of your wands are unshuffled",
        card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/unshuffle.png",
        weight = 1.0,
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
    }
}