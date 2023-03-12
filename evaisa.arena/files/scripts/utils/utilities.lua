function get_spawn_pos(min_range, max_range, x, y)
    
    local spawn_points = {}
    
    local count = 0
    
    for i = 1, 1000 do
    
        local angle = Random()*math.pi*2;
      
        local dx = x + (math.cos(angle)*Random(min_range, max_range));
        local dy = y + (math.sin(angle)*Random(min_range, max_range));		
        
        local rhit, rx, ry = RaytracePlatforms(dx - 2, dy - 2, dx + 2, dy + 2)
        
        
        
        if(rhit) then 
            --DEBUG_MARK( dx, dy, "bad_spawn_point",0, 0, 1 )
        else

            table.insert(spawn_points, {
                x = dx,
                y = dy,
            })
        end
    end

    if(#spawn_points == 0)then
        return x, y
    end
    local spawn_index = Random(1, #spawn_points)


    
    local spawn_x = spawn_points[spawn_index].x
    local spawn_y = spawn_points[spawn_index].y
    
    if(spawn_x == nil)then
        local dx = x;
        local dy = y;		
        
        return dx, dy
    else

        return spawn_x, spawn_y
    end

end

function ClearGameEffects(entity)
    local components = EntityGetComponent(entity, "GameEffectComponent")
    if components ~= nil then
        for i,component in ipairs(components) do
            -- check if the effect is not -1 frames
            local frames = ComponentGetValue2(component, "frames")
            if frames > 0 then
                -- if it is not, set it to 0
                ComponentSetValue2(component, "frames", 1)
            end
        end
    end
    -- also loop through children and do the same
    local children = EntityGetAllChildren(entity)
    if children ~= nil then
        for i,child in ipairs(children) do
            ClearGameEffects(child)
        end
    end
end