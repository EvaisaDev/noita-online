dofile_once("data/scripts/director_helpers.lua")
dofile_once("data/scripts/director_helpers_design.lua")
dofile_once("data/scripts/biome_scripts.lua")

--[[
local data = dofile_once("mods/evaisa.climb/courses/data.lua")

for k, v in ipairs(data.spawn_functions)do
	
	_G[v.id] = function(x, y)
		v.func(x, y)
	end
	RegisterSpawnFunction( v.color, v.id )
end
]]