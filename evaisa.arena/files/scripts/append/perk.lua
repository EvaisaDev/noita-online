local old_perk_get_spawn_order = perk_get_spawn_order

perk_get_spawn_order = function ( ignore_these_ )
    local oldSetRandomSeed = SetRandomSeed
    SetRandomSeed = function(x, y) 
        local local_seed = tonumber(GlobalsGetValue("local_seed", "0"))
        -- GlobalsSetValue("world_seed", tostring(seed))
        if(GameHasFlagRun("perk_sync"))then
            local_seed = tonumber(GlobalsGetValue("world_seed", "0")) or 0
        end
        oldSetRandomSeed(local_seed, local_seed)
    end

    ignore_these_ = ignore_these_ or {}
    
    for i, perk in ipairs(perk_list)do
        if GameHasFlagRun("perk_blacklist_"..perk.id) then
            table.insert(ignore_these_, perk.id)
        end
    end

    return old_perk_get_spawn_order(ignore_these_)
end

local old_perk_pickup = perk_pickup

perk_pickup = function( entity_item, entity_who_picked, item_name, do_cosmetic_fx, kill_other_perks, no_perk_entity_ )
    local oldSetRandomSeed = SetRandomSeed
    SetRandomSeed = function(x, y) 
        local local_seed = math.random(0, 999999999)
        local rounds = tonumber(GlobalsGetValue("holyMountainCount", "0")) or 0
        if(GameHasFlagRun("perk_sync"))then
            local_seed = ((tonumber(GlobalsGetValue("world_seed", "0")) or 1) * 214) * rounds

        end
        oldSetRandomSeed(local_seed, local_seed)
    end

    GameAddFlagRun("picked_perk")

    return old_perk_pickup( entity_item, entity_who_picked, item_name, do_cosmetic_fx, kill_other_perks, no_perk_entity_ )
end

local old_perk_spawn_many = perk_spawn_many

perk_spawn_many = function( x, y, dont_remove_others_, ignore_these_ )
    local perk_number = 0
    for i, perk in ipairs(perk_list)do
        if not GameHasFlagRun("perk_blacklist_"..perk.id) then
            perk_number = perk_number + 1
        end
    end
    if(perk_number == 0)then
        return
    end
    old_perk_spawn_many( x, y, dont_remove_others_, ignore_these_ )
end