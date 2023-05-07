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
				id = "flip_chat_direction",
				ui_name = "$mp_flip_chat_direction_name",
				ui_description = "$mp_flip_chat_direction_description",
				value_default = false,
				scope = MOD_SETTING_SCOPE_NEW_GAME,
			},
		},
	},
}

function ModSettingsUpdate(init_scope)
	local old_version = mod_settings_get_version(mod_id)
	mod_settings_update(mod_id, mod_settings, init_scope)
end

function ModSettingsGuiCount()
	return mod_settings_gui_count(mod_id, mod_settings)
end

function ModSettingsGui(gui, in_main_menu)
	mod_settings_gui(mod_id, mod_settings, gui, in_main_menu)
end
