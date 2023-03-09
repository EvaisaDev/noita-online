
local content = ModTextFileGetContent("data/genome_relations.csv")

function split_string(inputstr, sep)
    sep = sep or "%s"
    local t= {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
      table.insert(t, str)
    end
    return t
end
  

function add_new_genome(content, genome_name, default_relation_ab, default_relation_ba, self_relation, relations)
    local lines = split_string(content, "\r\n")
    local output = ""
    local genome_order = {}
    for i, line in ipairs(lines) do
      if i == 1 then
        output = output .. line .. "," .. genome_name .. "\r\n"
      else
        local herd = line:match("([%w_-]+),")
        output = output .. line .. ","..(relations[herd] or default_relation_ba).."\r\n"
        table.insert(genome_order, herd)
      end
    end
    
    local line = genome_name
    for i, v in ipairs(genome_order) do
      line = line .. "," .. (relations[v] or default_relation_ab)
    end
    output = output .. line .. "," .. self_relation
  
    return output
end


content = add_new_genome(content, "pvp", 0, 0, 0, {})
content = add_new_genome(content, "pvp_client", 0, 0, 0, {})


ModTextFileSetContent("data/genome_relations.csv", content)

if(ModIsEnabled("evaisa.mp"))then
    ModMaterialsFileAdd("mods/evaisa.arena/files/materials.xml")
    ModMagicNumbersFileAdd("mods/evaisa.arena/files/magic.xml")

    ModLuaFileAppend("mods/evaisa.mp/data/gamemodes.lua", "mods/evaisa.arena/files/scripts/gamemode.lua")
    --ModLuaFileAppend("data/scripts/gun/gun_actions.lua", "mods/evaisa.arena/files/scripts/gun_actions.lua")
    ModLuaFileAppend("data/scripts/gun/procedural/gun_procedural.lua", "mods/evaisa.arena/files/scripts/gun_procedural.lua")
end

function split_string(inputstr, sep)
    sep = sep or "%s"
    local t= {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
      table.insert(t, str)
    end
    return t
  end


local function CleanAndLockPlayer()
    local player = EntityGetWithTag("player_unit") or {}
    if(player == nil or #player == 0)then
        return
    end
    for k, v in pairs(player)do
        GameDestroyInventoryItems( v )
        -- disable controls component
        local controls = EntityGetFirstComponentIncludingDisabled(v, "ControlsComponent")
        if(controls ~= nil)then
            ComponentSetValue2(controls, "enabled", false)
        end
        local characterDataComponent = EntityGetFirstComponentIncludingDisabled(v, "CharacterDataComponent")
        if(characterDataComponent ~= nil)then
            EntitySetComponentIsEnabled(v, characterDataComponent, false)
        end
        local platformShooterPlayerComponent = EntityGetFirstComponentIncludingDisabled(v, "PlatformShooterPlayerComponent")
        if(platformShooterPlayerComponent ~= nil)then
            EntitySetComponentIsEnabled(v, platformShooterPlayerComponent, false)
        end
    end
end

function OnPlayerSpawned(player)
    GameRemoveFlagRun("ready_check")
    CleanAndLockPlayer()
    --EntityKill(player)
end