local helpers = dofile("mods/evaisa.mp/files/scripts/helpers.lua")
local json = dofile("mods/evaisa.arena/lib/json.lua")

function damage_about_to_be_received( damage, x, y, entity_thats_responsible, critical_hit_chance )
    local entity_id = GetUpdatedEntityID()

    if(GameHasFlagRun("Immortal"))then
        return 0, 0
    end

    if(GameHasFlagRun("smash_mode"))then
        --[[local damage_details = GetDamageDetails()

        local impulse_x = damage_details.impulse[1]
        local impulse_y = damage_details.impulse[2]
        ]]

        --if(not(impulse_x == 0 and impulse_y == 0))then
        local knockback = tonumber(GlobalsGetValue("smash_knockback", "1"))
        GlobalsSetValue("smash_knockback", tostring(math.min(knockback * 1.25, 100000)))
        if(entity_thats_responsible ~= GameGetWorldStateEntity())then
            return 0.0001, 0
        end
        --end
    end


    local damage_cap_percentage = tonumber(GlobalsGetValue("damage_cap", "0.25") or 0.25)

    local damageModelComponent = EntityGetFirstComponentIncludingDisabled( entity_id, "DamageModelComponent" )
    if damageModelComponent ~= nil and entity_thats_responsible ~= GameGetWorldStateEntity() then
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
    local x, y = EntityGetTransform(entity_id)
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

    --print(tostring(entity_thats_responsible))

    if(GameHasFlagRun("smash_mode") and entity_thats_responsible ~= GameGetWorldStateEntity() and entity_thats_responsible ~= nil)then

        local impulse_x = damage_details.impulse[1]
        local impulse_y = damage_details.impulse[2]

        if(projectile_thats_responsible)then
            -- calculate projectile velocity
            local velocity_comp = EntityGetFirstComponentIncludingDisabled(projectile_thats_responsible, "VelocityComponent")
            if(velocity_comp ~= nil)then
                local vel_x, vel_y = ComponentGetValue2(velocity_comp, "mVelocity")
                -- normalize
                local len = math.sqrt(vel_x * vel_x + vel_y * vel_y)
                impulse_x = vel_x / len
                impulse_y = vel_y / len
            end
        else
            -- get aim angle of responsible entity
            local controls_comp = EntityGetFirstComponentIncludingDisabled(entity_thats_responsible, "ControlsComponent")

            if(controls_comp)then
                local aim_x, aim_y = ComponentGetValue2(controls_comp, "mAimingVector")
                -- normalize
                local len = math.sqrt(aim_x * aim_x + aim_y * aim_y)
                impulse_x = aim_x / len
                impulse_y = aim_y / len
            else
                local ex, ey = EntityGetTransform(entity_thats_responsible)
                local dx = x - ex
                local dy = y - ey
                local len = math.sqrt(dx * dx + dy * dy)
                impulse_x = dx / len
                impulse_y = dy / len
            end
        
        end


        if(not(impulse_x == 0 and impulse_y == 0))then
            local character_data_comp = EntityGetFirstComponentIncludingDisabled(entity_id, "CharacterDataComponent")

            local smash_knockback = tonumber(GlobalsGetValue("smash_knockback", "1"))
            

            if(smash_knockback > 10000)then
                EntityLoad("mods/evaisa.arena/files/entities/misc/smash_explosion.xml", x, y)
                damage_details.smash_explosion = true
                damage_details.explosion_x = x
                damage_details.explosion_y = y
            end

            LoadGameEffectEntityTo( entity_id, "mods/evaisa.arena/files/entities/misc/smash_knockback.xml")

            --print("SMASH KNOCKBACK: " .. tostring(smash_knockback))
            --print("IMPULSE: " .. tostring(impulse_x) .. ", " .. tostring(impulse_y))

            ComponentSetValue2(character_data_comp, "mVelocity", impulse_x * smash_knockback, impulse_y * smash_knockback)

        end
    end


    --print(json.stringify(damage_details))
    -- check if would kill
    GameAddFlagRun("took_damage")
    GlobalsSetValue("last_damage_details", tostring(json.stringify(damage_details)))

    local damageModelComponent = EntityGetFirstComponentIncludingDisabled( entity_id, "DamageModelComponent" )
    if damageModelComponent ~= nil then
        if(is_fatal)then
            local died = false

            local respawn_count = tonumber( GlobalsGetValue( "RESPAWN_COUNT", "0" ) )
            if(respawn_count > 0)then
                respawn_count = respawn_count - 1
                GlobalsSetValue( "RESPAWN_COUNT", tostring(respawn_count) )
                print("$logdesc_gamefx_respawn")
                GamePrint("$logdesc_gamefx_respawn")

                GamePrintImportant("$log_gamefx_respawn", "$logdesc_gamefx_respawn")

                ComponentSetValue2( damageModelComponent, "hp", damage + 4 )
            else
                if(GameHasFlagRun( "saving_grace" ))then
                    local hp = ComponentGetValue2( damageModelComponent, "hp" )
                    if(math.floor(hp * 25) > 1)then
                        ComponentSetValue2( damageModelComponent, "hp", damage + 0.04 )
                        
                        print("$log_gamefx_savinggrace")
                        GamePrint("$log_gamefx_savinggrace")

                    else
                        died = true
                    end
                else
                    died = true
                end
            end

            if(died)then
                GameAddFlagRun("player_died")
                if(entity_thats_responsible ~= nil)then
                    ModSettingSet("killer", EntityGetName(entity_thats_responsible))
                end
                GameAddFlagRun("player_unloaded")
            end
        end
    end
end