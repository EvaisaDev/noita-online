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
	return RandomActionWithType( level, type, x * 324, y * 436 ) or "LIGHT_BULLET"
end

local get_new_seed = function(x, y)
	local rounds = tonumber(GlobalsGetValue("holyMountainCount", "0")) or 0
    local seed = tonumber(GlobalsGetValue("unique_seed", tostring(GameGetFrameNum() + GameGetRealWorldTimeSinceStarted())))
    if(GameHasFlagRun("shop_sync"))then
        seed = ((tonumber(GlobalsGetValue("world_seed", "0")) or 1) * 214) * rounds
    end
	if(x and y)then
		seed = seed + (x * 324) + (y * 436)
	end
    return seed
end

Random = function(a, b)
	--print("Custom random called!")
	if(a == nil and b == nil)then
		return random.next_float()
	elseif(b == nil)then
		return random.next_int(a)
	else
		return random.range(a, b)
	end
end

SetRandomSeed = function(x, y)
	--if(GameHasFlagRun("shop_sync"))then
		local seed = get_new_seed(x, y)
		if(seed ~= random_seed)then
			random = rng.new(seed)
			random_seed = seed
		end
	--end
end

