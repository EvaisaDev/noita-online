for k, v in ipairs(actions)do
    local old_action = v.action
    v.action = function( recursion_level, iteration )
        --c.extra_entities = c.extra_entities .. "mods/evaisa.arena/files/entities/identifier.xml,"
        if(not GameHasFlagRun("in_hm"))then
            c.friendly_fire = true
        end
        SetRandomSeed(0, 0)
        old_action(recursion_level, iteration)
        if(not GameHasFlagRun("in_hm"))then
            c.friendly_fire = true
        end
        --c.spread_degrees = 0
    end
end