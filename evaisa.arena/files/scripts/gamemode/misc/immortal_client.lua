function damage_about_to_be_received( damage, x, y, entity_thats_responsible, critical_hit_chance )
    local entity_id = GetUpdatedEntityID()
    
    -- check if would kill

    if(entity_thats_responsible == nil or entity_thats_responsible == 0 )then
        local damageModelComponent = EntityGetFirstComponentIncludingDisabled( entity_id, "DamageModelComponent" )
        if damageModelComponent ~= nil then
            local health = ComponentGetValue2( damageModelComponent, "hp" )
            if health then
                ComponentSetValue2( damageModelComponent, "hp", health + damage )
            end
        end
    elseif(entity_thats_responsible ~= GameGetWorldStateEntity())then
        return 0, 0
    end

    return damage, 0
end