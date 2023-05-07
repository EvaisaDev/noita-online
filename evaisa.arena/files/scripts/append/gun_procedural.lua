dofile("mods/evaisa.arena/files/scripts/misc/random_action.lua")

local rng = dofile_once("mods/evaisa.arena/lib/rng.lua")

local a, b, c, d, e, f = GameGetDateAndTimeLocal()

local random_seed = tonumber(GlobalsGetValue("unique_seed", tostring(GameGetFrameNum() + GameGetRealWorldTimeSinceStarted())))



local random = rng.new(random_seed)

GetRandomActionWithType = function( x, y, level, type, i)
	--print("Custom get action called!")
	return RandomActionWithType( level, type )
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

generate_gun = function( cost, level, force_unshuffle )
	local entity_id = GetUpdatedEntityID()
	local x, y = EntityGetTransform( entity_id )

	random_seed = math.abs(math.floor(tonumber(GlobalsGetValue("unique_seed", tostring(GameGetFrameNum() + GameGetRealWorldTimeSinceStarted()))) * x * y / 3))
	--print("Gun random seed: "..tostring(random_seed))

	random = rng.new(random_seed)

	local gun = get_gun_data( cost, level, force_unshuffle )
	make_wand_from_gun_data( gun, entity_id, level )
	wand_add_random_cards( gun, entity_id, level )
	
end

