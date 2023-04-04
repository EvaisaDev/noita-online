function damage_about_to_be_received( damage, x, y, entity_thats_responsible, critical_hit_chance )
    local entity_id = GetUpdatedEntityID()

    local damage_cap_percentage = tonumber(GlobalsGetValue("damage_cap", "0.25") or 0.25) 

    local damageModelComponent = EntityGetFirstComponentIncludingDisabled( entity_id, "DamageModelComponent" )
    local shooterDamageModelComp = EntityGetFirstComponentIncludingDisabled( entity_thats_responsible, "DamageModelComponent" )
    if damageModelComponent ~= nil and shooterDamageModelComp ~= nil then
        local shooter_max_hp = ComponentGetValue2( shooterDamageModelComp, "max_hp" )

        ComponentSetValue2( damageModelComponent, "max_hp", shooter_max_hp )
        
        local max_hp = ComponentGetValue2( damageModelComponent, "max_hp" )
        local damage_cap = max_hp * damage_cap_percentage
        if damage > damage_cap then
            GamePrint("Damage cap exceeded: " .. math.floor(damage * 25) .. " > " .. math.floor(damage_cap * 25)  .. " (" .. (damage_cap_percentage * 100) .. "% of max HP)")
            damage = damage_cap
        end
    end

    return damage, critical_hit_chance
end