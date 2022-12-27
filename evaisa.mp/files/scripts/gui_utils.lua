dofile_once("data/scripts/lib/utilities.lua")
local generated_id = 1000
function NewID(identifier)
	generated_id = generated_id + 1
	if(identifier ~= nil)then
		generated_id = generated_id + tostring(string.byte(identifier))
	end
	return generated_id
end

function GetGuiMousePosition(gui)
	local players = get_players()
	if(players ~= nil)then
		player = players[1]
		if(player ~= nil)then
			local controls_component = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")
			local screen_width, screen_height = GuiGetScreenDimensions(gui)
			local mouse_raw_x, mouse_raw_y = ComponentGetValue2(controls_component, "mMousePositionRaw")
			local mx, my = mouse_raw_x * screen_width / 1280, mouse_raw_y * screen_height / 720
			--local mx, my = ComponentGetValue2(controls_component, "mMousePositionRaw")
			return mx, my
		end
	end
	return 0, 0
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

function DrawWindow(gui, z_index, x, y, w, h, title, centered, callback, close_callback)

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

	if(close_callback ~= nil)then
		GuiLayoutBeginLayer( gui )
		GuiLayoutBeginHorizontal( gui, 0, 0, true, 0, 0)
		if(CustomButton(gui, "sagsadshds", x + (w + 2), bar_y + 1, z_index - 600, 1, "mods/evaisa.mp/files/gfx/ui/minimize.png", 0, 0, 0, 0.5))then
			close_callback()
		end
		GuiLayoutEnd( gui )
		GuiLayoutEndLayer( gui )
	end

	GuiZSetForNextWidget( gui, z_index )
	GuiOptionsAddForNextWidget(gui, GUI_OPTION.IsExtraDraggable)
	GuiEndAutoBoxNinePiece( gui, 0, w + 12, 8, false, 0, "mods/evaisa.mp/files/gfx/ui/9piece_window_bar.png", "mods/evaisa.mp/files/gfx/ui/9piece_window_bar.png")
	
	local clicked, right_clicked, hovered, bar_x, bar_y = GuiGetPreviousWidgetInfo( gui )

	GuiZSetForNextWidget( gui, z_index + 1 )
	GuiBeginScrollContainer( gui, NewID(), x, y, w, h, true, 2, 2 )
	GuiZSet( gui, z_index )
	callback()
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