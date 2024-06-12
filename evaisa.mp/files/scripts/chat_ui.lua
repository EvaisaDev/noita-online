dofile_once("data/scripts/lib/utilities.lua")
local text_input = dofile("mods/evaisa.mp/files/scripts/text_input.lua")

pretty = require("pretty_print")

chat_gui = chat_gui or GuiCreate()

GuiStartFrame(chat_gui)




GuiOptionsAdd(chat_gui, GUI_OPTION.NoPositionTween)

local screen_width, screen_height = GuiGetScreenDimensions(chat_gui);

chat_open = chat_open or false


initial_chat_log = {}
local reverse_chat_direction = ModSettingGet("evaisa.mp.flip_chat_direction")

for i = 1, 20 do
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


local reverse_chat_direction = ModSettingGet("evaisa.mp.flip_chat_direction")


local function split_message(msg)
	local words = {}
	local index = 1
	for word in string.gmatch(msg, "%S+") do

		-- split word into chunks of 200 pixels or less

		local width, height = GuiGetTextDimensions(chat_gui, word)

		if (width > 200) then
			local chunks = {}
			local chunk = ""
			for i = 1, #word do
				local char = word:sub(i, i)
				local char_width, char_height = GuiGetTextDimensions(chat_gui, chunk .. char)
				if (char_width <= 200) then
					chunk = chunk .. char
				else
					table.insert(chunks, chunk)
					chunk = char
				end
			end
			table.insert(chunks, chunk)

			for i, chunk in ipairs(chunks) do
				table.insert(words, chunk)
			end
		else
			table.insert(words, word)
		end


		index = index + 1
	end

	local chunks = {}
	local chunk = ""
	for i, word in ipairs(words) do
		local width, height = GuiGetTextDimensions(chat_gui, chunk .. " " .. word)

		--print("width: " .. tostring(width))

		if width <= 200 then
			if chunk == "" then
				chunk = word
			else
				chunk = chunk .. " " .. word
			end
		else
			table.insert(chunks, chunk)
			chunk = word
		end
	end
	table.insert(chunks, chunk)

	return chunks
end

function handleChatMessage(data)
	--[[
		example data:

		{
			lobbyID = 9223372036854775807,
			userID = 76361198523269435,
			type = 1,
			chatID = 1,
			fromOwner = true,
			message = "chat;evaisa: hello there how are you today?; I am great!; Yeah!"
		}
	]]

	local message = data.message
	local split_data = {}
	for token in string.gmatch(message, "[^;]+") do
		table.insert(split_data, token)
	end

	if (#split_data > 1 and split_data[1] == "chat") then
		local buffer = {}
		for i = 1, #split_data do
			if (i ~= 1) then

				local msg = steam_utils.getTranslatedPersonaName(data.userID, data.userID == steam_utils.getSteamID()) .. ": " .. split_data[i]

				local chunks = split_message(msg)

				for h = 1, #chunks do
					if (not reverse_chat_direction) then
						local was_found = false
						for j = 1, #chat_log do
							if (chat_log[j] == " ") then
								chat_log[j] = chunks[h]
								new_chat_message = true
								was_found = true
								break
							end
						end
						if (not was_found) then
							table.insert(chat_log, chunks[h])
							new_chat_message = true
						end
					else
						local empty_index = nil
						for j = 1, #chat_log do
							if (chat_log[j] == " ") then
								empty_index = j
								break
							end
						end
						if (empty_index ~= nil) then
							table.remove(chat_log, empty_index)
						end

						table.insert(buffer, chunks[h])
						new_chat_message = true
					end
				end

			end
		end
		if(reverse_chat_direction)then
			for i = #buffer, 1, -1 do
				print("inserting "..buffer[i].." at 1")
				table.insert(chat_log, 1, buffer[i])
			end
		end
	end
end

function ChatPrint(text)

	local buffer = {}
	local chunks = split_message(text)

	for h = 1, #chunks do
		if (not reverse_chat_direction) then
			local was_found = false
			for j = 1, #chat_log do
				if (chat_log[j] == " ") then
					chat_log[j] = chunks[h]
					new_chat_message = true
					was_found = true
					break
				end
			end
			if (not was_found) then
				table.insert(chat_log, chunks[h])
				new_chat_message = true
			end
		else
			local empty_index = nil
			for j = 1, #chat_log do
				if (chat_log[j] == " ") then
					empty_index = j
					break
				end
			end
			if (empty_index ~= nil) then
				table.remove(chat_log, empty_index)
			end

			table.insert(buffer, chunks[h])
			new_chat_message = true
		end
	end

	if(reverse_chat_direction)then
		for i = #buffer, 1, -1 do
			print("inserting "..buffer[i].." at 1")
			table.insert(chat_log, 1, buffer[i])
		end
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
		GameAddFlagRun("player_locked_chat")
		ComponentSetValue2(controls, "enabled", false)
	end
end

local UnlockPlayer = function()
	if(not GameHasFlagRun("player_locked_chat"))then
		return
	end

	local player = GetPlayer()
	if (player == nil) then
		return
	end

	if (not GameHasFlagRun("player_locked")) then
		local controls = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")
		if (controls ~= nil) then
			GameRemoveFlagRun("player_locked_chat")
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


	if (bindings:IsJustDown("chat_open_kb") and not GameHasFlagRun("chat_bind_disabled")) then
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

	--[[if (not chat_open) then
		GuiOptionsAdd(chat_gui, GUI_OPTION.NonInteractive)
	end]]


	if (chat_open) then
		new_chat_message = false

		local window_width = 200
		local window_height = 100

		local window_text = GameTextGetTranslatedOrNot("$mp_chat")
		--GuiLayoutBeginVertical(gui, 0, 0, true, 0, 0)
		DrawWindow(chat_gui, -7000, 4, screen_height - (window_height + 28), window_width,
			window_height, window_text, false, function()
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
		elseif (not input_hovered) then
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

					if(command_name == nil)then
						local username = steamutils.getTranslatedPersonaName(steam_utils.getSteamID())
						local message = username .. ": " .. input_text
	
						local message_final = "chat;" .. message
						steam.matchmaking.sendLobbyChatMsg(lobby_code, message_final)
					else

						mp_log:print("command received: " .. command_name)

						if(lobby_code ~= nil)then
							local active_mode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))
							if(active_mode ~= nil and active_mode.commands and active_mode.commands[command_name])then
								active_mode.commands[command_name](command_name, args)
							elseif(active_mode ~= nil )then
								--local username = steamutils.getTranslatedPersonaName(steam_utils.getSteamID())
								local message = input_text
			
								local message_final = "chat;" .. message
								steam.matchmaking.sendLobbyChatMsg(lobby_code, message_final)

							end
						end
					end
				else

					--local username = steamutils.getTranslatedPersonaName(steam_utils.getSteamID())
					local message = input_text

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

	GuiZSetForNextWidget(chat_gui, 0)

	if (GameGetIsGamepadConnected()) then
		GuiOptionsAddForNextWidget(chat_gui, GUI_OPTION.NonInteractive)
	end
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
