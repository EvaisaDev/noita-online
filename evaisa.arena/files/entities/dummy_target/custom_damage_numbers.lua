dofile_once( "mods/evaisa.arena/files/helper.lua" );
dofile_once( "mods/evaisa.arena/files/lib/helper.lua" );
dofile_once( "mods/evaisa.arena/files/lib/variables.lua" );
local last_damage_frame = {};
function damage_received( damage, message, entity_thats_responsible, is_fatal )
    local entity = GetUpdatedEntityID();
    if EntityHasNamedVariable( entity, "evaisa.arena_always_show_damage_numbers" ) or is_fatal == false then
        local now = GameGetFrameNum();
        if now - ( last_damage_frame[entity] or 0 ) > 180 then
            EntitySetVariableNumber( entity, "evaisa.arena_total_damage", 0 );
        end
        last_damage_frame[entity] = now;
        local total_damage = EntityGetVariableNumber( entity, "evaisa.arena_total_damage", 0 ) + damage;
        EntitySetVariableNumber( entity, "evaisa.arena_total_damage", total_damage );
        local damage_text = thousands_separator( string.format( "%.2f", total_damage * 25 ) );
        EntitySetVariableString( entity, "evaisa.arena_custom_damage_numbers_text", damage_text );
    else
        local sprites = EntityGetComponentIncludingDisabled(entity,"SpriteComponent") or {};
        for k,v in pairs( sprites ) do
            if ComponentGetValue2( v, "is_text_sprite" ) then
                EntityRemoveComponent( entity, v );
            end
        end
    end
end