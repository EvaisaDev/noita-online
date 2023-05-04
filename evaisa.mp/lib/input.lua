local minhook = dofile("mods/evaisa.mp/lib/minhook.lua")()
minhook.initialize()

local SDL = dofile("mods/evaisa.mp/lib/sdl2_ffi.lua")
local ffi = require("ffi")


SDL.SDL_StartTextInput()


local input = {
    pressed = {},
    inputs = {},
    released = {},
    held = {},
    chars = {}
}

input.Reset = function(self)
    self.pressed = {}
    self.inputs = {}
    self.released = {}
    self.held = {}
    self.chars = {}
end

local SDL_PollEvent_hook
SDL_PollEvent_hook = minhook.create_hook(SDL.SDL_PollEvent, function(event)

    local ret = SDL_PollEvent_hook.original(event)
    if ret == 0 then
        return 0
    end

    if event.type == SDL.SDL_TEXTINPUT then
        local char = ffi.string(event.text.text)
        print(char)
        table.insert(input.chars, char)
    elseif event.type == SDL.SDL_KEYDOWN then
        local key_name = ffi.string(SDL.SDL_GetKeyName(event.key.keysym.sym))

        print(key_name)

        input.inputs[key_name] = GameGetFrameNum()
        if not input.held[key_name] then
            input.pressed[key_name] = GameGetFrameNum()
        end
        input.held[key_name] = GameGetFrameNum()
    elseif event.type == SDL.SDL_KEYUP then
        local key_name = ffi.string(SDL.SDL_GetKeyName(event.key.keysym.sym))
        if(input.held[key_name] and input.held[key_name] ~= GameGetFrameNum())then
            input.released[key_name] = true
            input.held[key_name] = nil
        end
    end

    return ret

end)

minhook.enable(SDL.SDL_PollEvent)

input.WasKeyPressed = function(self, key)
    if(key == nil)then
        return false
    end
    return self.pressed[key] ~= nil
end

input.IsKeyDown = function(self, key)
    if(key == nil)then
        return false
    end
    return self.held[key] ~= nil
end

input.WasKeyReleased = function(self, key)
    if(key == nil)then
        return false
    end
    return self.released[key] ~= nil
end

input.GetInput = function(self, key)
    if(key == nil)then
        return false
    end
    return self.inputs[key]
end

input.GetChars = function(self)
    return self.chars
end

return input