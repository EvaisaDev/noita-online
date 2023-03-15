function damage_about_to_be_received( damage, x, y, entity_thats_responsible, critical_hit_chance )
    local entity_id = GetUpdatedEntityID()
    
    -- check if would kill

    local damageModelComponent = EntityGetFirstComponentIncludingDisabled( entity_id, "DamageModelComponent" )
    if damageModelComponent ~= nil then
        local health = ComponentGetValue2( damageModelComponent, "hp" )
        if(GameHasFlagRun("Immortal"))then
            return 0, 0
        else
            GameAddFlagRun("took_damage")
        end
        if health - damage <= 0 then
            GameAddFlagRun("player_died")
            if(entity_thats_responsible ~= nil)then
                ModSettingSet("killer", EntityGetName(entity_thats_responsible))
            end
            return 0, 0
        end
    end


    return damage, 0
end