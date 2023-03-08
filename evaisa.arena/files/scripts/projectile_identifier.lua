local entity = GetUpdatedEntityID()

-- get projectile component
local projectile = EntityGetFirstComponentIncludingDisabled(entity, "ProjectileComponent")
if projectile == nil then
    return
end

local velocityComponent = EntityGetFirstComponentIncludingDisabled(entity, "VelocityComponent")
if velocityComponent == nil then
    return
end

mWhoShot = ComponentGetValue2(projectile, "mWhoShot")
if mWhoShot == nil then
    return
end

local id = EntityGetName(mWhoShot)
local projectile_count = ModSettingGet("projectile_count_" .. id) or 0


if(EntityHasTag(mWhoShot, "player_unit")) then
    -- store position and velocity
    local x, y = EntityGetTransform(entity)
    local vx, vy = ComponentGetValueVector2(velocityComponent, "mVelocity")

    projectile_count = projectile_count + 1

    -- store projectile data
    ModSettingSet("projectile_" .. id .. tostring(projectile_count) .. "velocity_x", vx)
    ModSettingSet("projectile_" .. id .. tostring(projectile_count) .. "velocity_y", vy)
    ModSettingSet("projectile_" .. id .. tostring(projectile_count) .. "position_x", x)
    ModSettingSet("projectile_" .. id .. tostring(projectile_count) .. "position_y", y)

    ModSettingSet("projectile_count_" .. id, projectile_count)

    print("projectile_count_" .. id .. " = " .. projectile_count)

    GameAddFlagRun("player_fired_wand")
else
    -- get projectile data
    local vx = ModSettingGet("projectile_" .. id .. tostring(projectile_count) .. "velocity_x")
    local vy = ModSettingGet("projectile_" .. id .. tostring(projectile_count) .. "velocity_y")
    local x = ModSettingGet("projectile_" .. id .. tostring(projectile_count) .. "position_x")
    local y = ModSettingGet("projectile_" .. id .. tostring(projectile_count) .. "position_y")

    -- set projectile data
    ComponentSetValueVector2(velocityComponent, "mVelocity", vx, vy)
    EntitySetTransform(entity, x, y)

    projectile_count = projectile_count - 1
    ModSettingSet("projectile_count_" .. id, projectile_count)
end