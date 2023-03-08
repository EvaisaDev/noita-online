for k, v in ipairs(actions)do
    local old_action = v.action
    v.action = function( recursion_level, iteration )
        --c.extra_entities = c.extra_entities .. "mods/evaisa.arena/files/entities/identifier.xml,"
        c.friendly_fire = true
        SetRandomSeed(0, 0)
        old_action(recursion_level, iteration)
        c.friendly_fire = true
        --c.spread_degrees = 0
    end
end