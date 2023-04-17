local old_order_deck = order_deck --[[function ()
    if gun.shuffle_deck_when_empty then
        SetRandomSeed( 0, 0 )
        -- shuffle the deck
        state_shuffled = true

        local rand = Random 
        local iterations = #deck
        local new_deck = { }

        GamePrint("Deck rng: "..tostring(Random(10000, 1000000)))

        for i = iterations, 1, -1 do  -- looping from iterations to 1 (inclusive)
            local index = rand( 1, i )
            local action = deck[ index ]
            table.remove( deck, index )
            table.insert( new_deck, action )
        end

        deck = new_deck
    else
        -- sort the deck
        if ( force_stop_draws == false ) then
            table.sort( deck, function(a,b) 
                    local a_index = a.deck_index or 0 
                    local b_index = b.deck_index or 0
                    return a_index<b_index
                end )
        else
            table.sort( deck, function(a,b) local a_ = a.deck_index or 0 local b_ = b.deck_index or 0 return a_<b_ end )
        end
    end
end]]

order_deck = function()
    local oldSetRandomSeed = SetRandomSeed
    SetRandomSeed = function() 

        local shooter = EntityGetRootEntity(GetUpdatedEntityID())

        --GamePrint(EntityGetName(shooter))

        oldSetRandomSeed(GameGetFrameNum(), GameGetFrameNum())

        local seed = 0
        if(EntityHasTag(shooter, "client"))then
            --GamePrint("2: shooter_rng_"..EntityGetName(shooter))
            seed = tonumber(GlobalsGetValue("shooter_rng_"..EntityGetName(shooter), "0")) or 0
        elseif(EntityHasTag(shooter, "player_unit"))then
            seed = Random(10, 10000000)
            GlobalsSetValue("player_rng", tostring(seed))
        end

        

       -- GamePrint("Seed forced to: "..tostring(seed))

        oldSetRandomSeed(seed, seed)
    end

    old_order_deck()

    SetRandomSeed = oldSetRandomSeed
end


--local json = dofile("mods/evaisa.arena/lib/json.lua")

--[[
local smallfolk = dofile("mods/evaisa.arena/lib/smallfolk.lua")

local old_start_shot = _start_shot

_start_shot = function( current_mana )

    local shooter = EntityGetRootEntity(GetUpdatedEntityID())

    old_start_shot(current_mana)

    local cast_state_data = {
        first_shot = first_shot,
        reloading = reloading,
        start_reload = start_reload,
        got_projectiles = got_projectiles,
        state_from_game = state_from_game,
        discarded = {},
        deck = {},
        hand = {},
        c = c,
        current_projectile = current_projectile,
        current_reload_time = current_reload_time,
        shot_effects = shot_effects,
        active_extra_modifiers = active_extra_modifiers,
        mana = mana,
        state_shuffled = state_shuffled,
        state_cards_drawn = state_cards_drawn,
        state_discarded_action = state_discarded_action,
        state_destroyed_action = state_destroyed_action,
        playing_permanent_card = playing_permanent_card,
    }

    for k, v in pairs(discarded) do
        table.insert(cast_state_data.discarded, {id = v.id, inventoryitem_id = v.inventoryitem_id})
    end

    for k, v in pairs(deck) do
        table.insert(cast_state_data.deck, {id = v.id, inventoryitem_id = v.inventoryitem_id})
    end

    for k, v in pairs(hand) do
        table.insert(cast_state_data.hand, {id = v.id, inventoryitem_id = v.inventoryitem_id})
    end

    

    if(EntityHasTag(shooter, "client"))then

        

        local cast_state_data_str = GlobalsGetValue("shooter_cast_state_"..EntityGetName(shooter))

        if(cast_state_data_str ~= nil and cast_state_data_str ~= "")then
            cast_state_data = smallfolk.loadsies(cast_state_data_str)

            GamePrint("Loaded cast state data for "..EntityGetName(shooter))

            for k, v in pairs(cast_state_data) do
                if(k == "discarded")then
                    -- loop through the data, and move the correct ones from hand or deck to discarded
                    -- make sure both id and inventoryitem_id match
                    for k2, v2 in pairs(v) do
                        for k3, v3 in pairs(hand) do
                            if(v2.id == v3.id and v2.inventoryitem_id == v3.inventoryitem_id)then
                                table.remove(hand, k3)
                                table.insert(discarded, v3)
                                break
                            end
                        end

                        for k3, v3 in pairs(deck) do
                            if(v2.id == v3.id and v2.inventoryitem_id == v3.inventoryitem_id)then
                                table.remove(deck, k3)
                                table.insert(discarded, v3)
                                break
                            end
                        end
                    end
                elseif(k == "deck")then
                    -- loop through the data, and move the correct ones from hand or discarded to deck
                    -- make sure both id and inventoryitem_id match
                    for k2, v2 in pairs(v) do
                        for k3, v3 in pairs(hand) do
                            if(v2.id == v3.id and v2.inventoryitem_id == v3.inventoryitem_id)then
                                table.remove(hand, k3)
                                table.insert(deck, v3)
                                break
                            end
                        end

                        for k3, v3 in pairs(discarded) do
                            if(v2.id == v3.id and v2.inventoryitem_id == v3.inventoryitem_id)then
                                table.remove(discarded, k3)
                                table.insert(deck, v3)
                                break
                            end
                        end
                    end
                elseif(k == "hand")then
                    -- loop through the data, and move the correct ones from deck or discarded to hand
                    -- make sure both id and inventoryitem_id match
                    for k2, v2 in pairs(v) do
                        for k3, v3 in pairs(deck) do
                            if(v2.id == v3.id and v2.inventoryitem_id == v3.inventoryitem_id)then
                                table.remove(deck, k3)
                                table.insert(hand, v3)
                                break
                            end
                        end

                        for k3, v3 in pairs(discarded) do
                            if(v2.id == v3.id and v2.inventoryitem_id == v3.inventoryitem_id)then
                                table.remove(discarded, k3)
                                table.insert(hand, v3)
                                break
                            end
                        end
                    end
                else
                    _G[k] = v
                end
            end
        end
    elseif(EntityHasTag(shooter, "player_unit"))then
        GlobalsSetValue("player_cast_state", smallfolk.dumpsies(cast_state_data))
    end

end]]