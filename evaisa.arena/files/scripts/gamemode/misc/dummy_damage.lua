function damage_about_to_be_received( damage, x, y, entity_thats_responsible, critical_hit_chance )
    local entity_id = GetUpdatedEntityID()


    if(GameHasFlagRun("smash_mode"))then
        local knockback = tonumber(GlobalsGetValue("smash_knockback_dummy", "1"))
        GlobalsSetValue("smash_knockback_dummy", tostring(knockback * 1.5))
        if(entity_thats_responsible ~= GameGetWorldStateEntity())then
            return 0.0001, 0
        end
    end

    local damage_cap_percentage = tonumber(GlobalsGetValue("damage_cap", "0.25") or 0.25) 

    local damageModelComponent = EntityGetFirstComponentIncludingDisabled( entity_id, "DamageModelComponent" )
    local shooterDamageModelComp = EntityGetFirstComponentIncludingDisabled( entity_thats_responsible, "DamageModelComponent" )
    if damageModelComponent ~= nil and shooterDamageModelComp ~= nil then
        local shooter_max_hp = ComponentGetValue2( shooterDamageModelComp, "max_hp" )

        ComponentSetValue2( damageModelComponent, "max_hp", shooter_max_hp )
        
        local max_hp = ComponentGetValue2( damageModelComponent, "max_hp" )
        local damage_cap = max_hp * damage_cap_percentage
        if damage > damage_cap then
            --GamePrint("Damage cap exceeded: " .. math.floor(damage * 25) .. " > " .. math.floor(damage_cap * 25)  .. " (" .. (damage_cap_percentage * 100) .. "% of max HP)")
            damage = damage_cap
        end
    end

    return damage, critical_hit_chance
end

function damage_received( damage, message, entity_thats_responsible, is_fatal, projectile_thats_responsible )
    local entity_id = GetUpdatedEntityID()
    
    local damage_details = GetDamageDetails()
    --[[
        {
            ragdoll_fx = 1 
            damage_types = 16 -- bitflag
            knockback_force = 0    
            impulse = {0, 0},
            world_pos = {216.21, 12.583},
        }
    ]]

    if(GameHasFlagRun("smash_mode") and entity_thats_responsible ~= GameGetWorldStateEntity())then
        local impulse_x = damage_details.impulse[1]
        local impulse_y = damage_details.impulse[2]
        if(not(impulse_x == 0 and impulse_y == 0))then
            local velocity_comp = EntityGetFirstComponentIncludingDisabled(entity_id, "VelocityComponent")

            local smash_knockback = tonumber(GlobalsGetValue("smash_knockback_dummy", "1"))

            print("SMASH KNOCKBACK: " .. tostring(smash_knockback))
            print("IMPULSE: " .. tostring(impulse_x) .. ", " .. tostring(impulse_y))

            ComponentSetValue2(velocity_comp, "mVelocity", impulse_x * smash_knockback, impulse_y * smash_knockback)

        end
    end
end