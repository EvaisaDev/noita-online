last_area_size = last_area_size or 0

local this = GetUpdatedEntityID()

local x, y = EntityGetTransform(this)

local area_size = tonumber(GlobalsGetValue("arena_area_size", "1000"))
local area_size_cap = tonumber(GlobalsGetValue("arena_area_size_cap", "1000"))

if(area_size ~= last_area_size)then
    --GamePrint("Area size updated.")

    local circle_emitter = EntityGetFirstComponent(this, "ParticleEmitterComponent", "area_indicator_circle")
    local outer_emitter = EntityGetFirstComponent(this, "ParticleEmitterComponent", "area_indicator_outer")

    if(circle_emitter ~= nil)then
        ComponentSetValue2(circle_emitter, "area_circle_radius", area_size, area_size + 15)
        ComponentSetValue2(circle_emitter, "count_min", math.floor(area_size * 0.5))
        ComponentSetValue2(circle_emitter, "count_max", math.floor(area_size * 0.5))
    end

    if(outer_emitter ~= nil)then
        ComponentSetValue2(outer_emitter, "area_circle_radius", area_size, area_size_cap * 2)
        ComponentSetValue2(outer_emitter, "count_min", area_size)
        ComponentSetValue2(outer_emitter, "count_max", area_size_cap)
    end
    

    last_area_size = area_size
end