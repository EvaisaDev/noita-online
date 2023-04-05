function damage_about_to_be_received( damage, x, y, entity_thats_responsible, critical_hit_chance )
    local entity_id = GetUpdatedEntityID()
    
    -- check if would kill

    --local damageModelComponent = EntityGetFirstComponentIncludingDisabled( entity_id, "DamageModelComponent" )
    --if damageModelComponent ~= nil then
        --local health = ComponentGetValue2( damageModelComponent, "hp" )
        if(GameHasFlagRun("Immortal"))then
            return 0, 0
        --else
        --    GameAddFlagRun("took_damage")
        end
        --[[if health - damage <= 1 then
            GameAddFlagRun("player_died")
            if(entity_thats_responsible ~= nil)then
                ModSettingSet("killer", EntityGetName(entity_thats_responsible))
            end
            return 0, 0
        end]]
    --end

    local damage_cap_percentage = tonumber(GlobalsGetValue("damage_cap", "0.25") or 0.25)

    local damageModelComponent = EntityGetFirstComponentIncludingDisabled( entity_id, "DamageModelComponent" )
    if damageModelComponent ~= nil then
        local max_hp = ComponentGetValue2( damageModelComponent, "max_hp" )
        local damage_cap = max_hp * damage_cap_percentage
        if damage > damage_cap then
            damage = damage_cap
        end
    end

    return damage, critical_hit_chance
end

function damage_received( damage, message, entity_thats_responsible, is_fatal, projectile_thats_responsible )
    local entity_id = GetUpdatedEntityID()
    
    -- check if would kill
    GameAddFlagRun("took_damage")

    local damageModelComponent = EntityGetFirstComponentIncludingDisabled( entity_id, "DamageModelComponent" )
    if damageModelComponent ~= nil then
        if(is_fatal)then
            GameAddFlagRun("player_died")
            if(entity_thats_responsible ~= nil)then
                ModSettingSet("killer", EntityGetName(entity_thats_responsible))
            end
            GameAddFlagRun("player_unloaded")
            -- set health so that player ends on 1
            
            local respawn_count = tonumber( GlobalsGetValue( "RESPAWN_COUNT", "0" ) )
            if(respawn_count > 0)then
                respawn_count = respawn_count - 1
                GlobalsSetValue( "RESPAWN_COUNT", tostring(respawn_count) )
                ComponentSetValue2( damageModelComponent, "hp", damage + 4 )
            else
                if(GameHasFlagRun( "saving_grace" ))then
                    local hp = ComponentGetValue2( damageModelComponent, "hp" )
                    if(hp * 25 > 1)then
                        ComponentSetValue2( damageModelComponent, "hp", damage + 0.04 )
                    end
                end
            end
        end
    end
end