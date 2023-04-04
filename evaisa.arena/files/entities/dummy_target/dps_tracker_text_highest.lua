dofile_once( "mods/evaisa.arena/files/helper.lua" );
dofile_once( "mods/evaisa.arena/files/lib/variables.lua" );
last_text = last_text or "";
local entity = GetUpdatedEntityID();
local current_target = EntityGetParent( entity );
local current_text = EntityGetVariableString( current_target, "evaisa.arena_dps_tracker_text_highest", "" );
if current_target ~= 0 and last_text ~= current_text then
    last_text = current_text;
    local height = 20;
    local sprite = EntityGetFirstComponent( entity, "SpriteComponent", "evaisa.arena_dps_tracker_highest" );
    if sprite then
        ComponentSetValue2( sprite, "offset_x", #current_text * 2 - 2 );
        ComponentSetValue2( sprite, "offset_y", height * 2 - 12 );
        ComponentSetValue2( sprite, "text", current_text );
        EntityRefreshSprite( entity, sprite );
    end
end