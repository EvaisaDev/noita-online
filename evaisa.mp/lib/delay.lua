local delay = {}
local delay_queue = {}

delay.reset = function()
    delay_queue = {}
end

delay.update = function()
    for i = #delay_queue, 1, -1 do
        local v = delay_queue[i]

        if(type(v.frames) == "number")then
            v.frames = v.frames - 1
        end

        if(v.tick_callback)then
            v.tick_callback(v.frames)
        end

        --[[print("type: "..type(v.frames))

        if(type(v.frames) == "function")then
            print("waw: "..v.frames())
        end]]

        if((type(v.frames) == "number" and v.frames <= 0) or (type(v.frames) == "function" and v.frames()))then
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