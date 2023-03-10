dofile_once("data/scripts/director_helpers.lua")
dofile_once("data/scripts/director_helpers_design.lua")
dofile_once("data/scripts/biome_scripts.lua")

RegisterSpawnFunction( 0xffff54e3, "spawn_point" )
--RegisterSpawnFunction( 0xff0051ff, "spawn_kill_zone" )

function spawn_point( x, y )
	EntityLoad( "mods/evaisa.arena/files/entities/spawn_point.xml", x, y )
end

--[[
function spawn_kill_zone( x, y )
	EntityLoad( "mods/evaisa.arena/files/entities/kill_zone.xml", x, y )
end
]]