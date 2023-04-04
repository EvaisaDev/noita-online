function get_entity_held_or_random_wand( entity, or_random )
    if or_random == nil then or_random = true; end
    local base_wand = nil;
    local wands = {};
    local children = EntityGetAllChildren( entity ) or {};
    for key,child in pairs( children ) do
        if EntityGetName( child ) == "inventory_quick" then
            wands = EntityGetChildrenWithTag( child, "wand" );
            break;
        end
    end
    if #wands > 0 then
        local inventory2 = EntityGetFirstComponent( entity, "Inventory2Component" );
        local active_item = ComponentGetValue2( inventory2, "mActiveItem" );
        for _,wand in pairs( wands ) do
            if wand == active_item then
                base_wand = wand;
                break;
            end
        end
        if base_wand == nil and or_random then
            SetRandomSeed( EntityGetTransform( entity ) );
            base_wand =  Random( 1, #wands );
        end
    end
    return base_wand;
end

function thousands_separator(amount)
    local formatted = amount;
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
            if (k==0) then
            break
        end
    end
    return formatted;
end

function decimal_format( amount, decimals )
    if decimals == nil then decimals = 0; end
    return thousands_separator( string.format( "%."..decimals.."f", amount ) );
end

function reduce_particles( entity, disable )
    local particle_emitters = EntityGetComponent( entity, "ParticleEmitterComponent" ) or {};
    local sprite_particle_emitters = EntityGetComponent( entity, "SpriteParticleEmitterComponent" ) or {};
    local projectile = EntityGetFirstComponent( entity, "ProjectileComponent" );
    if not disable then
        for _,emitter in pairs( particle_emitters ) do
            if ComponentGetValue2( emitter, "emit_cosmetic_particles" ) == true and ComponentGetValue2( emitter, "create_real_particles" ) == false and ComponentGetValue2( emitter, "emit_real_particles" ) == false then
                ComponentSetValue2( emitter, "count_min", 1 );
                ComponentSetValue2( emitter, "count_max", 1 );
                ComponentSetValue2( emitter, "collide_with_grid", false );
                ComponentSetValue2( emitter, "is_trail", false );
                local lifetime_min = tonumber( ComponentGetValue2( emitter, "lifetime_min" ) );
                ComponentSetValue2( emitter, "lifetime_min", math.min( lifetime_min * 0.5, 0.1 ) );
                local lifetime_max = tonumber( ComponentGetValue2( emitter, "lifetime_max" ) );
                ComponentSetValue2( emitter, "lifetime_max", math.min( lifetime_max * 0.5, 0.5 ) );
            end
        end
        for _,emitter in pairs( sprite_particle_emitters ) do
            if ComponentGetValue2( emitter, "entity_file" ) == "" then
                ComponentSetValue2( emitter, "count_max", 1 );
                ComponentSetValue2( emitter, "emission_interval_min_frames", math.ceil( ComponentGetValue2( emitter, "emission_interval_min_frames" ) * 2 ) );
                ComponentSetValue2( emitter, "emission_interval_max_frames", math.ceil( ComponentGetValue2( emitter, "emission_interval_max_frames" ) * 2 ) );
            end
        end
        if projectile ~= nil then
            ComponentObjectAdjustValues( projectile, "config_explosion", {
                sparks_count_min=function( value ) return math.min( value, 1 ); end,
                sparks_count_max=function( value ) return math.min( value, 2 ); end,
            });
        end
    else
        for _,emitter in pairs( particle_emitters ) do
            if ComponentGetValue2( emitter, "emit_cosmetic_particles" ) == true and ComponentGetValue2( emitter, "create_real_particles" ) == false and ComponentGetValue2( emitter, "emit_real_particles" ) == false then
                EntitySetComponentIsEnabled( entity, emitter, false );
            end
        end
        for _,emitter in pairs( sprite_particle_emitters ) do
            EntitySetComponentIsEnabled( entity, emitter, false );
        end
        if projectile ~= nil then
            ComponentObjectSetValues( projectile, "config_explosion", {
                sparks_count_min=0,
                sparks_count_max=0,
            });
        end
    end
    for _,child in pairs( EntityGetAllChildren( entity ) or {} ) do
        reduce_particles( child, disable );
    end
end

function string_split( s, splitter )
    local words = {};
    for word in string.gmatch( s, '([^'..splitter..']+)') do
        table.insert( words, word );
    end
    return words;
end

function nexp( value, exponent ) return ( ( math.abs( value ^ 2 ) ) ^ exponent ) / value; end