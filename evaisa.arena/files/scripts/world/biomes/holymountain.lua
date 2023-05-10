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
RegisterSpawnFunction( 0xffd14158, "spawn_target_dummy")

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
    if(not GameHasFlagRun("skip_health"))then
		EntityLoad( "data/entities/items/pickup/heart_fullhp_temple.xml", x-16, y )
	else
		GameRemoveFlagRun("skip_health")
	end
	EntityLoad( "data/entities/buildings/music_trigger_temple.xml", x-16, y )
	EntityLoad( "data/entities/items/pickup/spell_refresh.xml", x+16, y )
	EntityLoad( "data/entities/buildings/coop_respawn.xml", x, y )
	local chunk_loader = EntityLoad("mods/evaisa.arena/files/entities/chunk_loader.xml", 0, 0)
	EntitySetTransform(chunk_loader, 1500, 0)
	--[[EntityApplyTransform(chunk_loader, 300, 0)
	EntitySetTransform(chunk_loader, 300, 0)
	EntityApplyTransform(chunk_loader, 600, 0)
	EntitySetTransform(chunk_loader, 600, 0)]]
end

function spawn_all_shopitems( x, y )

	local rng = dofile_once("mods/evaisa.arena/lib/rng.lua")

	a, b, c, d, e, f = GameGetDateAndTimeLocal()
	
	local random_seed = GlobalsGetValue("unique_seed", "0")
	
	print("random_seed = "..tostring(random_seed))
	
	local random = rng.new(random_seed)

	--[[local spawn_shop, spawn_perks = temple_random( x, y )
	if( spawn_shop == "0" ) then
		return
	end]]

	local round = tonumber(GlobalsGetValue("holyMountainCount", "0"))

	local round = math.min(math.ceil(round / 2), 5)

	EntityLoad( "data/entities/buildings/shop_hitbox.xml", x, y )
	
	print("Generated shop items for mountain #"..tostring(round))

	a, b, c, d, e, f = GameGetDateAndTimeLocal()
	SetRandomSeed( x + GameGetFrameNum() + GameGetRealWorldTimeSinceStarted() + a + b + c + d + e + f, y  + GameGetFrameNum() + GameGetRealWorldTimeSinceStarted() + a + b + c + d + e + f)

	local count = tonumber( GlobalsGetValue( "TEMPLE_SHOP_ITEM_COUNT", "5" ) )
	local width = 132
	local item_width = width / count
	local sale_item_i = random.range( 1, count, true )

	print("Sale item: "..tostring(sale_item_i))

	-- Get the shop type from the settings
	local shop_type = GlobalsGetValue("shop_type", "mixed")
	-- Get the wand chance from the settings
	local shop_wand_chance = tonumber(GlobalsGetValue("shop_wand_chance", "20"))
	-- "Alternating" shop type switches between spells and wands every round.
	if (shop_type == "alternating") then
		-- Alternate which shop is presented
		if (round % 2 == 0) then
			for i=1,count do
				if( i == sale_item_i ) then
					generate_shop_item( x + (i-1)*item_width, y, true, round, false )
				else
					generate_shop_item( x + (i-1)*item_width, y, false, round, false )
				end
				
				generate_shop_item( x + (i-1)*item_width, y - 30, false, round, false )
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
	-- "Mixed" shop type mixed spells and wands.
	elseif (shop_type == "mixed") then
		local wand_count = math.floor(((count / 100) * shop_wand_chance) + 0.5)
		for i=1, wand_count do
			if (i == sale_item_i) then
				generate_shop_wand(x + (i-1)*item_width, y, true, round)
			else
				generate_shop_wand(x + (i-1)*item_width, y, false, round)
			end
		end
		for i=wand_count+1, count do
			LoadPixelScene("data/biome_impl/temple/shop_second_row.png", "data/biome_impl/temple/shop_second_row_visual.png", x + (i-1)*item_width - 8, y-22, "", true)
			if (i == sale_item_i) then
				generate_shop_item( x + (i-1)*item_width, y, true, round, false )
				generate_shop_item( x + (i-1)*item_width, y - 30, false, round, false )
			else
				generate_shop_item( x + (i-1)*item_width, y, false, round, false )
				generate_shop_item( x + (i-1)*item_width, y - 30, false, round, false )
			end
		end
	-- "Spell Only" shop type is self explanatory.
	elseif (shop_type == "spell_only") then
		for i=1,count do
			if( i == sale_item_i ) then
				generate_shop_item( x + (i-1)*item_width, y, true, round, false )
			else
				generate_shop_item( x + (i-1)*item_width, y, false, round, false )
			end
			
			generate_shop_item( x + (i-1)*item_width, y - 30, false, round, false )
			LoadPixelScene( "data/biome_impl/temple/shop_second_row.png", "data/biome_impl/temple/shop_second_row_visual.png", x + (i-1)*item_width - 8, y-22, "", true )
		end
	-- "Wand Only" shop type is.. uh..
	elseif (shop_type == "wand_only") then
		for i=1,count do
			if( i == sale_item_i ) then
				generate_shop_wand( x + (i-1)*item_width, y, true, round )
			else
				generate_shop_wand( x + (i-1)*item_width, y, false, round )
			end
		end
	-- "Choose" shop type is something i guess the player chooses what type of shop they want but idk how eba wants to implement this.
	elseif (shop_type == "choose") then
		print("just kidding, its not implemented yet, ha ha ha!")
	-- "Random" shop type is basically vanilla and we default to this if no other shop type is match is found.
	else
		local shop_random_ratio = tonumber(GlobalsGetValue("shop_random_ratio", "50"))
		if( random.range( 0, 100 ) >= shop_random_ratio ) then
			for i=1,count do
				if( i == sale_item_i ) then
					generate_shop_item( x + (i-1)*item_width, y, true, round, false )
				else
					generate_shop_item( x + (i-1)*item_width, y, false, round, false )
				end
				
				generate_shop_item( x + (i-1)*item_width, y - 30, false, round, false )
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
end

function spawn_all_perks( x, y )
	if(GameHasFlagRun("first_death") and not GameHasFlagRun("skip_perks"))then
		a, b, c, d, e, f = GameGetDateAndTimeLocal()
		SetRandomSeed( x + GameGetFrameNum() + GameGetRealWorldTimeSinceStarted() + a + b + c + d + e + f, y  + GameGetFrameNum() + GameGetRealWorldTimeSinceStarted() + a + b + c + d + e + f)
	
		perk_spawn_many( x, y )
	else
		GameRemoveFlagRun("skip_perks")
	end
end

function spawn_perk_reroll( x, y )
	if(GameHasFlagRun("first_death"))then
		EntityLoad( "data/entities/items/pickup/perk_reroll.xml", x, y )
	end
end

function spawn_target_dummy( x, y )
	EntityLoad( "mods/evaisa.arena/files/entities/dummy_target/dummy_target.xml", x, y )
end

-- GameHasFlagRun("first_death")