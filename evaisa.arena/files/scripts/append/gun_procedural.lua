dofile("mods/evaisa.arena/files/scripts/misc/random_action.lua")

local rng = dofile_once("mods/evaisa.arena/lib/rng.lua")

local a, b, c, d, e, f = GameGetDateAndTimeLocal()

local random_seed = tonumber(GlobalsGetValue("unique_seed", tostring(GameGetFrameNum() + GameGetRealWorldTimeSinceStarted())))

local rounds = tonumber(GlobalsGetValue("holyMountainCount", "0")) or 0
if(GameHasFlagRun("shop_sync"))then
	random_seed = ((tonumber(GlobalsGetValue("world_seed", "0")) or 1) * 214) * rounds
end


local random = rng.new(random_seed)

GetRandomActionWithType = function( x, y, level, type, i)
	--print("Custom get action called!")
	return RandomActionWithType( level, type ) or "LIGHT_BULLET"
end

local get_new_seed = function()
	local rounds = tonumber(GlobalsGetValue("holyMountainCount", "0")) or 0
    local seed = tonumber(GlobalsGetValue("unique_seed", tostring(GameGetFrameNum() + GameGetRealWorldTimeSinceStarted())))
    if(GameHasFlagRun("shop_sync"))then
        seed = ((tonumber(GlobalsGetValue("world_seed", "0")) or 1) * 214) * rounds
    end
    return seed
end

Random = function(a, b)
	if(GameHasFlagRun("shop_sync"))then
		local seed = get_new_seed()
		if(seed ~= random_seed)then
			random = rng.new(seed)
			random_seed = seed
		end
	end
	--print("Custom random called!")
	if(a == nil and b == nil)then
		return random.next_float()
	elseif(b == nil)then
		return random.next_int(a)
	else
		return random.range(a, b)
	end
end

generate_gun = function( cost, level, force_unshuffle )
	local entity_id = GetUpdatedEntityID()
	local x, y = EntityGetTransform( entity_id )

	if(GameHasFlagRun("shop_sync"))then
		local seed = get_new_seed() + x + y
		if(seed ~= random_seed)then
			random = rng.new(seed)
			random_seed = seed
		end
	end

	local gun = get_gun_data( cost, level, force_unshuffle )
	make_wand_from_gun_data( gun, entity_id, level )
	wand_add_random_cards( gun, entity_id, level )
	
end

