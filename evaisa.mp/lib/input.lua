last_pressed_keys = last_pressed_keys or {}

local input = {}

-- was key pressed this frame
input.WasKeyPressed = function(key)
    local pressed_keys = keys_down

    local out = false
    
    if pressed_keys[key] and last_pressed_keys[key] == nil then
        out = true
    end

    for k, v in pairs(pressed_keys) do
        if(last_pressed_keys[k] == nil)then
            last_pressed_keys[k] = GameGetFrameNum()
        end
    end
    
    for k, v in pairs(last_pressed_keys) do
        if(pressed_keys[k] == nil)then
            last_pressed_keys[k] = nil
        end
    end

    return out
end

-- is key held down
input.IsKeyHeld = function(key)
    local pressed_keys = keys_down

    return pressed_keys[key]
end

-- was key released this frame
input.WasKeyReleased = function(key)
    local pressed_keys = keys_down

    local out = false

    if not pressed_keys[key] and last_pressed_keys[key] then
        out = true
    end

    for k, v in pairs(pressed_keys) do
        if(last_pressed_keys[k] == nil)then
            last_pressed_keys[k] = GameGetFrameNum()
        end
    end
    
    for k, v in pairs(last_pressed_keys) do
        if(pressed_keys[k] == nil)then
            last_pressed_keys[k] = nil
        end
    end

    return out
end

return input