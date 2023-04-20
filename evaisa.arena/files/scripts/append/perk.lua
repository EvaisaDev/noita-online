local old_perk_get_spawn_order = perk_get_spawn_order

perk_get_spawn_order = function ( ignore_these_ )
    local oldSetRandomSeed = SetRandomSeed
    SetRandomSeed = function(x, y) 
        local local_seed = tonumber(GlobalsGetValue("local_seed", "0"))
        oldSetRandomSeed(local_seed, local_seed)
    end

    return old_perk_get_spawn_order(ignore_these_)
end

local old_perk_pickup = perk_pickup

perk_pickup = function( entity_item, entity_who_picked, item_name, do_cosmetic_fx, kill_other_perks, no_perk_entity_ )
    local oldSetRandomSeed = SetRandomSeed
    SetRandomSeed = function(x, y) 
        local local_seed = math.random(0, 999999999)
        oldSetRandomSeed(local_seed, local_seed)
    end

    return old_perk_pickup( entity_item, entity_who_picked, item_name, do_cosmetic_fx, kill_other_perks, no_perk_entity_ )
end