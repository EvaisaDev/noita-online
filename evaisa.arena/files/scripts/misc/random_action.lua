dofile_once("data/scripts/lib/utilities.lua")
dofile_once( "data/scripts/gun/gun_enums.lua")
dofile("data/scripts/gun/gun_actions.lua")
local rng = dofile_once("mods/evaisa.arena/lib/rng.lua")

local a, b, c, d, e, f = GameGetDateAndTimeLocal()

local rounds = tonumber(GlobalsGetValue("holyMountainCount", "0")) or 0
local random_seed = (GameGetFrameNum() + GameGetRealWorldTimeSinceStarted() + a + b + c + d + e + f) / 2
if(GameHasFlagRun("shop_sync"))then
    random_seed = ((tonumber(GlobalsGetValue("world_seed", "0")) or 1) * 214) * rounds
end

local random = rng.new(random_seed)


local generate_spell_list = function()
    local spell_list = {}

    for _, v in ipairs(actions) do
    
        if GameHasFlagRun("spell_blacklist_"..v.id) then
            goto continue
        end
    
    
        local spawn_levels = {}
        for spawn_level in string.gmatch(v.spawn_level or "", "([^,]+)") do
            table.insert(spawn_levels, tonumber(spawn_level))
        end
    
        local spawn_probabilities = {}
        for spawn_probability in string.gmatch(v.spawn_probability or "", "([^,]+)") do
            table.insert(spawn_probabilities, tonumber(spawn_probability))
        end
    
        for k, level in ipairs(spawn_levels) do
            local key = "level_" .. tostring(level)
            spell_list[key] = spell_list[key] or {}
    
            table.insert(spell_list[key], {
                id = v.id,
                probability = spawn_probabilities[k],
                type = v.type
            })
        end
    
        ::continue::
    end

    return spell_list
end


local get_new_seed = function(x, y)
    local rounds = tonumber(GlobalsGetValue("holyMountainCount", "0")) or 0
    local a, b, c, d, e, f = GameGetDateAndTimeLocal()
    local seed = (GameGetFrameNum() + GameGetRealWorldTimeSinceStarted() + a + b + c + d + e + f) / 2
    if(GameHasFlagRun("shop_sync"))then
        seed = ((tonumber(GlobalsGetValue("world_seed", "0")) or 1) * 214) * rounds
    end
	if(x and y)then
		seed = seed + (x * 324) + (y * 436)
	end
    return seed
end


function RandomAction(max_level, x, y)
    --if(GameHasFlagRun("shop_sync"))then
        local seed = get_new_seed(x, y)
        if(seed ~= random_seed)then
            random = rng.new(seed)
            random_seed = seed
            --print("new seed: "..tostring(seed))
        end
    --end

    local spell_list = generate_spell_list()

    local available_actions = {}

    for level = 0, max_level do
        local key = "level_" .. tostring(level)

        for _, action in ipairs(spell_list[key] or {}) do
            table.insert(available_actions, action)
        end 
    end

    local total_probability = 0
    for _, action in ipairs(available_actions) do
        total_probability = total_probability + action.probability
    end

    local random_value = random.next_float() * total_probability

    for _, action in ipairs(available_actions) do
        random_value = random_value - action.probability
        if random_value <= 0 then
            return action.id
        end
    end

    return "LIGHT_BULLET"
end

-- GetRandomActionWithType function to find a random action with the specified action_type and max_level
function RandomActionWithType(max_level, action_type, x, y)
    --if(GameHasFlagRun("shop_sync"))then
    local seed = get_new_seed(x, y)
    if(seed ~= random_seed)then
        random = rng.new(seed)
        random_seed = seed
    end
    --end

    local spell_list = generate_spell_list()

    local available_actions = {}

    for level = 0, max_level do
        local key = "level_" .. tostring(level)

        --print("checking level: "..tostring(level))

        for _, action in ipairs(spell_list[key] or {}) do
            if(action.type == action_type)then
                --print("found valid spell: "..tostring(action.id))
                table.insert(available_actions, action)
            end
        end 
    end

    local total_probability = 0
    for _, action in ipairs(available_actions) do
        total_probability = total_probability + action.probability
    end

    local random_value = random.next_float() * total_probability

    for _, action in ipairs(available_actions) do
        random_value = random_value - action.probability
        if random_value <= 0 then
            return action.id
        end
    end

    return "LIGHT_BULLET"
end