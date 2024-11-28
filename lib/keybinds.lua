local inputs = dofile_once("mods/evaisa.mp/lib/list_inputs.lua")

local smallfolk = dofile_once("mods/evaisa.mp/lib/smallfolk.lua")

local bindings = {
    _bindings = {},
    _binding_order = {},
    RegisterBinding = function(self, id, category, name, default, default_type, allow_mouse, allow_keyboard, allow_gamepad, allow_axis, allow_axis_button)
        if(allow_mouse == nil)then
            allow_mouse = true
        end
        if(allow_keyboard == nil)then
            allow_keyboard = true
        end
        if(allow_gamepad == nil)then
            allow_gamepad = true
        end
        if self._bindings[id] == nil then
            self._bindings[id] = {
                category = category,
                name = name,
                default = default,
                default_type = default_type,
                value = ModSettingGet("keybind."..category .. "." .. id) or default,
                being_set = false,
                allow_mouse = allow_mouse,
                allow_keyboard = allow_keyboard,
                allow_gamepad = allow_gamepad,
                allow_axis = allow_axis,
                allow_axis_button = allow_axis_button,
                type = ModSettingGet("keybind."..category .. "." .. id .. ".type") or default_type,
                was_down = false,
            }
            print("registering binding: " .. id)
            table.insert(self._binding_order, id)
        end

        GlobalsSetValue("evaisa.mp.keybinds", smallfolk.dumps(self._bindings))
        GlobalsSetValue("evaisa.mp.keybinds_order", smallfolk.dumps(self._binding_order))
    end,
    Load = function(self)
        local data = GlobalsGetValue("evaisa.mp.keybinds", "{}")
        print(data)
        local data = smallfolk.loads(data)

        self._bindings = data

        local order_s = GlobalsGetValue("evaisa.mp.keybinds_order", "{}")
        local order = smallfolk.loads(order_s)
        self._binding_order = order

        GameRemoveFlagRun("evaisa.mp.binding_being_set")
    end,
    IsJustDown = function(self, id)
        if(GameHasFlagRun("evaisa.mp.reload_bindings"))then
            GameRemoveFlagRun("evaisa.mp.reload_bindings")
            print("reloading binds!")
            self:Load()
        end
        local handlers = {
            mouse = function(name)
                return InputIsMouseButtonJustDown(inputs.mouse[name])
            end,
            key = function(name)
                return InputIsKeyJustDown(inputs.key[name])
            end,
            joy = function(name)
                return InputIsJoystickButtonJustDown(0, inputs.joy[name])
            end,
        }

        local binding = self._bindings[id]
        if binding ~= nil then
            local type = binding.type
            if type ~= nil and handlers[type] ~= nil then
                return handlers[type](binding.value)
            end
        end
    end,
    IsJustUp = function(self, id)
        if(GameHasFlagRun("evaisa.mp.reload_bindings"))then
            GameRemoveFlagRun("evaisa.mp.reload_bindings")
            self:Load()
        end
        local binding = self._bindings[id]
        if binding ~= nil then
            local handlers = {
                mouse = function(name)
                    return InputIsMouseButtonJustUp(inputs.mouse[name])
                end,
                key = function(name)
                    return InputIsKeyJustUp(inputs.key[name])
                end,
                joy = function(name)
                    return InputIsJoystickButtonJustDown(0, inputs.joy[name]) and not binding.was_down
                end,
            }


            local type = binding.type
            if type ~= nil and handlers[type] ~= nil then
                return handlers[type](binding.value)
            end
        end
    end,
    IsDown = function(self, id)
        if(GameHasFlagRun("evaisa.mp.reload_bindings"))then
            GameRemoveFlagRun("evaisa.mp.reload_bindings")
            self:Load()
        end
        local binding = self._bindings[id]
        if binding ~= nil then
            local handlers = {
                mouse = function(name)
                    return InputIsMouseButtonDown(inputs.mouse[name])
                end,
                key = function(name)
                    return InputIsKeyDown(inputs.key[name])
                end,
                joy = function(name)
                    return InputIsJoystickButtonDown(0, inputs.joy[name])
                end,
            }

            local type = binding.type
            if type ~= nil and handlers[type] ~= nil then
                return handlers[type](binding.value)
            end
        end
    end,
    GetAxis = function(self, id)
        if(GameHasFlagRun("evaisa.mp.reload_bindings"))then
            GameRemoveFlagRun("evaisa.mp.reload_bindings")
            self:Load()
        end
        local binding = self._bindings[id]
        if binding ~= nil then
            local handlers = {
                axis = function(name)
                    local x, y = InputGetJoystickAnalogStick(0, inputs.stick[name])
                    return x, y
                end,
                axis_button = function(name)
                    return InputGetJoystickAnalogButton(0, inputs.trigger[name])
                end,
            }

            local type = binding.type
            if type ~= nil and handlers[type] ~= nil then
                local a, b = handlers[type](binding.value)
                return a, b
            end
        end 

        return 0, 0
    end,
    Get = function(self, id)
        local binding = self._bindings[id]
        if binding ~= nil then
            return binding.value
        end
        return nil
    end,
    TrySet = function(self, id)
        local binding = self._bindings[id]
        if binding ~= nil and not GameHasFlagRun("evaisa.mp.binding_being_set") then
            GameAddFlagRun("evaisa.mp.binding_being_set")
            binding.being_set = true
        end
    end,
    Update = function(self)

        for bind_id, v in pairs(self._bindings)do
            local binding = v
            if binding ~= nil then
                
                if(v.type == "joy")then
                    if(InputIsJoystickButtonDown(0, inputs.joy[binding.value]))then
                        binding.was_down = true
                    else
                        if(binding.was_down)then
                            binding.was_down = false
                        end
                    end
                end

                if binding.being_set then

                    print("binding still being set!!")
               
                    local set = false
                    -- if backspace is pressed, unbind
                    if(InputIsKeyJustDown(inputs.key.Key_BACKSPACE))then
                        binding.value = ""
                        binding.being_set = false
                        GameRemoveFlagRun("evaisa.mp.binding_being_set")
                        ModSettingSet("keybind."..binding.category .. "." .. bind_id, "")
                        ModSettingSet("keybind."..binding.category .. "." .. bind_id .. ".type", "key")
                        GameAddFlagRun("evaisa.mp.reload_bindings")
                    end
     
                    if(binding.allow_mouse)then
                        if(not set)then
                            for name, id in pairs(inputs.mouse)do
                                if(InputIsMouseButtonJustDown(id))then
                                    binding.value = name
                                    binding.being_set = false
                                    GameRemoveFlagRun("evaisa.mp.binding_being_set")
                                    ModSettingSet("keybind."..binding.category .. "." .. bind_id, name)
                                    binding.type = "mouse"
                                    ModSettingSet("keybind."..binding.category .. "." .. bind_id .. ".type", "mouse")
                                    set = true
                                    break
                                end
                            end
                        end
                    end
                    if(binding.allow_keyboard)then
                        if not set then
                            for name, id in pairs(inputs.key)do
                                if(InputIsKeyJustDown(id))then
                                    binding.value = name
                                    binding.being_set = false
                                    GameRemoveFlagRun("evaisa.mp.binding_being_set")
                                    ModSettingSet("keybind."..binding.category .. "." .. bind_id, name)
                                    binding.type = "key"
                                    ModSettingSet("keybind."..binding.category .. "." .. bind_id .. ".type", "key")
                                    set = true
                                    break
                                end
                            end
                        end
                    end
                    if(binding.allow_gamepad)then
                        if not set then
                            for name, id in pairs(inputs.joy)do
                                if(InputIsJoystickButtonJustDown(0, id))then
                                    binding.value = name
                                    binding.being_set = false
                                    GameRemoveFlagRun("evaisa.mp.binding_being_set")
                                    ModSettingSet("keybind."..binding.category .. "." .. bind_id, name)
                                    binding.type = "joy"    
                                    ModSettingSet("keybind."..binding.category .. "." .. bind_id .. ".type", "joy")
                                    set = true
                                    break
                                end
                            end
                        end
                    end
                    if(binding.allow_axis)then
                        if not set then
                            for name, id in pairs(inputs.stick)do
                                if(InputGetJoystickAnalogStick(0, id) > 0.9 or InputGetJoystickAnalogStick(0, id) < -0.9)then
                                    binding.value = name
                                    binding.being_set = false
                                    GameRemoveFlagRun("evaisa.mp.binding_being_set")
                                    ModSettingSet("keybind."..binding.category .. "." .. bind_id, name)
                                    binding.type = "axis"
                                    ModSettingSet("keybind."..binding.category .. "." .. bind_id .. ".type", "axis")
                                    set = true
                                    break
                                end
                            end
                        end
                    end
                    if(binding.allow_axis_button)then
                        if(not set)then
                            for name, id in pairs(inputs.trigger)do
                                if(InputGetJoystickAnalogButton(0, id) > 0.9)then
                                    binding.value = name
                                    binding.being_set = false
                                    GameRemoveFlagRun("evaisa.mp.binding_being_set")
                                    ModSettingSet("keybind."..binding.category .. "." .. bind_id, name)
                                    binding.type = "axis_button"
                                    ModSettingSet("keybind."..binding.category .. "." .. bind_id .. ".type", "axis_button")
                                    set = true
                                    break
                                end
                            end
                        end
                    end

                    if(set)then
                        GlobalsSetValue("evaisa.mp.keybinds", smallfolk.dumps(self._bindings))
                        GameAddFlagRun("evaisa.mp.reload_bindings")
                    end
                end
            end
        end
    end,
}



return bindings