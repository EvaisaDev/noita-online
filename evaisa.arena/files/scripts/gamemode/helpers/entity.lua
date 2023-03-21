local entity = {}

entity.ClearGameEffects = function( ent )
    local components = EntityGetComponent(ent, "GameEffectComponent")
    if components ~= nil then
        for i,component in ipairs(components) do
            -- check if the effect is not -1 frames
            local frames = ComponentGetValue2(component, "frames")
            if frames > 0 then
                -- if it is not, set it to 1
                ComponentSetValue2(component, "frames", 1)
            end
        end
    end
    -- do the same for lifetime components
    local components = EntityGetComponent(ent, "LifetimeComponent")
    if components ~= nil then
        for i,component in ipairs(components) do
            -- check if the effect is not -1 frames
            local frames = ComponentGetValue2(component, "lifetime")
            if frames > 0 then
                -- if it is not, set it to 1
                ComponentSetValue2(component, "lifetime", 1)
            end
        end
    end

    -- also loop through children and do the same
    local children = EntityGetAllChildren(ent)
    if children ~= nil then
        for i,child in ipairs(children) do
            entity.ClearGameEffects(child)
        end
    end
end

entity.GivePerk = function( entity_who_picked, perk_id, amount )
    -- fetch perk info ---------------------------------------------------

    local pos_x, pos_y

    pos_x, pos_y = EntityGetTransform( entity_who_picked )

    local perk_data = get_perk_with_id( perk_list, perk_id )
    if perk_data == nil then
        return
    end

    local no_remove = perk_data.do_not_remove or false

    -- add a game effect or two
    if perk_data.game_effect ~= nil then
        local game_effect_comp,game_effect_entity = GetGameEffectLoadTo( entity_who_picked, perk_data.game_effect, true )
        if game_effect_comp ~= nil then
            ComponentSetValue( game_effect_comp, "frames", "-1" )
            
            if ( no_remove == false ) then
                ComponentAddTag( game_effect_comp, "perk_component" )
                EntityAddTag( game_effect_entity, "perk_entity" )
            end
        end
    end

    if perk_data.game_effect2 ~= nil then
        local game_effect_comp,game_effect_entity = GetGameEffectLoadTo( entity_who_picked, perk_data.game_effect2, true )
        if game_effect_comp ~= nil then
            ComponentSetValue( game_effect_comp, "frames", "-1" )
            
            if ( no_remove == false ) then
                ComponentAddTag( game_effect_comp, "perk_component" )
                EntityAddTag( game_effect_entity, "perk_entity" )
            end
        end
    end

    -- particle effect only applied once
    if perk_data.particle_effect ~= nil and ( amount <= 1 ) then
        local particle_id = EntityLoad( "data/entities/particles/perks/" .. perk_data.particle_effect .. ".xml" )
        
        if ( no_remove == false ) then
            EntityAddTag( particle_id, "perk_entity" )
        end
        
        EntityAddChild( entity_who_picked, particle_id )
    end

    local fake_perk_ent = EntityCreateNew()
    EntitySetTransform( fake_perk_ent, pos_x, pos_y )

    if perk_data.func_client ~= nil then
        perk_data.func_client( fake_perk_ent, entity_who_picked, perk_id, amount )
    elseif perk_data.func ~= nil then
        perk_data.func( fake_perk_ent, entity_who_picked, perk_id, amount )
    end

    EntityKill( fake_perk_ent )

    --GamePrint( "Picked up perk: " .. perk_data.name )
end

return entity