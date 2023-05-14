local delay = {}
local delay_queue = {}

delay.reset = function()
    delay_queue = {}
end

delay.update = function()
    for i, v in ipairs(delay_queue) do
        v.frames = v.frames - 1
        if(v.tick_callback)then
            v.tick_callback(v.frames)
        end
        if(v.frames <= 0)then
            if(v.finish_callback)then
                v.finish_callback()
            end
            table.remove(delay_queue, i)
        end
    end
end

delay.new = function(frames, finish_callback, tick_callback)
    local self = {
        frames = frames,
        tick_callback = tick_callback,
        finish_callback = finish_callback
    }
    table.insert(delay_queue, self)
    return self
end

return delay