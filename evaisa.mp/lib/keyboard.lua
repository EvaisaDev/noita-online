if _hacky_keyboard_defined then
	return
end

_hacky_keyboard_defined = true

if not require then
	mp_log:print("No require? Urgh.")
	return
end

local ffi = require('ffi')
if not ffi then
	mp_log:print("No FFI? Well that's a pain.")
	return
end

_keyboard_present = true

ffi.cdef([[
	const uint8_t* SDL_GetKeyboardState(int* numkeys);
	uint32_t SDL_GetKeyFromScancode(uint32_t scancode);
	char* SDL_GetScancodeName(uint32_t scancode);
	char* SDL_GetKeyName(uint32_t key);
]])
_SDL = ffi.load('SDL2.dll')

local code_to_a = {}
local shifts = {}

for i = 0, 284 do
	local keycode = _SDL.SDL_GetKeyFromScancode(i)
	if keycode > 0 then
	local keyname = ffi.string(_SDL.SDL_GetKeyName(keycode))
	if keyname and #keyname > 0 then
		code_to_a[i] = keyname:lower()
		if keyname:lower():find("shift") then
			table.insert(shifts, i)
		end
	end
	end
end

local prev_state = {}
for i = 0, 284 do
	prev_state[i] = 0
end

function hack_update_keys()
    local keys = _SDL.SDL_GetKeyboardState(nil)
    local pressed = {}
    local held = {}
    local released = {}
    -- start at scancode 1 because we don't care about "UNKNOWN"
    for scancode = 1, 284 do 
        if keys[scancode] > 0 then
            if prev_state[scancode] <= 0 then
                pressed[#pressed+1] = code_to_a[scancode]
            end
            held[#held+1] = code_to_a[scancode]
        elseif prev_state[scancode] > 0 then
            released[#released+1] = code_to_a[scancode]
        end
        prev_state[scancode] = keys[scancode]
    end

    local shift_held = false
    for _, shiftcode in ipairs(shifts) do
        if keys[shiftcode] > 0 then
            shift_held = true
            break
        end
    end

    return pressed, held, released, shift_held
end
