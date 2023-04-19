dofile("mods/evaisa.mp/files/scripts/gui_utils.lua")
dofile_once("data/scripts/lib/utilities.lua")

pretty = require("pretty_print")

chat_gui = chat_gui or GuiCreate()

GuiStartFrame(chat_gui)

GuiOptionsAdd( chat_gui, GUI_OPTION.NoPositionTween )

local screen_width, screen_height = GuiGetScreenDimensions( chat_gui );

chat_open = chat_open or false


initial_chat_log = {}

for i = 1, 9 do
	table.insert(initial_chat_log, " ")
end

chat_log = chat_log or initial_chat_log

new_chat_message = new_chat_message or false
was_new_chat_message = was_new_chat_message or false
was_input_hovered = was_input_hovered or false

if(#chat_log > 50)then
	-- remove first item
	table.remove(chat_log, 1)
end


local GetPlayer = function()

    local player = EntityGetWithTag("player_unit")

    if(player == nil)then
        return
    end

    return player[1]
end

local LockPlayer = function()
    local player = GetPlayer()
    if(player == nil)then
        return
    end
    local controls = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")
    if(controls ~= nil)then
        ComponentSetValue2(controls, "enabled", false)
    end
end

local UnlockPlayer = function()
    local player = GetPlayer()
    if(player == nil)then
        return
    end

	if(not GameHasFlagRun("player_locked"))then
		local controls = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")
		if(controls ~= nil)then
			ComponentSetValue2(controls, "enabled", true)
		end
	end
end

if(lobby_code ~= nil)then
	local pressed, shift_held = hack_update_keys()

	local hit_enter = false
	for _, key in ipairs(pressed) do
		if key == "enter" or key == "return" then
			hit_enter = true
		end
		if(key == "t")then
			if(chat_open == false)then
				chat_open = true
			elseif(was_input_hovered == false)then
				chat_open = false
			end
		end
	end

	if(chat_open)then
		new_chat_message = false

		local window_width = 200
		local window_height = 100

		local window_text = "Chat"
		--GuiLayoutBeginVertical(gui, 0, 0, true, 0, 0)
		DrawWindow(chat_gui, 0, 4 + (window_width / 2), screen_height - ((window_height / 2) + 30), window_width, window_height, window_text, true, function()
			GuiLayoutBeginVertical(chat_gui, 0, 0, true, 0, 0)
			for k, v in ipairs(chat_log)do
				GuiText(chat_gui, 2, 0, v)
			end
			GuiLayoutEnd(chat_gui)
		end, function() 
			chat_open = false; 
		end, "chat_window")
		GuiLayoutBeginHorizontal(chat_gui, 0, 0, true, 0, 0)

		initial_text = initial_text or ""

		local input_text = GuiTextInput(chat_gui, NewID("Chatting"), 2, screen_height - 16, initial_text, window_width + 1, 52, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+[]{}\\|:'\",./<>?`~ ")

		local _, _, input_hovered = GuiGetPreviousWidgetInfo(chat_gui)

		if(initial_text ~= input_text)then
			initial_text = input_text
		end

		if(not was_input_hovered and input_hovered)then
			LockPlayer()
		elseif(was_input_hovered and not input_hovered)then
			UnlockPlayer()
		end

		if(hit_enter)then
			-- check if input text is not a empty string or entirely made of spaces
			if(#input_text > 0 and not input_text:match("^%s*$"))then
				local username = steam.friends.getPersonaName()
				local message = username .. ": " .. input_text
				
				local message_final = "chat;"
				local chunk_count = math.ceil(#message / 50)
				for i = 1, chunk_count do
					local start_index = (i - 1) * 50 + 1
					local end_index = i * 50
					if(end_index > #message)then
						end_index = #message
					end
					message_final = message_final .. string.sub(message, start_index, end_index) .. ";"
				end

				steam.matchmaking.sendLobbyChatMsg(lobby_code, message_final)
			end
			initial_text = ""
		end

		if(GuiImageButton(chat_gui, NewID("Chatting"), -2, screen_height - 16, "", "mods/evaisa.mp/files/gfx/ui/send.png"))then
			if(#input_text > 0)then
				local username = steam.friends.getPersonaName()
				local message = username .. ": " .. input_text

				local message_final = "chat;"
				local chunk_count = math.ceil(#message / 50)
				for i = 1, chunk_count do
					local start_index = (i - 1) * 50 + 1
					local end_index = i * 50
					if(end_index > #message)then
						end_index = #message
					end
					message_final = message_final .. string.sub(message, start_index, end_index) .. ";"
				end

				steam.matchmaking.sendLobbyChatMsg(lobby_code, message_final)
				
				--[[
				table.insert(chat_log, 1, input_text)
				if(#chat_log > 50)then
					-- remove last item
					table.remove(chat_log, #chat_log)
				end
				]]
			end 	
			initial_text = ""
		end

		GuiLayoutEnd(chat_gui)

		--GuiLayoutEnd(gui)

		was_input_hovered = input_hovered
	end


	GuiZSetForNextWidget(chat_gui, 0)
	if(GuiImageButton(chat_gui, NewID("MenuButton"), screen_width - 40, screen_height - 20, "", "mods/evaisa.mp/files/gfx/ui/chat.png"))then
		chat_open = not chat_open
		GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", 0, 0)
	end

	if(new_chat_message)then
		--GamePrint("whar")
		if(not chat_open)then
			if(not was_new_chat_message)then
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