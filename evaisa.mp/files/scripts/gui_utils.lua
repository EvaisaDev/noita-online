dofile_once("data/scripts/lib/utilities.lua")
--[[
local generated_id = 1000
function NewID(identifier, force)
	generated_id = generated_id + 1
	if(identifier ~= nil)then
		generated_id = generated_id + tostring(string.byte(identifier))
		if(force)then
			generated_id = 1000 + tonumber(tostring(string.byte(identifier)))
		end
	end
	return generated_id
end]]

local start_values = {}
local reserved_id_space = 3000
local next_start_value = reserved_id_space

local function get_start_value(identifier)
    if not start_values[identifier] then
        start_values[identifier] = next_start_value
        next_start_value = next_start_value + reserved_id_space
    end

    return start_values[identifier]
end

local id_pool = {}

function NewID(identifier, force)
    identifier = identifier or "default"
    
    if not id_pool[identifier] then
        id_pool[identifier] = start_values[identifier] or get_start_value(identifier)
    end
    
    id_pool[identifier] = id_pool[identifier] + 1
    
    if force then
        id_pool[identifier] = start_values[identifier] or get_start_value(identifier)
    end
    
    return id_pool[identifier]
end

function ResetIDs()
    id_count = 1
    id_pool = {}
end

local old_window_stack = {}
local window_stack = {}
local last_hovered_window = nil
function ResetWindowStack()
	--print("ResetWindowStack")
	for k, window in pairs(old_window_stack) do
		if(window_stack[k] == nil)then
			old_window_stack[k] = nil
		end
	end

	for k, window in pairs(window_stack) do
		old_window_stack[k] = window
	end

	window_stack = {}
end


function WorldToScreenPos(gui_input, x, y)
    local virt_x = MagicNumbersGetValue("VIRTUAL_RESOLUTION_X")
    local virt_y = MagicNumbersGetValue("VIRTUAL_RESOLUTION_Y")
    local screen_width, screen_height = GuiGetScreenDimensions(gui_input)
    local scale_x = virt_x / screen_width
    local scale_y = virt_y / screen_height
    local cx, cy = GameGetCameraPos()
    local sx, sy = (x - cx) / scale_x + screen_width / 2 + 1.5, (y - cy) / scale_y + screen_height / 2
    return sx, sy
end


function GetGuiMousePosition(gui)
	local players = get_players()
	if(players ~= nil)then
		player = players[1]
		if(player ~= nil)then
			local controls_component = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")
			local gui = GuiCreate()
			GuiStartFrame(gui)
			local screen_width, screen_height = GuiGetScreenDimensions(gui)
			local input_x, input_y = 100, 100;
			local mx, my = mouse_raw_x * screen_width / 1280, mouse_raw_y * screen_height / 720
			GuiDestroy(gui)
			--local mx, my = ComponentGetValue2(controls_component, "mMousePositionRaw")
			return mx, my
		end
	end
	return 0, 0
end

function ParseStringColors(str)
    -- Define pattern: # followed by [digits,digits,digits]
    local pattern = "#%[(%d+),(%d+),(%d+)%]"

    -- Initialize the output table
    local output = {}

    -- Initialize the last match position and color
    local last_pos, last_color = 1, nil

    -- Iterate through the input string, matching the pattern
    for r, g, b, pos in string.gmatch(str, "()" .. pattern .. "()") do
        -- Extract the text before the color marker or between the pre-existing color markers
        local text = string.sub(str, last_pos, pos - #pattern - 1)

        -- Add an entry to the output table
        table.insert(output, {text = text, color = last_color})

        -- Update the last match position and color
        last_pos = pos
        last_color = {tonumber(r), tonumber(g), tonumber(b)}
    end

    -- Add the remaining text after the last color marker
    local remaining_text = string.sub(str, last_pos)
    if remaining_text ~= "" then
        table.insert(output, {text = remaining_text, color = last_color})
    end

    return output
end


function GetMouseDown()
	local players = get_players()
	if(players ~= nil)then
		player = players[1]
		if(player ~= nil)then
			local controls_component = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")
			local down = ComponentGetValue2(controls_component, "mButtonDownFire")
			return down
		end
	end
	return false
end

function GetCenterPosition(x, y, w, h)
	return x - (w/2), y - (h/2)
end

buttonHovers = buttonHovers or {}

function CustomButton(gui, identifier, x, y, z, scale, image, r, g, b, alpha)

	local width, height = GuiGetImageDimensions(gui, image, scale)
	GuiZSetForNextWidget(gui, z - 2)
	GuiImage(gui, NewID(identifier), x, y, image, 0.1, scale)
	local clicked, right_clicked, hovered, _x, _y, _width, _height, draw_x, draw_y, draw_width, draw_height = GuiGetPreviousWidgetInfo(gui)
	local button_id = NewID(identifier)
	if hovered then

		if(buttonHovers[button_id] == nil)then
			GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_select", 0, 0)
			buttonHovers[button_id] = true
		end


		
		-- render GuiImage on top
		GuiColorSetForNextWidget(gui, 255/255, 255/255, 178/255, 1)
		GuiImage(gui, NewID(identifier), -width, y, image, 1, scale)
	else
		buttonHovers[button_id] = nil
		-- render GuiImage on top
		GuiColorSetForNextWidget(gui, r, g, b, alpha)
		GuiImage(gui, NewID(identifier), -width, y, image, alpha, scale)
	end
	if(clicked)then
		GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", 0, 0)
		
	end
	return clicked
end

function DrawWindow(gui, z_index, x, y, w, h, title, centered, callback, close_callback, identifier)

	--print(tostring(title))
	--print(tostring(identifier))

	h = h - 12
	if(centered)then
		x, y = GetCenterPosition(x, y, w, h)
	end
	local bar_y = y
	y = y + 13

	GuiBeginAutoBox( gui )
	GuiZSet( gui, z_index - 1 )
	GuiColorSetForNextWidget( gui, 0, 0, 0, 0.3 )
	if(type(title) == "function")then
		GuiLayoutBeginHorizontal( gui,x, bar_y, true, 0, 0)
		GuiText(gui, 0, 0, " ")
		title()
		GuiLayoutEnd( gui )
		
	else
		GuiText(gui, x, bar_y, " "..title)
	end

	w = w + 12

	if(close_callback ~= nil)then
		GuiLayoutBeginLayer( gui )
		GuiLayoutBeginHorizontal( gui, 0, 0, true, 0, 0)
		if(CustomButton(gui, "sagsadshds", x + (w - 10), bar_y + 1, z_index - 600, 1, "mods/evaisa.mp/files/gfx/ui/minimize.png", 0, 0, 0, 0.5))then
			close_callback()
		end
		GuiLayoutEnd( gui )
		GuiLayoutEndLayer( gui )
	end

	GuiZSetForNextWidget( gui, z_index )
	GuiOptionsAddForNextWidget(gui, GUI_OPTION.IsExtraDraggable)
	GuiEndAutoBoxNinePiece( gui, 0, w, 8, false, 0, "mods/evaisa.mp/files/gfx/ui/9piece_window_bar.png", "mods/evaisa.mp/files/gfx/ui/9piece_window_bar.png")
	
	local clicked, right_clicked, hovered, bar_x, bar_y = GuiGetPreviousWidgetInfo( gui )

	--GuiOptionsAddForNextWidget(gui, GUI_OPTION.IgnoreContainer)

	local mouse_x, mouse_y = input:GetUIMousePos(gui)

	local disable_scroll = true

	

	-- check if mouse is over scroll container

	--[[
	if(mouse_x > x and mouse_x < x + w and mouse_y > y and mouse_y < y + h)then
		w = w - 12
		disable_scroll = false
	else
		w = w - 4
	end
	]]
	
	-- only do this if we are the upmost window hovered
	-- check old_window_stack for this
	
	local hovered_windows = {}
	for k, v in pairs(old_window_stack)do
		if(mouse_x > v.x and mouse_x < v.x + v.w and mouse_y > v.y and mouse_y < v.y + v.h)then
			table.insert(hovered_windows, v)
			--print("hovered window: "..tostring(k))
		--[[else
			print("not hovered window: "..tostring(k))]]
		end
	end

	window_stack[identifier] = {
		identifier = identifier,
		z_index = z_index,
		x = x,
		y = y,
		w = w,
		h = h,
	}

	if(last_hovered_window == identifier)then
		w = w - 12
		disable_scroll = false
	else
		if(#hovered_windows > 0)then
			-- check z index, lower z is higher up
			local highest_z = 9999
			local highest_window = nil
			for k, v in ipairs(hovered_windows)do
				if(v.z_index < highest_z)then
					highest_z = v.z_index
					highest_window = v.identifier
				end
			end
			if(highest_window ~= nil and highest_window == identifier)then
				w = w - 12
				disable_scroll = false
			else
				w = w - 4
			end
		else
			w = w - 4
		end
	end


	local id_extra = 0
	if(disable_scroll)then
		id_extra = id_extra + 1
		id_extra = GameGetFrameNum() % 2
	end

	local id = NewID(identifier)
	NewID(identifier)

	local screen_width, screen_height = GuiGetScreenDimensions( gui )
	
	GuiBeginAutoBox(gui)
	GuiLayoutBeginHorizontal( gui, screen_width + 5, screen_height + 5, true, 0, 0)
	callback(x, y, w, h)
	GuiLayoutEnd( gui )
	GuiZSetForNextWidget( gui, 10)
	GuiEndAutoBoxNinePiece( gui, 2, 0, 0, false, 0)
	local _, _, _, _, _, content_width, content_height = GuiGetPreviousWidgetInfo( gui )
	--print("contents height: "..tostring(content_height))
	--print("container height: "..tostring(h)	)

	
	if(content_height < h and not disable_scroll)then
		w = w + 8
	elseif(content_height >= h and not disable_scroll)then
		last_hovered_window = identifier
	end

	GuiOptionsAddForNextWidget(gui, GUI_OPTION.NoPositionTween)
	GuiOptionsRemove(gui, GUI_OPTION.DrawScaleIn)

	GuiZSetForNextWidget( gui, z_index + 1 )
	GuiBeginScrollContainer( gui, id + id_extra, x, y, w, h, true, 2, 2 )
	GuiZSet( gui, z_index )
	callback(x, y, w, h)
	GuiZSet( gui, 0 )
	GuiEndScrollContainer( gui )
end

function CustomTooltip(gui, callback, z, x_offset, y_offset )
	if z == nil then z = -12; end
	local left_click,right_click,hover,x,y,width,height,draw_x,draw_y,draw_width,draw_height = GuiGetPreviousWidgetInfo( gui );
	local screen_width,screen_height = GuiGetScreenDimensions( gui );
	if x_offset == nil then x_offset = 0; end
	if y_offset == nil then y_offset = 0; end
	if draw_y > screen_height * 0.5 then
		y_offset = y_offset - height;
	end
	if hover then
		local screen_width, screen_height = GuiGetScreenDimensions( gui );
		GuiZSet( gui, z );
		GuiLayoutBeginLayer( gui );
			GuiLayoutBeginVertical( gui, ( x + x_offset + width * 2 ) / screen_width * 100, ( y + y_offset ) / screen_height * 100 );
				GuiOptionsAdd( gui, GUI_OPTION.NoPositionTween )
				GuiBeginAutoBox( gui );
					if callback ~= nil then callback(); end
					GuiZSetForNextWidget( gui, z + 1 );
				GuiEndAutoBoxNinePiece( gui );
			GuiLayoutEnd( gui );
		GuiLayoutEndLayer( gui );
	end
end