generate_gun = function( cost, level, force_unshuffle )
	local entity_id = GetUpdatedEntityID()
	local x, y = EntityGetTransform( entity_id )
	a, b, c, d, e, f = GameGetDateAndTimeLocal()
	SetRandomSeed( x + GameGetFrameNum() + GameGetRealWorldTimeSinceStarted() + a + b + c + d + e + f, y  + GameGetFrameNum() + GameGetRealWorldTimeSinceStarted() + a + b + c + d + e + f)


	local gun = get_gun_data( cost, level, force_unshuffle )
	make_wand_from_gun_data( gun, entity_id, level )
	wand_add_random_cards( gun, entity_id, level )
	
end

