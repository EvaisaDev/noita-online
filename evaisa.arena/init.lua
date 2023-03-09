

if(ModIsEnabled("evaisa.mp"))then
    ModMaterialsFileAdd("mods/evaisa.arena/files/materials.xml")
    ModMagicNumbersFileAdd("mods/evaisa.arena/files/magic.xml")

    ModLuaFileAppend("mods/evaisa.mp/data/gamemodes.lua", "mods/evaisa.arena/files/scripts/gamemode.lua")
    ModLuaFileAppend("data/scripts/gun/gun_actions.lua", "mods/evaisa.arena/files/scripts/gun_actions.lua")
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