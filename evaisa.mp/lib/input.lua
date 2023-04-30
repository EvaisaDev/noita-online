last_pressed_keys = last_pressed_keys or {}

local input = {}

input.getPressedKeys = function ()
    local keys = {}

    local pressed, shift_held = hack_update_keys()

    for _, key in ipairs(pressed) do
        keys[key] = true
    end

    return keys
end

-- was key pressed this frame
input.WasKeyPressed = function(key)
    local pressed_keys = input.getPressedKeys()

    local out = false

    if pressed_keys[key] and not last_pressed_keys[key] then
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
    local pressed_keys = input.getPressedKeys()

    return pressed_keys[key]
end

-- was key released this frame
input.WasKeyReleased = function(key)
    local pressed_keys = input.getPressedKeys()

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