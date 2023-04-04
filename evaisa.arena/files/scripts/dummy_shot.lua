local entity = GetUpdatedEntityID();
function damage_about_to_be_received( damage, x, y, entity_thats_responsible, critical_hit_chance )
    local highest_crit = tonumber( GlobalsGetValue("spell_lab_highest_crit_chance","0") );
    if critical_hit_chance > highest_crit then
        GlobalsSetValue("spell_lab_highest_crit_chance", tostring( critical_hit_chance ) );
    end
    
    return damage, critical_hit_chance;
end