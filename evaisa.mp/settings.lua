dofile("data/scripts/lib/mod_settings.lua")



local mod_id = "evaisa.mp" -- This should match the name of your mod's folder.
mod_settings_version = 1   -- This is a magic global that can be used to migrate settings to new mod versions. call mod_settings_get_version() before mod_settings_update() to get the old value.
mod_settings =
{
	{
		category_id = "default_settings",
		ui_name = "",
		ui_description = "",
		settings = {
			--[[{
				id = "artificial_lag",
				ui_name = "Artificial Lag",
				ui_description = "Adds a delay to all network traffic. Useful for testing network code.",
				value_default = 1,
				value_min = 1,
				value_max = 60,
				value_display_multiplier = 1,
				value_display_formatting = " $0",
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},]]
			{
				id = "hide_lobby_code",
				ui_name = "Hide Lobby Code",
				ui_description = "Censor lobby code in join lobby menu.",
				value_default = false,
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				id = "presets_as_json",
				ui_name = "Presets as JSON",
				ui_description = "Save presets as plain text JSON files.\nThis allows you to edit presets outside of the game. \nIssues caused by doing so will not be supported.",
				value_default = false,
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				id = "streamer_mode",
				ui_name = "Streamer Mode",
				ui_description = "Disable avatars and other stuff.",
				value_default = false,
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				id = "streamer_mode_detection",
				ui_name = "Streaming App Detection",
				ui_description = "Show popup asking if you want to enable streamer mode if a streaming app is detected, and streamer mode is disabled.",
				value_default = true,
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				id = "flip_chat_direction",
				ui_name = "Flip chat direction",
				ui_description = "Make new messages appear on the top of the chat box.",
				value_default = false,
				scope = MOD_SETTING_SCOPE_NEW_GAME,
			},
			{
				id = "profiler_rate",
				ui_name = "Profiler Rate",
				ui_description = "The rate at which the debugging profiler runs, in frames.",
				value_default = 1,
				value_min = 1,
				value_max = 300,
				value_display_multiplier = 1,
				value_display_formatting = " $0",
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				category_id = "keybinds",
				ui_name = "Keybindings",
				ui_description = "You can edit keybinds here.",
				foldable = true,
				_folded = true,
				settings = {
		
				}
			}
		},
	},
}

local bindings = nil

function ModSettingsUpdate(init_scope)
	local old_version = mod_settings_get_version(mod_id)
	mod_settings_update(mod_id, mod_settings, init_scope)


end

function ModSettingsGuiCount()
	return mod_settings_gui_count(mod_id, mod_settings)
end


function mod_setting_button( mod_id, gui, in_main_menu, im_id, setting )
	local value = setting.handler_callback( mod_id, setting )

	local text = setting.ui_name .. ": "

	GuiLayoutBeginHorizontal( gui, mod_setting_group_x_offset, 0, true)
	local clicked,right_clicked = GuiButton( gui, im_id, 0, 0, text )
	GuiColorSetForNextWidget( gui, 1, 1, 1, 0.65 )
	local clicked2,right_clicked2 = GuiButton( gui, im_id + 352623462, 0, 0, value )

	if clicked or clicked2 then
		setting.clicked_callback( mod_id, setting, value )
	end
	if right_clicked or right_clicked2 then
		setting.right_clicked_callback( mod_id, setting, value )
	end

	mod_setting_tooltip( mod_id, gui, in_main_menu, setting )
	GuiLayoutEnd( gui )
end

mod_settings_gui = function ( mod_id, settings, gui, in_main_menu )
	local im_id = 1

	for i,setting in ipairs(settings) do
		if setting.category_id ~= nil then
			-- setting category
			GuiIdPush( gui, im_id )
			if setting.foldable then
				local im_id2 = im_id
				im_id = im_id + 1
				local clicked_category_heading = mod_setting_category_button( mod_id, gui, im_id, im_id2, setting )
				if not setting._folded then
					GuiAnimateBegin( gui )
					GuiAnimateAlphaFadeIn( gui, 3458923234, 0.1, 0.0, clicked_category_heading )
					mod_setting_group_x_offset = mod_setting_group_x_offset + 6
					mod_settings_gui( mod_id, setting.settings, gui, in_main_menu )
					mod_setting_group_x_offset = mod_setting_group_x_offset - 6
					GuiAnimateEnd( gui )
					GuiLayoutAddVerticalSpacing( gui, 4 )
				end
			else
				GuiOptionsAddForNextWidget( gui, GUI_OPTION.DrawSemiTransparent )
				GuiText( gui, mod_setting_group_x_offset, 0, setting.ui_name )
				if is_visible_string( setting.ui_description ) then
					GuiTooltip( gui, setting.ui_description, "" )
				end
				mod_setting_group_x_offset = mod_setting_group_x_offset + 2
				mod_settings_gui( mod_id, setting.settings, gui, in_main_menu )
				mod_setting_group_x_offset = mod_setting_group_x_offset - 2
				GuiLayoutAddVerticalSpacing( gui, 4 )
			end
			GuiIdPop( gui )
		else
			-- setting
			local auto_gui = setting.ui_fn == nil
			local visible = (setting.hidden == nil or not setting.hidden)
			if auto_gui and visible then
				local value_type = type(setting.value_default)
				if setting.not_setting then
					mod_setting_title( mod_id, gui, in_main_menu, im_id, setting )
				elseif setting.is_button then
					mod_setting_button( mod_id, gui, in_main_menu, im_id, setting )
				elseif value_type == "boolean" then
					mod_setting_bool( mod_id, gui, in_main_menu, im_id, setting )
				elseif value_type == "number" then
					mod_setting_number( mod_id, gui, in_main_menu, im_id, setting )
				elseif value_type == "string" and setting.values ~= nil then
					mod_setting_enum( mod_id, gui, in_main_menu, im_id, setting )
				elseif value_type == "string" then
					mod_setting_text( mod_id, gui, in_main_menu, im_id, setting )
				end
			elseif visible then
				setting.ui_fn( mod_id, gui, in_main_menu, im_id, setting )
			end
		end

		im_id = im_id+1
	end
end

local function ToID (str)
	str = str:gsub("[^%w]", "_")
	-- lowercase
	str = str:lower()
	return str
end

mod_setting_title = function ( mod_id, gui, in_main_menu, im_id, setting )
	if(setting.color)then
		GuiColorSetForNextWidget( gui, setting.color[1], setting.color[2], setting.color[3], setting.color[4] )
	end
	GuiText( gui, mod_setting_group_x_offset + (setting.offset_x or nil), 0, setting.ui_name )
end

local function GenerateDisplayName(id)
	-- if id starts with "Key_", remove it
	if(id:sub(1, 4) == "Key_")then
		id = id:sub(5)
	end

	-- if starts with "JOY_BUTTON", replace with "Gamepad"
	if(id:sub(1, 11) == "JOY_BUTTON_")then
		id = "Gamepad " .. id:sub(12)
	end

	-- replace underscores with spaces
	id = id:gsub("_", " ")
	-- lowercase, then capitalize first letter
	id = id:sub(1, 1):upper() .. id:sub(2):lower()

	-- trim
	id = id:match("^%s*(.-)%s*$")

	return id
end

function ModSettingsGui(gui, in_main_menu)
	
	if(bindings == nil and not in_main_menu)then
		bindings = dofile_once("mods/evaisa.mp/lib/keybinds.lua")
		bindings:Load()

		local settings_cat = nil
		local all_bindings = {}
		-- sort bindings by category
		for _, id in pairs(bindings._binding_order)do
			if(bindings._bindings[id])then
				local bindy = bindings._bindings[id]
				bindy.id = id
				table.insert(all_bindings, bindy)
			end
		end

		table.sort(all_bindings, function(a, b)
			return a.category < b.category
		end)

		for k, v in ipairs(mod_settings[1].settings)do
			if(v.category_id == "keybinds")then
				settings_cat = v
				break
			end
		end
		local last_cat = nil
		for _, bind in pairs(all_bindings)do
			if(bind.category ~= last_cat)then
				last_cat = bind.category
				local cat = {
					id = "cat_" .. ToID(bind.category),
					ui_name = bind.category,
					ui_description = "Edit your keybinds here.",
					offset_x = -4,
					color = {219 / 255, 156 / 255, 79 / 255, 1},
					not_setting = true,
				}
				table.insert(settings_cat.settings, cat)
			end

			local id = bind.id
			local setting = {
				id = id,
				ui_name = bind.name,
				ui_description = "",
				value_default = bind.default,
				is_button = true,
				clicked_callback = function(mod_id, setting, value)
					bindings._bindings[setting.id].being_set = true
				end,
				right_clicked_callback = function(mod_id, setting, value)
					ModSettingSet("keybind."..bindings._bindings[setting.id].category .. "." .. setting.id, bindings._bindings[setting.id].default)
					ModSettingSet("keybind."..bindings._bindings[setting.id].category .. "." .. setting.id .. ".type", bindings._bindings[setting.id].default_type)
					bindings._bindings[setting.id].value = bindings._bindings[setting.id].default
					bindings._bindings[setting.id].type = bindings._bindings[setting.id].default_type
					
					bindings._bindings[setting.id].being_set = false
				end,
				handler_callback = function(mod_id, setting)
					if(bindings._bindings[setting.id].being_set)then
						return "[...]"
					end
					return "["..GenerateDisplayName(bindings._bindings[setting.id].value).."]"
				end
			}

			print("Adding keybind: " .. id)

			table.insert(settings_cat.settings, setting)
		end
	end


	mod_settings_gui(mod_id, mod_settings, gui, in_main_menu)

	if(bindings ~= nil)then
		bindings:Update()
	end
end
