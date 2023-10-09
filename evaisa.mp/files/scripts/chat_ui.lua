dofile_once("data/scripts/lib/utilities.lua")
local text_input = dofile("mods/evaisa.mp/files/scripts/text_input.lua")

pretty = require("pretty_print")

chat_gui = chat_gui or GuiCreate()

GuiStartFrame(chat_gui)

if (GameGetIsGamepadConnected()) then
	GuiOptionsAdd(chat_gui, GUI_OPTION.NonInteractive)
end


GuiOptionsAdd(chat_gui, GUI_OPTION.NoPositionTween)

local screen_width, screen_height = GuiGetScreenDimensions(chat_gui);

chat_open = chat_open or false


initial_chat_log = {}
local reverse_chat_direction = ModSettingGet("evaisa.mp.flip_chat_direction")

for i = 1, 9 do
	table.insert(initial_chat_log, " ")
end


chat_log = chat_log or initial_chat_log

new_chat_message = new_chat_message or false
was_new_chat_message = was_new_chat_message or false
was_input_hovered = was_input_hovered or false


if (#chat_log > 50) then
	-- remove first item
	if (not reverse_chat_direction) then
		table.remove(chat_log, 1)
	else
		table.remove(chat_log, #chat_log)
	end
end


local GetPlayer = function()
	local player = EntityGetWithTag("player_unit")

	if (player == nil) then
		return
	end

	return player[1]
end

local LockPlayer = function()
	local player = GetPlayer()
	if (player == nil) then
		return
	end
	local controls = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")
	if (controls ~= nil) then
		ComponentSetValue2(controls, "enabled", false)
	end
end

local UnlockPlayer = function()
	local player = GetPlayer()
	if (player == nil) then
		return
	end

	if (not GameHasFlagRun("player_locked")) then
		local controls = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")
		if (controls ~= nil) then
			ComponentSetValue2(controls, "enabled", true)
		end
	end
end

chat_opened_with_bind = chat_opened_with_bind or false

if (lobby_code ~= nil) then
	--local pressed, shift_held = hack_update_keys()

	local hit_enter = false
	
	local toggled_chat = false
	--for _, key in ipairs(pressed) do
	if bindings:IsJustDown("chat_submit") or bindings:IsJustDown("chat_submit2")  then
		hit_enter = true
		toggled_chat = true
	end


	if (bindings:IsJustDown("chat_open") and not GameHasFlagRun("chat_bind_disabled")) then
		if (chat_open == false) then
			chat_open = true
			chat_opened_with_bind = true
			toggled_chat = true
		elseif (chat_input ~= nil and not chat_input.focus) then
			chat_open = false
			chat_opened_with_bind = false
			toggled_chat = true
		end
	end

	--end

	if (not chat_open) then
		GuiOptionsAdd(chat_gui, GUI_OPTION.NonInteractive)
	end


	if (chat_open) then
		new_chat_message = false

		local window_width = 200
		local window_height = 100

		local window_text = GameTextGetTranslatedOrNot("$mp_chat")
		--GuiLayoutBeginVertical(gui, 0, 0, true, 0, 0)
		DrawWindow(chat_gui, 0, 4 + (window_width / 2), screen_height - ((window_height / 2) + 30), window_width,
			window_height, window_text, true, function()
				GuiLayoutBeginVertical(chat_gui, 0, 0, true, 0, 0)
				for k, v in ipairs(chat_log) do
					GuiText(chat_gui, 2, 0, v)
				end
				GuiLayoutEnd(chat_gui)
			end, function()
				chat_open = false;
			end, "chat_window")
		GuiLayoutBeginHorizontal(chat_gui, 0, 0, true, 0, 0)

		chat_input = chat_input or text_input.create(chat_gui, 2, screen_height - 16, window_width + 2, "", 100, nil, ";", 0)

		input_text = input_text or ""
		
		chat_input.text = input_text
		chat_input:transform(2, screen_height - 16, window_width + 2)
		if(not toggled_chat)then
			chat_input:update()
		end
		chat_input:draw()
		if(chat_opened_with_bind)then
			chat_opened_with_bind = false
			chat_input.focus = true
		end


		input_text = chat_input.text

		
		--[[local input_text = GuiTextInput(chat_gui, NewID("Chatting"), 2, screen_height - 16, initial_text,
			window_width + 1, 52,
			"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+[]{}\\|:'\",./<>?`~ ")]]

		--local _, _, input_hovered = GuiGetPreviousWidgetInfo(chat_gui)

		--[[
		if (initial_text ~= input_text) then
			initial_text = input_text
		end
		]]

		--input_text = ""
		input_hovered = chat_input.focus

		if (input_hovered) then
			if (not GameHasFlagRun("chat_input_hovered")) then
				GameAddFlagRun("chat_input_hovered")
			end
		else
			if (GameHasFlagRun("chat_input_hovered")) then
				GameRemoveFlagRun("chat_input_hovered")
			end
		end

		if (not was_input_hovered and input_hovered) then
			LockPlayer()
		elseif (was_input_hovered and not input_hovered) then
			UnlockPlayer()
		end

		local sendMessage = function()
			chat_input.cursor_pos = 0
			if (utf8.len(input_text) > 0 and not input_text:match("^%s*$")) then
				-- check if message begins with / or !
				local command = input_text:sub(1, 1)

				if (command == "/" or command == "!") then
					-- get command name, get arguments as table, remove ! or / from command name
					local command_name, args = input_text:match("([%w_]+)%s*(.*)")

					mp_log:print("command received: " .. command_name)

					if(lobby_code ~= nil)then
						local active_mode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))
						if(active_mode ~= nil and active_mode.commands and active_mode.commands[command_name])then
							active_mode.commands[command_name](command_name, args)
						end
					end
				else
					local username = steamutils.getTranslatedPersonaName()
					local message = username .. ": " .. input_text

					local message_final = "chat;" .. message
					steam.matchmaking.sendLobbyChatMsg(lobby_code, message_final)
				end
			end
			input_text = ""
		end

		if (hit_enter) then
			sendMessage()
		end

		if (GuiImageButton(chat_gui, NewID("Chatting"), 3, screen_height - 16, "", "mods/evaisa.mp/files/gfx/ui/send2.png")) then
			sendMessage()
		end

		GuiLayoutEnd(chat_gui)

		--GuiLayoutEnd(gui)

		was_input_hovered = input_hovered
	end

	if (not GameGetIsGamepadConnected()) then
		GuiOptionsRemove(chat_gui, GUI_OPTION.NonInteractive)
	end

	GuiZSetForNextWidget(chat_gui, 0)
	if (GuiImageButton(chat_gui, NewID("MenuButton"), screen_width - 40, screen_height - 20, "", "mods/evaisa.mp/files/gfx/ui/chat.png")) then
		chat_open = not chat_open
		chat_opened_with_bind = false
		GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", 0, 0)
	end

	if (new_chat_message) then
		--GamePrint("whar")
		if (not chat_open) then
			if (not was_new_chat_message) then
				GamePlaySound("mods/evaisa.mp/online.bank", "message/received", 0, 0)
				--GamePrint("Playing notification noise")
			end

			GuiZSetForNextWidget(chat_gui, -1)
			GuiImage(chat_gui, NewID("Notification"), screen_width - 42, screen_height - 22, "mods/evaisa.mp/files/gfx/ui/notification.png", 1, 1, 1)
		end
	end

	was_new_chat_message = new_chat_message
else
	chat_log = initial_chat_log
end
