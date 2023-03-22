CHEST_LEVEL = 3
dofile_once("data/scripts/director_helpers.lua")
dofile_once("data/scripts/biome_scripts.lua")
dofile( "mods/evaisa.arena/files/scripts/misc/generate_shop_item.lua" )
dofile_once("data/scripts/lib/utilities.lua")
dofile( "data/scripts/biomes/temple_shared.lua" )
dofile( "data/scripts/perks/perk.lua" )
dofile_once("data/scripts/biomes/temple_altar_top_shared.lua")

RegisterSpawnFunction( 0xff6d934c, "spawn_hp" )

RegisterSpawnFunction( 0xff03fade, "spawn_spell_visualizer" )
RegisterSpawnFunction( 0xff33934c, "spawn_all_shopitems" )
RegisterSpawnFunction( 0xff10822d, "spawn_workshop" )
RegisterSpawnFunction( 0xff5a822d, "spawn_workshop_extra" )
RegisterSpawnFunction( 0xffb66ccd, "spawn_ready_point" )
RegisterSpawnFunction( 0xff7345DF, "spawn_perk_reroll" )

function spawn_workshop( x, y )
	--EntityLoad( "data/entities/buildings/workshop.xml", x, y )
end

function spawn_ready_point( x, y )
	EntityLoad( "mods/evaisa.arena/files/entities/misc/ready.xml", x, y )
end

function spawn_workshop_extra( x, y )
	EntityLoad( "mods/evaisa.arena/files/entities/misc/workshop_allow_mods.xml", x, y )
end

function spawn_spell_visualizer( x, y )
	EntityLoad( "data/entities/buildings/workshop_spell_visualizer.xml", x, y )
	EntityLoad( "data/entities/buildings/workshop_aabb.xml", x, y )
end

function spawn_hp( x, y )
	GameAddFlagRun("in_hm")
	EntityLoad( "data/entities/items/pickup/heart_fullhp_temple.xml", x-16, y )
	EntityLoad( "data/entities/buildings/music_trigger_temple.xml", x-16, y )
	EntityLoad( "data/entities/items/pickup/spell_refresh.xml", x+16, y )
	EntityLoad( "data/entities/buildings/coop_respawn.xml", x, y )
end

function spawn_all_shopitems( x, y )
	local spawn_shop, spawn_perks = temple_random( x, y )
	if( spawn_shop == "0" ) then
		return
	end

	local round = tonumber(GlobalsGetValue("holyMountainCount", "0"))

	local round = math.min(math.ceil(round / 2), 7)

	EntityLoad( "data/entities/buildings/shop_hitbox.xml", x, y )
	
	print("Generated shop items for mountain #"..tostring(round))

	a, b, c, d, e, f = GameGetDateAndTimeLocal()
	SetRandomSeed( x + GameGetFrameNum() + GameGetRealWorldTimeSinceStarted() + a + b + c + d + e + f, y  + GameGetFrameNum() + GameGetRealWorldTimeSinceStarted() + a + b + c + d + e + f)

	local count = tonumber( GlobalsGetValue( "TEMPLE_SHOP_ITEM_COUNT", "5" ) )
	local width = 132
	local item_width = width / count
	local sale_item_i = Random( 1, count )

	if( Random( 0, 100 ) <= 50 ) then
		for i=1,count do
			if( i == sale_item_i ) then
				generate_shop_item( x + (i-1)*item_width, y, true, round, true )
			else
				generate_shop_item( x + (i-1)*item_width, y, false, round, true )
			end
			
			generate_shop_item( x + (i-1)*item_width, y - 30, false, round, true )
			LoadPixelScene( "data/biome_impl/temple/shop_second_row.png", "data/biome_impl/temple/shop_second_row_visual.png", x + (i-1)*item_width - 8, y-22, "", true )
		end
	else	
		for i=1,count do
			if( i == sale_item_i ) then
				generate_shop_wand( x + (i-1)*item_width, y, true, round )
			else
				generate_shop_wand( x + (i-1)*item_width, y, false, round )
			end
		end
	end
end

function spawn_all_perks( x, y )
	if(GameHasFlagRun("first_death"))then
		a, b, c, d, e, f = GameGetDateAndTimeLocal()
		SetRandomSeed( x + GameGetFrameNum() + GameGetRealWorldTimeSinceStarted() + a + b + c + d + e + f, y  + GameGetFrameNum() + GameGetRealWorldTimeSinceStarted() + a + b + c + d + e + f)
	
		perk_spawn_many( x, y )
	end
end

function spawn_perk_reroll( x, y )
	if(GameHasFlagRun("first_death"))then
		EntityLoad( "data/entities/items/pickup/perk_reroll.xml", x, y )
	end
end

-- GameHasFlagRun("first_death")