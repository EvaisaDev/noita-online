local helpers = dofile("mods/evaisa.mp/files/scripts/helpers.lua")
local json = dofile("mods/evaisa.arena/lib/json.lua")

function damage_about_to_be_received( damage, x, y, entity_thats_responsible, critical_hit_chance )
    local entity_id = GetUpdatedEntityID()

    --local damageModelComponent = EntityGetFirstComponentIncludingDisabled( entity_id, "DamageModelComponent" )
    --if damageModelComponent ~= nil then
        --local health = ComponentGetValue2( damageModelComponent, "hp" )
        if(GameHasFlagRun("Immortal"))then
            return 1, 0
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
    print(json.stringify(damage_details))
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