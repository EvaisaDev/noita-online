function wand_fired( gun_entity_id )
    local fire_count = GlobalsGetValue( "wand_fire_count", "0" )
    fire_count = tonumber( fire_count )
    fire_count = fire_count + 1
    GlobalsSetValue( "wand_fire_count", tostring( fire_count ) )
    --GamePrint("fired")
end