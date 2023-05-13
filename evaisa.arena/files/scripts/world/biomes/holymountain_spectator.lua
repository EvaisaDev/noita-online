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
	EntityLoad( "data/entities/buildings/music_trigger_temple.xml", x-16, y )
	EntityLoad( "data/entities/buildings/coop_respawn.xml", x, y )
	local chunk_loader = EntityLoad("mods/evaisa.arena/files/entities/chunk_loader.xml", 0, 0)
	EntitySetTransform(chunk_loader, 1500, 0)
	--[[EntityApplyTransform(chunk_loader, 300, 0)
	EntitySetTransform(chunk_loader, 300, 0)
	EntityApplyTransform(chunk_loader, 600, 0)
	EntitySetTransform(chunk_loader, 600, 0)]]
end

function spawn_all_shopitems( x, y )

end

function spawn_all_perks( x, y )

end

function spawn_perk_reroll( x, y )
end

function spawn_target_dummy( x, y )
	EntityLoad( "mods/evaisa.arena/files/entities/dummy_target/dummy_target.xml", x, y )
end

-- GameHasFlagRun("first_death")