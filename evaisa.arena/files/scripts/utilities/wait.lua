local wait = {}
local wait_queue = {}

wait.reset = function()
    wait_queue = {}
end

wait.update_item = function(i, v)
    if(v.condition())then
        if(v.success_callback)then
            v.success_callback()
        end
        table.remove(wait_queue, i)
    else
        if(v.tick_callback)then
            v.tick_callback()
        end
    end
end

wait.update = function()
    for i = #wait_queue, 1, -1 do
        local v = wait_queue[i]
        wait.update_item(i, v)
    end
end

wait.new = function(condition, success_callback, tick_callback)
    local self = {
        condition = condition,
        tick_callback = tick_callback,
        success_callback = success_callback
    }
    table.insert(wait_queue, self)

    wait.update_item(#wait_queue, self)

    return self
end

return wait