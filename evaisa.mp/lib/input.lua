local minhook = dofile("mods/evaisa.mp/lib/minhook.lua")("mods/evaisa.mp/bin")
minhook.initialize()

local SDL = dofile("mods/evaisa.mp/lib/sdl2_ffi.lua")
local ffi = require("ffi")


SDL.SDL_StartTextInput()


local input = {
    pressed = {},
    inputs = {},
    released = {},
    held = {},
    chars = {},
    mouse = {
        x = 0,
        y = 0,
        held = {},
        pressed = {},
        released = {}
    },
    frame_finished = false
}

input.Reset = function(self)
    self.pressed = {}
    self.inputs = {}
    self.released = {}
    self.chars = {}
    self.mouse.pressed = {}
    self.mouse.released = {}
end


local mouse_map = {
    "left",
    "middle",
    "right",
    "x1",
    "x2"
}


local SDL_PollEvent_hook
SDL_PollEvent_hook = minhook.create_hook(SDL.SDL_PollEvent, function(event)
    local success, result = pcall(function()
        if(input.frame_finished)then
            input:Reset()
            input.frame_finished = false
        end

        local ret = SDL_PollEvent_hook.original(event)
        if ret == 0 then
            input.frame_finished = true
            return 0
        end

        if event.type == SDL.SDL_TEXTINPUT then
            local char = ffi.string(event.text.text)
            --print(char)
            table.insert(input.chars, char)
        elseif event.type == SDL.SDL_KEYDOWN then
            local key_name = ffi.string(SDL.SDL_GetKeyName(event.key.keysym.sym)):lower()

            --print(key_name)

            input.inputs[key_name] = GameGetFrameNum()
            if not input.held[key_name] then
                input.pressed[key_name] = GameGetFrameNum()
                --print(key_name)
            end
            input.held[key_name] = GameGetFrameNum()
        elseif event.type == SDL.SDL_KEYUP then
            local key_name = ffi.string(SDL.SDL_GetKeyName(event.key.keysym.sym)):lower()
            if(input.held[key_name] and input.held[key_name] ~= GameGetFrameNum())then
                input.released[key_name] = true
                input.held[key_name] = nil
            end
        elseif event.type == SDL.SDL_MOUSEMOTION then
            input.mouse.x = event.motion.x
            input.mouse.y = event.motion.y
        elseif event.type == SDL.SDL_MOUSEBUTTONDOWN then
            local map_button = mouse_map[event.button.button]
            input.mouse.held[map_button] = true
            input.mouse.pressed[map_button] = true
        elseif event.type == SDL.SDL_MOUSEBUTTONUP then
            local map_button = mouse_map[event.button.button]
            input.mouse.held[map_button] = nil
            input.mouse.released[map_button] = true
        end

        return ret
    end)

    if success then
        return result
    end

    print("Input error: " .. result)
    return 0
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

input.WasMousePressed = function(self, button)
    if(button == nil)then
        return false
    end
    if(type(button) == "number")then
        button = mouse_map[button]
    end
    return self.mouse.pressed[button] ~= nil
end

input.IsMouseDown = function(self, button)
    if(button == nil)then
        return false
    end
    if(type(button) == "number")then
        button = mouse_map[button]
    end
    return self.mouse.held[button] ~= nil
end

input.WasMouseReleased = function(self, button)
    if(button == nil)then
        return false
    end
    if(type(button) == "number")then
        button = mouse_map[button]
    end
    return self.mouse.released[button] ~= nil
end

input.GetMousePos = function(self)
    return self.mouse.x, self.mouse.y
end

input.GetUIMousePos = function(self, gui)
    local input_manager = EntityGetWithName("mp_input_manager")
    if(input_manager == nil or not EntityGetIsAlive(input_manager))then
        input_manager = EntityLoad("mods/evaisa.mp/files/entities/input_manager.xml")
    end

    local controls_component = EntityGetFirstComponentIncludingDisabled(input_manager, "ControlsComponent")
    local screen_width, screen_height = GuiGetScreenDimensions(gui)
    local mouse_raw_x, mouse_raw_y = ComponentGetValue2(controls_component, "mMousePositionRaw")
    local mx, my = mouse_raw_x * screen_width / 1280, mouse_raw_y * screen_height / 720

    return mx, my
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
