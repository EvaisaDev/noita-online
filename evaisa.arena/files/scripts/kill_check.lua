function damage_about_to_be_received( damage, x, y, entity_thats_responsible, critical_hit_chance )
    local entity_id = GetUpdatedEntityID()
    
    -- check if would kill

    local damageModelComponent = EntityGetFirstComponentIncludingDisabled( entity_id, "DamageModelComponent" )
    if damageModelComponent ~= nil then
        local health = ComponentGetValue2( damageModelComponent, "hp" )
        if health - damage <= 0 then
            GameAddFlagRun("player_died")
            ModSettingSet("killer", EntityGetName(entity_thats_responsible))
            return 0, 0
        end
    end


    return damage, 0
end