dofile_once( "mods/evaisa.arena/files/helper.lua" );
dofile_once( "mods/evaisa.arena/files/lib/helper.lua" );
dofile_once( "mods/evaisa.arena/files/lib/variables.lua" );
current = current or 0;
current_true = current_true or 0;
first_hit_frame = first_hit_frame or 0;
last_hit_frame = last_hit_frame or 0;
last_damage = last_damage or 0;
total_damage = total_damage or 0;
current_total_damage = current_total_damage or 0;
reset_frame = reset_frame or 0;
first_hit_time = first_hit_time or 0;
function damage_received( damage, message, entity_thats_responsible, is_fatal )
    local now = GameGetFrameNum();
    local now_true = GameGetRealWorldTimeSinceStarted();
    local entity = GetUpdatedEntityID();
    local damage_per_frames = EntityGetVariableNumber( entity, "damage_per_frames", 60 );

    local damage_models = EntityGetComponent( entity, "DamageModelComponent" ) or {};
    for _,damage_model in pairs(damage_models) do
        local max_hp = ComponentGetValue2( damage_model, "max_hp" );
        ComponentSetValue2( damage_model, "max_hp", 4 );
        ComponentSetValue2( damage_model, "hp", math.max( 4, damage * 1.1 ) );
    end
    --local x,y = EntityGetTransform( entity );
    --local did_hit, hit_x, hit_y = RaytracePlatforms( x, y - 1, x, y );
    --if did_hit then
    --    EntityApplyTransform( entity, x, y - 5 );
    --end
    if entity_thats_responsible == 0 or damage < 0 then return; end

    local highest_damage = tonumber( GlobalsGetValue("evaisa.arena_highest_damage_dealt","0") );
    if damage * 25 > highest_damage then
        GlobalsSetValue("evaisa.arena_highest_damage_dealt", tostring( damage * 25 ) );
    end
    GlobalsSetValue( "evaisa.arena_latest_damage", tostring( damage * 25 ) );
    local tracked_damage = EntityGetVariableNumber( entity, "evaisa.arena_tracked_damage", 0 );
    EntitySetVariableNumber( entity, "evaisa.arena_tracked_damage", tracked_damage + damage * 25 );
    
    -- reset tracker after 10 frames of dps
    if now - last_hit_frame > 180 then
        total_damage = 0;
    end
    if now >= reset_frame or (now - first_hit_frame) > math.max( damage_per_frames, 180 ) then
        current_total_damage = 0;
        current_true = 0;
        current = 0;
        first_hit_frame = now;
        first_hit_time = now_true;
        EntitySetVariableNumber( entity, "first_hit_frame", first_hit_frame );
        EntitySetVariableNumber( entity, "evaisa.arena_dps_tracker_highest", 0 );
    end
    last_hit_frame = now;
    last_damage = damage;
    total_damage = total_damage + damage;
    current_total_damage = current_total_damage + damage;
    reset_frame = now + 60;
    current = current_total_damage / math.ceil( math.max( now - first_hit_frame, 1 ) / damage_per_frames );
    current_true = current_total_damage / math.max( now_true - first_hit_time, 1 );
    local highest_current = EntityGetVariableNumber( entity, "evaisa.arena_dps_tracker_highest", 0 );
    local damage_text = thousands_separator(string.format( "%.2f", current * 25 ));
    local damage_text_true = thousands_separator(string.format( "%.2f", current_true * 25 ));
    EntitySetVariableString( entity, "evaisa.arena_dps_tracker_text", damage_text );
    EntitySetVariableString( entity, "evaisa.arena_dps_tracker_text_true", damage_text_true );
    GlobalsSetValue( "evaisa.arena_recent_total_damage", thousands_separator( string.format( "%.2f", total_damage * 25 ) ) );
    if current > highest_current then
        EntitySetVariableNumber( entity, "evaisa.arena_dps_tracker_highest", current );
        EntitySetVariableString( entity, "evaisa.arena_dps_tracker_text_highest", thousands_separator( string.format( "%.2f", current * 25 ) ) );
        GlobalsSetValue( "evaisa.arena_recent_highest_dps", thousands_separator( string.format( "%.2f", current * 25 ) ) );
    end
    local highest_dps = tonumber( GlobalsGetValue( "evaisa.arena_highest_dps", "0" ) );
    if current * 25 > highest_dps then
        GlobalsSetValue( "evaisa.arena_highest_dps", tostring( current * 25 ) );
    end
end