local genomes = dofile("mods/evaisa.arena/files/scripts/utilities/genomes.lua")

genomes:start()
genomes:add("pvp", 0, 0, 0, {})
genomes:add("pvp_client", 0, 0, 0, {})
genomes:finish()

ModMaterialsFileAdd("mods/evaisa.arena/files/materials.xml")
ModMagicNumbersFileAdd("mods/evaisa.arena/files/magic.xml")
ModLuaFileAppend("data/scripts/gun/procedural/gun_procedural.lua", "mods/evaisa.arena/files/scripts/append/gun_procedural.lua")

if(ModIsEnabled("evaisa.mp"))then
    ModLuaFileAppend("mods/evaisa.mp/data/gamemodes.lua", "mods/evaisa.arena/files/scripts/gamemode/main.lua")
end

function OnPlayerSpawned(player)

end