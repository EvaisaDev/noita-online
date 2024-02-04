dofile_once("data/scripts/lib/utilities.lua")

pretty = require("pretty_print")

menu_gui = menu_gui or GuiCreate()

GuiStartFrame(menu_gui)


status = {
	main_menu = 1,
	lobby = 2,
	creating_lobby = 3,
	joining_lobby = 4,
	disconnected = 5,
}

GuiOptionsAdd( menu_gui, GUI_OPTION.NoPositionTween )
if(GameGetIsGamepadConnected())then
	GuiOptionsAdd(menu_gui, GUI_OPTION.NonInteractive)
end

local lobby_types = {
	GameTextGetTranslatedOrNot("$mp_public"),
	GameTextGetTranslatedOrNot("$mp_private"),
	GameTextGetTranslatedOrNot("$mp_friends_only"),
}

gui_closed = gui_closed or false
invite_menu_open = invite_menu_open or false
mod_list_open = mod_list_open or false
lobby_settings_open = lobby_settings_open or false
lobby_presets_open = lobby_presets_open or false
was_lobby_presets_open = was_lobby_presets_open or false
settings_changed = settings_changed or false

local is_in_lobby = lobby_code ~= nil and true or false

selected_player = selected_player or nil

menu_status = menu_status or status.main_menu

show_lobby_code = show_lobby_code or false

if(is_in_lobby)then
	menu_status = status.lobby
end

active_custom_menu = active_custom_menu or nil

local screen_width, screen_height = GuiGetScreenDimensions( menu_gui );

-- replace each letter in string with *
function censorString(input)
	local output = ""
	for i = 1, string.len(input) do
		output = output .. "X"
	end
	return output
end


function CreateLobby(type, max_players, callback)
	--print("yeah?")
	steam.matchmaking.createLobby(type, max_players, function(e) 
		--print("did this run?")
		if(tostring(e.result) == "1")then
			callback(e.lobby)
		else
			mp_log:print("CreateLobby failed: " .. tostring(e.result))
		end
	end )
end



initial_refreshes = initial_refreshes or 10

if(initial_refreshes > 0)then
	refreshLobbies()
	initial_refreshes = initial_refreshes - 1
end




local windows = {
	{
		name = "Menu",
		func = function()

			local window_width = 200
			local window_height = 180
		
			local window_text = GameTextGetTranslatedOrNot("$mp_lobby_list_header")
		
			DrawWindow(menu_gui, -4000, screen_width / 2, screen_height / 2, window_width, window_height, window_text, true, function()
				GuiLayoutBeginVertical(menu_gui, 0, 0, true, 0, 0)

				if(GuiButton(menu_gui, NewID(), 0, 0, GameTextGetTranslatedOrNot("$mp_create_lobby")))then
					menu_status = status.creating_lobby
				end

				if(GuiButton(menu_gui, NewID(), 0, 0, GameTextGetTranslatedOrNot("$mp_join_with_code")))then
					menu_status = status.joining_lobby
				end

				GuiText(menu_gui, 2, 0, " ")
				if(GuiButton(menu_gui, NewID(), 0, 0, GameTextGetTranslatedOrNot("$mp_refresh_lobby_list")))then
					refreshLobbies()
				end
				GuiText(menu_gui, 2, 0, " ")
				GuiText(menu_gui, 2, 0, "----- "..GameTextGetTranslatedOrNot("$mp_friend_lobbies").." -----")
				if(#lobbies.friend > 0)then
					for k, v in ipairs(lobbies.friend)do
						if(steam.matchmaking.requestLobbyData(v))then
							local lobby_mode_id = steam.matchmaking.getLobbyData(v, "gamemode")
							local active_mode = FindGamemode(steam.matchmaking.getLobbyData(v, "gamemode"))
							local lobby_name = steam.matchmaking.getLobbyData(v, "name")

							local lobby_members = steam.matchmaking.getNumLobbyMembers(v)
							local lobby_max_players = steam.matchmaking.getLobbyMemberLimit(v)

							if(lobby_name ~= nil and active_mode ~= nil and lobby_mode_id ~= nil and lobby_members ~= nil and lobby_max_players ~= nil)then
								GuiLayoutBeginHorizontal(menu_gui, 0, 0, true, 0, 0)
								if(not IsCorrectVersion(v))then
									if(GuiButton(menu_gui, NewID(), 0, 0, GameTextGetTranslatedOrNot("$mp_version_mismatch").." "..lobby_name))then
										steam.matchmaking.leaveLobby(v)
										steam.matchmaking.joinLobby(v, function(e)
										end)
									end
								else
									if(active_mode ~= nil)then
										if(GuiButton(menu_gui, NewID(), 0, 0, "("..GameTextGetTranslatedOrNot(active_mode.name)..")("..tostring(lobby_members).."/"..tostring(lobby_max_players)..") "..lobby_name))then
											steam.matchmaking.leaveLobby(v)
											steam.matchmaking.joinLobby(v, function(e)
											end)
										end
									else
										if(GuiButton(menu_gui, NewID(), 0, 0, "("..lobby_mode_id..""..GameTextGetTranslatedOrNot("$mp_missing")..")("..tostring(lobby_members).."/"..tostring(lobby_max_players)..") "..lobby_name))then
											steam.matchmaking.leaveLobby(v)
											steam.matchmaking.joinLobby(v, function(e)
											end)
										end
									end
								end

								GuiLayoutEnd(menu_gui)
							end
						end
					end
				else
					GuiText(menu_gui, 2, 0, GameTextGetTranslatedOrNot("$mp_no_lobbies_found"))
				end
				GuiText(menu_gui, 2, 0, " ")
				GuiText(menu_gui, 2, 0, "----- "..GameTextGetTranslatedOrNot("$mp_public_lobbies").." -----")
				if(#lobbies.public > 0)then
					for k, v in ipairs(lobbies.public)do
						local lobby_mode_id = steam.matchmaking.getLobbyData(v, "gamemode")
						local active_mode = FindGamemode(steam.matchmaking.getLobbyData(v, "gamemode"))
						local lobby_name = steam.matchmaking.getLobbyData(v, "name")

						local lobby_members = steam.matchmaking.getNumLobbyMembers(v)
						local lobby_max_players = steam.matchmaking.getLobbyMemberLimit(v)

						if(lobby_name ~= nil and active_mode ~= nil and lobby_mode_id ~= nil and lobby_members ~= nil and lobby_max_players ~= nil)then
							GuiLayoutBeginHorizontal(menu_gui, 0, 0, true, 0, 0)
							if(not IsCorrectVersion(v))then
								if(GuiButton(menu_gui, NewID(), 0, 0, GameTextGetTranslatedOrNot("$mp_version_mismatch").." "..lobby_name))then
									steam.matchmaking.leaveLobby(v)
									steam.matchmaking.joinLobby(v, function(e)
									end)
								end
							else
								if(active_mode ~= nil)then
									if(GuiButton(menu_gui, NewID(), 0, 0, "("..GameTextGetTranslatedOrNot(active_mode.name)..")("..tostring(lobby_members).."/"..tostring(lobby_max_players)..") "..lobby_name))then
										steam.matchmaking.leaveLobby(v)
										steam.matchmaking.joinLobby(v, function(e)
										end)
									end
								else
									if(GuiButton(menu_gui, NewID(), 0, 0, "("..lobby_mode_id..GameTextGetTranslatedOrNot("$mp_missing")..")("..tostring(lobby_members).."/"..tostring(lobby_max_players)..") "..lobby_name))then

									end
								end
							end
							

							GuiLayoutEnd(menu_gui)
						end
					end
				else
					GuiText(menu_gui, 2, 0, GameTextGetTranslatedOrNot("$mp_no_lobbies_found"))
				end
					
				
				--[[
				for i = 1, 40 do
					GuiText(menu_gui, 2, 0, " ")
				end
				]]

				GuiLayoutEnd(menu_gui)
			end, function() 
				gui_closed = true; 
				invite_menu_open = false 
				selected_player = nil
			end, "main_menu_gui")

		end
	},
	{
		name = "Lobby",
		func = function()
			local window_width = 200
			local window_height = 180

			function string_to_number(str)
				local num = 0
				local validCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
				local str_len = #validCharacters
				for i=1, str_len do
				  local ch = str:sub(i, i)
				  local value = validCharacters:find(ch)
				  value = value - 1
				  num = num + math.pow(str_len, (#str - i)) * value
				end
				return num
			end

			if(not lobby_code)then
				-- force return to main menu
				print("Disconnected from lobby?? (no lobby code)")
				gui_closed = false
				gamemode_settings = {}
				initial_refreshes = 10
				invite_menu_open = false
				menu_status = status.main_menu
				show_lobby_code = false
				lobby_code = nil
				banned_members = {}
				return;
			end

			DrawWindow(menu_gui, -5000, screen_width / 2, screen_height / 2, window_width, window_height, function() 

				GuiColorSetForNextWidget( menu_gui, 0, 0, 0, 0.3 )
				GuiText(menu_gui, 0, 0, GameTextGetTranslatedOrNot("$mp_lobby").." - ("..((not show_lobby_code) and censorString(steam.utils.compressSteamID(lobby_code)) or steam.utils.compressSteamID(lobby_code))..")")

				GuiColorSetForNextWidget( menu_gui, (74 / 2) / 255, (62 / 2) / 255, (46 / 2) / 255, 0.5 )
				GuiImage(menu_gui, NewID("Lobby"), 1, 1.5, (show_lobby_code) and "mods/evaisa.mp/files/gfx/ui/hide.png" or "mods/evaisa.mp/files/gfx/ui/show.png", 0.5, 1)
				

				GuiColorSetForNextWidget( menu_gui, 0, 0, 0, 0.5 )
				if(GuiButton(menu_gui, NewID("Lobby"), 0, 0, show_lobby_code and " "..GameTextGetTranslatedOrNot("$mp_hide") or " "..GameTextGetTranslatedOrNot("$mp_show")))then
					show_lobby_code = not show_lobby_code
				end
				
				if(show_lobby_code)then
					CustomTooltip(menu_gui, function() 
						--GuiZSetForNextWidget(menu_gui, -5110)
						GuiColorSetForNextWidget( menu_gui, 1, 1, 1, 0.8 )
						--GuiText(menu_gui, 0, 0, "Hide Code")
						GuiZSetForNextWidget(menu_gui, -5110)
						GuiText(menu_gui, 0, 0, GameTextGetTranslatedOrNot("$mp_hide_tooltip"))
					end, -5100, -60, -20)
				else
					CustomTooltip(menu_gui, function() 
						--GuiZSetForNextWidget(menu_gui, -5110)
						GuiColorSetForNextWidget( menu_gui, 1, 1, 1, 0.8 )
						--GuiText(menu_gui, 0, 0, "Show Code")
						GuiZSetForNextWidget(menu_gui, -5110)
						GuiText(menu_gui, 0, 0, GameTextGetTranslatedOrNot("$mp_show_tooltip"))
					end, -5100, -68, -20)
				end

				GuiColorSetForNextWidget( menu_gui, (74 / 2) / 255, (62 / 2) / 255, (46 / 2) / 255, 0.5 )
				GuiImage(menu_gui, NewID("Lobby"), 6, 1.5, "mods/evaisa.mp/files/gfx/ui/copy.png", 0.5, 1)

				GuiColorSetForNextWidget( menu_gui, 0, 0, 0, 0.5 )
				if(GuiButton(menu_gui, NewID("Lobby"), -1, 0, " "..GameTextGetTranslatedOrNot("$mp_copy")))then
					steam.utils.setClipboard(steam.utils.compressSteamID(lobby_code))
				end

				CustomTooltip(menu_gui, function() 
					--GuiZSetForNextWidget(menu_gui, -5110)
					GuiColorSetForNextWidget( menu_gui, 1, 1, 1, 0.8 )
					--GuiText(menu_gui, 0, 0, "Show Code")
					GuiZSetForNextWidget(menu_gui, -5110)
					GuiText(menu_gui, 0, 0, GameTextGetTranslatedOrNot("$mp_copy_tooltip"))
				end, -5100, -150, -20)
				
			end, true, function(window_x, window_y, window_width, window_height)
				


				local owner = steam.matchmaking.getLobbyOwner(lobby_code)



				--local _, _, _, _, _, width, height = GuiGetPreviousWidgetInfo(menu_gui)

				local current_button_height = 0

		
				local lobby_presets_translation = GameTextGetTranslatedOrNot("$mp_lobby_presets")
				local lobby_presets_button_text = lobby_presets_open and lobby_presets_translation.." >" or lobby_presets_translation.." <"
				local text_width, text_height = GuiGetTextDimensions(menu_gui, lobby_presets_button_text)
				current_button_height = current_button_height + text_height
				local button_x_position = window_width - text_width
				GuiLayoutBeginVertical(menu_gui, button_x_position, 0, true, 0, 0)
				if(GuiButton(menu_gui, NewID("lobby_presets_button"), 0, 0, lobby_presets_button_text))then
					lobby_presets_open = not lobby_presets_open
					active_custom_menu = nil
					invite_menu_open = false
					selected_player = nil
				end
				--current_button_offset = current_button_offset + text_height

				local active_mode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))
				if(active_mode ~= nil and active_mode.lobby_menus ~= nil)then
					for i, lobby_menu in ipairs(active_mode.lobby_menus)do
						if(lobby_menu.button_location == nil or lobby_menu.button_location == "main_window")then
							local button_text = active_custom_menu == lobby_menu.id and GameTextGetTranslatedOrNot(lobby_menu.button_text).." >" or GameTextGetTranslatedOrNot(lobby_menu.button_text).." <"
							local text_width, text_height = GuiGetTextDimensions(menu_gui, button_text)
							local button_x_position = window_width - text_width
							current_button_height = current_button_height + text_height
							if(GuiButton(menu_gui, NewID("lobby_menu_"..lobby_menu.id), 0, 0, button_text))then
								if(active_custom_menu == lobby_menu.id)then
									active_custom_menu = nil
								else
									active_custom_menu = lobby_menu.id
								end

								lobby_presets_open = false
								invite_menu_open = false
								selected_player = nil
							end
							--current_button_offset = current_button_offset + text_height
						end
					end
				end
				GuiLayoutEnd(menu_gui)

				GuiLayoutBeginVertical(menu_gui, 0, 0, true, 0, 0)


				if(GuiButton(menu_gui, NewID("lobby_leave_button"), 0, 0, GameTextGetTranslatedOrNot("$mp_leave_lobby")))then
					local active_mode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))
					if(active_mode)then
						active_mode.leave(lobby_code)
						delay.reset()
					end
					gui_closed = false
					gamemode_settings = {}
					steam.matchmaking.leaveLobby(lobby_code)
					initial_refreshes = 10
					invite_menu_open = false
					menu_status = status.main_menu
					show_lobby_code = false
					lobby_code = nil
					banned_members = {}
					return
				end


				local invite_translation = GameTextGetTranslatedOrNot("$mp_invite_players")
				if(GuiButton(menu_gui, NewID("lobby_invite_button"), 0, 0, invite_menu_open and "< "..invite_translation or "> "..invite_translation))then
					invite_menu_open = not invite_menu_open
					lobby_settings_open = false
				end

				local lobby_settings_translation = GameTextGetTranslatedOrNot("$mp_lobby_settings")
				if(GuiButton(menu_gui, NewID("lobby_settings_button"), 0, 0, lobby_settings_open and "< "..lobby_settings_translation or "> "..lobby_settings_translation))then
					lobby_settings_open = not lobby_settings_open
					invite_menu_open = false
				end

				-- calculate relative offset from window_y
				local relative_offset = 33

				--GamePrint("relative_offset: "..tostring(relative_offset).."; current_button_height: "..tostring(current_button_height))

				local offset = 0
				if(current_button_height > relative_offset)then
					offset = current_button_height
				else
					offset = relative_offset
				end

				GuiLayoutEnd(menu_gui)

				GuiLayoutBeginVertical(menu_gui, 0, offset, true, 0, 0)

				local active_mode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))
				local spectating = steamutils.IsSpectator(lobby_code)
				if(active_mode and active_mode.spectate ~= nil and active_mode.disable_spectator_system ~= true)then
					if(GuiButton(menu_gui, NewID("lobby_spectate_button"), 0, 0, spectating and GameTextGetTranslatedOrNot("$mp_spectator_mode_enabled")..(active_mode.spectator_unfinished_warning and " [Unfinished]" or "") or GameTextGetTranslatedOrNot("$mp_spectator_mode_disabled")..(active_mode.spectator_unfinished_warning and " [Unfinished]" or "")))then
						if(owner == steam.user.getSteamID())then
							steam.matchmaking.setLobbyData(lobby_code, tostring(steam.user.getSteamID()).."_spectator", spectating and "false" or "true")
						else
							steam.matchmaking.sendLobbyChatMsg(lobby_code, "spectate")
						end
					end
				end
				

				GuiText(menu_gui, 0, -6, " ")


				if(owner == steam.user.getSteamID())then

					local start_string = GameTextGetTranslatedOrNot("$mp_start_game")
					if(steam.matchmaking.getLobbyData(lobby_code, "in_progress") == "true")then
						start_string = GameTextGetTranslatedOrNot("$mp_restart_game")
					end

					if(GuiButton(menu_gui, NewID("lobby_start_button"), 0, 0, start_string ))then
						gui_closed = not gui_closed
						invite_menu_open = false
						if(steam.matchmaking.getLobbyData(lobby_code, "in_progress") == "true")then
							steam.matchmaking.sendLobbyChatMsg(lobby_code, "restart")
						else
							steam.matchmaking.sendLobbyChatMsg(lobby_code, "start")
						end
						steam.matchmaking.setLobbyData(lobby_code, "in_progress", "true")
					end
				end

				spectating = steamutils.IsSpectator(lobby_code)

				--print(tostring(spectating))

				local lobby_in_progress = steam.matchmaking.getLobbyData(lobby_code, "in_progress") == "true"
				if(lobby_in_progress and not in_game)then
					if GuiButton(menu_gui, NewID("lobby_enter_button"), 0, 0, GameTextGetTranslatedOrNot("$mp_enter_game")) then
						
						local active_mode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))

						mp_log:print("Attempting to load into gamemode: "..(active_mode and active_mode.name or "UNKNOWN"))

						if(active_mode)then

							in_game = true
							game_in_progress = true
							
							gui_closed = true

							mp_log:print("Attempting to start gamemode")
							if(spectating)then
								mp_log:print("Checking if gamemode has spectate function")
								if(active_mode.spectate ~= nil)then
									mp_log:print("Starting gamemode in spectator mode")
									active_mode.spectate(lobby_code, true)
								elseif(active_mode.start ~= nil)then
									mp_log:print("Starting gamemode")
									active_mode.start(lobby_code, true)
								end
							else
								mp_log:print("Checking if gamemode has start function")
								if(active_mode.start ~= nil)then
									mp_log:print("Starting gamemode")
									active_mode.start(lobby_code, true)
								end
							end


						end
					end
				end


				GuiText(menu_gui, 2, 0, "--------------------")
				local players = steam_utils.getLobbyMembers(lobby_code, true)
	
				for k, v in pairs(players) do
					GuiLayoutBeginHorizontal(menu_gui, 0, 0, true, 0, 0)
	
					if(v.id ~= steam.user.getSteamID() and owner == steam.user.getSteamID())then
						if(GuiButton(menu_gui, NewID("lobby_player"), 2, 0, GameTextGetTranslatedOrNot("$mp_kick")))then
							steam.matchmaking.kickUserFromLobby(lobby_code, v.id, GameTextGetTranslatedOrNot("$mp_kick_notification"))
						end
						if(GuiButton(menu_gui, NewID("lobby_player"), 0, 0, GameTextGetTranslatedOrNot("$mp_ban")))then
							steam.matchmaking.kickUserFromLobby(lobby_code, v.id, GameTextGetTranslatedOrNot("$mp_ban_notification"))	
							steam.matchmaking.setLobbyData(lobby_code, "banned_"..tostring(v.id), "true")
							banned_members[tostring(v.id)] = true
						end
						if(GuiButton(menu_gui, NewID("lobby_player"), 0, 0, GameTextGetTranslatedOrNot("$mp_owner")))then
							steam.matchmaking.setLobbyOwner(lobby_code, v.id)
							banned_members = {}
						end
					end
					
					if(v.id == owner)then
						GuiImage(menu_gui, NewID("lobby_player"), 2, -3, "mods/evaisa.mp/files/gfx/ui/crown.png", 1, 1, 1, 0)
						--selected_player
						if(selected_player == v.id)then
							GuiColorSetForNextWidget( menu_gui, 1, 1, 0.2, 1 )
						else
							GuiColorSetForNextWidget( menu_gui, 1, 1, 1, 1 )
						end
						if(GuiButton(menu_gui, NewID("lobby_player"), -5, 0, tostring(v.name)))then
							lobby_presets_open = false
							active_custom_menu = nil
							if(selected_player == v.id)then
								selected_player = nil
							else
								selected_player = v.id
							end
						end
					else
						if(selected_player == v.id)then
							GuiColorSetForNextWidget( menu_gui, 1, 1, 0.2, 1 )
						else
							GuiColorSetForNextWidget( menu_gui, 1, 1, 1, 1 )
						end

						if(GuiButton(menu_gui, NewID("lobby_player"), 2, 0, tostring(v.name)))then
							lobby_presets_open = false
							active_custom_menu = nil
							if(selected_player == v.id)then
								selected_player = nil
							else
								selected_player = v.id
							end
						end
					end

					--[[
					local player_mod_data = getLobbyUserData(lobby_code, v.id) or {}

					CustomTooltip(menu_gui, function() 
						for k, v in pairs(player_mod_data) do
							GuiColorSetForNextWidget( menu_gui, 1, 1, 1, 0.8 )
							GuiZSetForNextWidget(menu_gui, -5110)
							GuiText(menu_gui, 0, 0, v.name .. " ( "..v.id.." )")
						end
					end, -5100, 0, 0)
					]]
	
					GuiLayoutEnd(menu_gui)

					--GuiLayoutEnd(menu_gui)
					GuiText(menu_gui, 0, -6, " ")
				end
	
				--[[
				for i = 1, 40 do
					GuiText(menu_gui, 2, 0, " ")
				end
				]]

				GuiLayoutEnd(menu_gui)
			end, function() 
				gui_closed = true; 
				invite_menu_open = false 
			end, "lobby_gui")
		
			if(invite_menu_open)then

				friendfilters_ingame = friendfilters_ingame or false
				friendfilters_inlobby = friendfilters_inlobby or false
				friendfilters_offline = friendfilters_offline or false
				friendfilters_busy = friendfilters_busy or false
				friendfilters_away = friendfilters_away or false

				friends_cache = friends_cache or {
					friends = nil,
					state = {},
					game_info = {},
				}

				DrawWindow(menu_gui, -5500 ,(((screen_width / 2) - (window_width / 2))) - (150 / 2) - 18, screen_height / 2, 150, window_height, "Friends", true, function()
					local do_update = GameGetFrameNum() % 60 == 0
					
					GuiLayoutBeginVertical(menu_gui, 0, 0, true, 0, 0)

					if(do_update or friends_cache.friends == nil)then
						friends_cache.friends = steamutils.getSteamFriends();
						friends_cache.state = {}
						friends_cache.game_info = {}
					end

					local friends = friends_cache.friends

					local only_ingame = GameTextGetTranslatedOrNot("$mp_invite_only_ingame")
					if(GuiButton(menu_gui, NewID("Invite"), 0, 0, friendfilters_ingame and "[X] "..only_ingame or "[ ] "..only_ingame))then
						friendfilters_ingame = not friendfilters_ingame
					end

					local show_in_lobby = GameTextGetTranslatedOrNot("$mp_invite_in_lobby")
					if(GuiButton(menu_gui, NewID("Invite"), 0, 0, friendfilters_inlobby and "[X] "..show_in_lobby or "[ ] "..show_in_lobby))then
						friendfilters_inlobby = not friendfilters_inlobby
					end

					local show_offline = GameTextGetTranslatedOrNot("$mp_invite_offline")
					if(GuiButton(menu_gui, NewID("Invite"), 0, 0, friendfilters_offline and "[X] "..show_offline or "[ ] "..show_offline))then
						friendfilters_offline = not friendfilters_offline
					end

					local show_busy = GameTextGetTranslatedOrNot("$mp_invite_busy")
					if(GuiButton(menu_gui, NewID("Invite"), 0, 0, friendfilters_busy and "[X] "..show_busy or "[ ] "..show_busy))then
						friendfilters_busy = not friendfilters_busy
					end

					local show_away = GameTextGetTranslatedOrNot("$mp_invite_away")
					if(GuiButton(menu_gui, NewID("Invite"), 0, 0, friendfilters_away and "[X] "..show_away or "[ ] "..show_away))then
						friendfilters_away = not friendfilters_away
					end

					GuiText(menu_gui, 2, 0, "--------------------")

					for k, v in pairs(friends)do
						local state = friends_cache.state[v.id] or steam.friends.getFriendPersonaState(v.id)
						local game_info = friends_cache.game_info[v.id] or steam.friends.getFriendGamePlayed(v.id)

						--[[
						local state = steam.friends.getFriendPersonaState(v.id)
						local game_info = steam.friends.getFriendGamePlayed(v.id)
						]]

						local online_filter_pass = state == 1 or (state == 0 and friendfilters_offline) or (state == 2 and friendfilters_busy) or (state == 3 and friendfilters_away) or (state == 4 and friendfilters_away)

						local ingame_filter_pass = (not game_info and not friendfilters_ingame) or (game_info and game_info.gameID ~= game_id and not friendfilters_ingame ) or (game_info and game_info.gameID == game_id)

						local inlobby_filter_pass = (not game_info) or (game_info and game_info.gameID ~= game_id) or (game_info and game_info.gameID == game_id and tostring(game_info.lobbyID) ~= "0" and friendfilters_inlobby) or (game_info and game_info.gameID == game_id and tostring(game_info.lobbyID) == "0")


						if(online_filter_pass and ingame_filter_pass and inlobby_filter_pass)then
							GuiLayoutBeginHorizontal(menu_gui, 0, 0, true, 0, 0)
							if(GuiButton(menu_gui, NewID("Invite"), 0, 0, GameTextGetTranslatedOrNot("$mp_invite").." "))then
								if(lobby_code ~= nil)then
									if(steam.matchmaking.inviteUserToLobby(lobby_code, v.id))then
										mp_log:print("Invited "..v.name.." to lobby")
									else
										mp_log:print("Failed to invite "..v.name.." to lobby")
									end
								end
							end
							GuiText(menu_gui, 2, 0, v.name)
							GuiLayoutEnd(menu_gui)
						end
					end

					for i = 1, 40 do
						--[[
						GuiText(menu_gui, 2, 0, " ")
						]]
					end
		
					GuiLayoutEnd(menu_gui)
				end, nil, "invite_gui")	
		
			end

			if(selected_player ~= nil)then
				local selected_player_name = steamutils.getTranslatedPersonaName(selected_player)

				DrawWindow(menu_gui, -5500 ,(((screen_width / 2) - (window_width / 2))) + 293, screen_height / 2, 150, window_height, GameTextGetTranslatedOrNot("$mp_mods").." ("..selected_player_name..")", true, function()
					GuiLayoutBeginVertical(menu_gui, 0, 0, true, 0, 0)
					
					local player_mod_data = getLobbyUserData(lobby_code, selected_player) or {}

					local mod_count = 0
					
					-- Define a Lua function to sanitize a URL input
					function sanitize_url(url)
						-- Initialize an empty string to store the sanitized URL
						local sanitized_url = ""

						-- Check if the URL starts with "https://"
						if url:sub(1, 8) ~= "https://" then
							-- Inform user if the URL is not allowed
							mp_log:print("Invalid input URL: '"..url.."', Must start with 'https://'.")
							-- Return empty string
							return sanitized_url
						end

						-- Add "https://" to the sanitized URL
						sanitized_url = "https://"

						-- Iterate over each character in the input URL (starting from position 9, after "https://")
						for i = 9, #url do
							-- Extract the current character
							local char = url:sub(i, i)

							-- Check if the character is part of the whitelist (i.e., only alphanumeric, dash, underscore, period, colon, slash,
							-- question mark, equal sign, plus sign, ampersand, or percent sign)
							if char:match("[%w%-%_%.%:%/%?%=%+&%%]") then
								-- If the character is part of the whitelist, append it to the sanitized URL
								sanitized_url = sanitized_url .. char
							end
						end

						mp_log:print("Sanitized URL: " .. sanitized_url)

						-- Return the sanitized URL
						return sanitized_url
					end
										
	

					for k, v in pairs(player_mod_data) do
						local description_truncated = v.description

						-- remove anything after a /n (newline)
						local newline_pos = string.find(description_truncated, "\\n")
						if(newline_pos ~= nil)then
							description_truncated = description_truncated:sub(1, newline_pos - 1)
						end
						if(#description_truncated > 100)then
							description_truncated = description_truncated:sub(1, 100) .. "..."
						end

						GuiColorSetForNextWidget( menu_gui, 1, 1, 1, 0.8 )
						GuiZSetForNextWidget(menu_gui, -5510)
						--GamePrint(tostring(v.workshop_item_id))
						--GuiLayoutBeginHorizontal(menu_gui, 0, 0, true)

						if(v.workshop_item_id ~= 0 and v.workshop_item_id ~= "0")then
							if(GuiButton(menu_gui, NewID("mod_list"), 0, 0, v.name .. (v.id ~= nil and " ( "..v.id.." )" or "")))then
								--steam.utils.openWorkshopItem(v.workshop_item_id)
								popup.create("open_steam_url", v.name, GameTextGetTranslatedOrNot("$mp_open_steam_url_warning"), {
									{
										text="Yes", 
										callback = function() 
											os.execute("start steam://openurl/https://steamcommunity.com/sharedfiles/filedetails/?id="..v.workshop_item_id)
										end
									},
									{
										text="No", 
										callback = function() 
										end
									}
								}, -20000)

							end
							GuiTooltip(menu_gui, GameTextGetTranslatedOrNot("$mp_open_steam_url_tooltip"), description_truncated)
						elseif(v.download_link ~= nil and v.download_link ~= "")then
							if(GuiButton(menu_gui, NewID("mod_list"), 0, 0, v.name .. (v.id ~= nil and " ( "..v.id.." )" or "")))then
								--os.execute("start "..v.workshop_item_id)
								local url = sanitize_url(v.download_link)
								

								popup.create("open_mod_download_page", v.name, string.format(GameTextGetTranslatedOrNot("$mp_open_download_page_warning"), "\""..url.."\""), {
									{
										text="Yes", 
										callback = function() 
											os.execute("start explorer \""..url.."\"")
										end
									},
									{
										text="No", 
										callback = function() 
										end
									}
								}, -20000)

							end
							GuiTooltip(menu_gui, GameTextGetTranslatedOrNot("$mp_open_download_page_tooltip"),  description_truncated)
						else	
							GuiText(menu_gui, 0, 0, v.name .. (v.id ~= nil and " ( "..v.id.." )" or ""))
							GuiTooltip(menu_gui,  description_truncated, "")
						end

						local mod_required = (steam.matchmaking.getLobbyData(lobby_code, "mod_required_"..v.id) == "true") or false

						local required_text = mod_required and GameTextGetTranslatedOrNot("$mp_required") or GameTextGetTranslatedOrNot("$mp_not_required")

						GuiZSetForNextWidget(menu_gui, -5510)

						if(mod_required)then
							GuiColorSetForNextWidget( menu_gui, 1, 0.129, 0, 0.8 )
						else
							GuiColorSetForNextWidget( menu_gui, 0.314, 1, 0, 0.8 )
						end

						if(steamutils.IsOwner(lobby_code))then
							if(GuiButton(menu_gui, NewID("mod_list"), 0, 0, required_text))then
								steam.matchmaking.setLobbyData(lobby_code, "mod_required_"..v.id, tostring(not mod_required))
								if(not mod_required)then
									local required_mods = (steam.matchmaking.getLobbyData(lobby_code, "required_mods") ~= nil and steam.matchmaking.getLobbyData(lobby_code, "required_mods") ~= "") and bitser.loads(steam.matchmaking.getLobbyData(lobby_code, "required_mods")) or {}
								
									table.insert(required_mods, {v.id, v.name})

									steam.matchmaking.setLobbyData(lobby_code, "required_mods", bitser.dumps(required_mods))
								else
									local required_mods = (steam.matchmaking.getLobbyData(lobby_code, "required_mods") ~= nil and steam.matchmaking.getLobbyData(lobby_code, "required_mods") ~= "") and bitser.loads(steam.matchmaking.getLobbyData(lobby_code, "required_mods")) or {}
								
									for i, mod in ipairs(required_mods) do
										if(mod.id == v.id)then
											table.remove(required_mods, i)
											break
										end
									end

									steam.matchmaking.setLobbyData(lobby_code, "required_mods", bitser.dumps(required_mods))
								end
							end
						else
							GuiText(menu_gui, 0, 0, required_text)
						end


						GuiText(menu_gui, 0, -8, " ")

						mod_count = mod_count + 1
					end
					--GuiLayoutEnd(menu_gui)
					
					--[[
					for i = 1, 50 - mod_count do
						GuiText(menu_gui, 2, 0, " ")
					end
					]]
		
					GuiLayoutEnd(menu_gui)
				end, nil, "mod_list_gui")	
		
			end

			if(lobby_presets_open)then
				local active_mode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))

				if(active_mode ~= nil)then
					local presets_folder_name = os.getenv('APPDATA'):gsub("\\Roaming", "") .. "\\LocalLow\\Nolla_Games_Noita\\save00\\evaisa.mp_presets"
					local gamemode_preset_folder_name = presets_folder_name .. "\\"..active_mode.id
					presets = presets or {}
					reserved_preset_names = reserved_preset_names or {}

					local preset_version = 2
					local function GenerateDefaultPreset()
						local default_name = GameTextGetTranslatedOrNot("$mp_default_preset_name")
						local preset_data = {version = preset_version, settings = {}}
						for k, v in ipairs(active_mode.settings)do
							preset_data.settings[v.id] = v.default
						end
						reserved_preset_names[default_name] = true
						table.insert(presets, 1, {name=default_name, data=preset_data})
					end

					local function AddGamemodePresets()
						if(active_mode.default_presets ~= nil)then
							for name, data in pairs(active_mode.default_presets)do
								reserved_preset_names[name] = true
								table.insert(presets, 1, {name=name, data=data})
							end
						end
					end

					local function RefreshPresets()
						-- create folder if doesn't exist
						if not os.rename(presets_folder_name, presets_folder_name) then
							os.execute("mkdir \"" .. presets_folder_name .. "\"")
						end
						
						if not os.rename(gamemode_preset_folder_name, gamemode_preset_folder_name) then
							os.execute("mkdir \"" .. gamemode_preset_folder_name .. "\"")
						end

						presets = {}

						-- loop through files in folder, without luafilesystem
						local pfile = io.popen([[dir "]] .. gamemode_preset_folder_name .. [[" /b]])
						for filename in pfile:lines() do

							-- if filename ends in .mp_preset
							if(filename:sub(-10) == ".mp_preset")then
								local preset_data = {}
								local file = io.open(gamemode_preset_folder_name .. "\\" .. filename, "r")
								if(file ~= nil)then
									local data = file:read("*all")
									file:close()
									filename = filename:gsub(".mp_preset", "")
									local valid, preset_data = pcall(bitser.loads, data)
									if(valid and preset_data ~= nil)then
										table.insert(presets, {name = filename, data = preset_data})
									else
										table.insert(presets, {name = filename,	corrupt = true, data = {
											version = preset_version,
											settings = {}
										}})
									end
								end
							end
						end

						AddGamemodePresets()
						GenerateDefaultPreset()
					end

					local function SavePreset(name)
						if(not reserved_preset_names[name])then

							local settings_data = {version = preset_version, settings = gamemode_settings}

							if(active_mode.save_preset)then
								settings_data = active_mode.save_preset(lobby_code, settings_data)
							end

							local serialized_data = bitser.dumps(settings_data)
							print(json.stringify(settings_data))
							local file = io.open(gamemode_preset_folder_name .. "\\" .. name .. ".mp_preset", "w")
							if(file ~= nil)then
								file:write(serialized_data)
								file:close()
							end
						else
							print("Preset name is reserved")
							GamePrint("Preset name is reserved")
						end
					end

					local function RemovePreset(name)
						if(name ~= " " and name ~= "_" and #name > 0)then
							os.remove(gamemode_preset_folder_name .. "\\" .. name .. ".mp_preset")
						end
					end

					if(not was_lobby_presets_open)then
						RefreshPresets()
					end

					DrawWindow(menu_gui, -5500 ,(((screen_width / 2) - (window_width / 2))) + 293, screen_height / 2, 150, window_height, GameTextGetTranslatedOrNot("$mp_lobby_presets"), true, function()
						GuiLayoutBeginVertical(menu_gui, 0, 0, true, 0, 0)

						preset_name = preset_name or ("Preset_"..tostring(Random(1, 1000000)))
						GuiLayoutBeginHorizontal(menu_gui, 0, 0)
						GuiText(menu_gui, 0, 0, GameTextGetTranslatedOrNot("$mp_preset_name"))
						preset_name = GuiTextInput(menu_gui, NewID("save_preset_name"), 0, 0, preset_name, 90, 15, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_ ")
						local _, _, hover = GuiGetPreviousWidgetInfo(menu_gui)

						if(hover)then
							GameAddFlagRun("chat_bind_disabled")
						end

						
						GuiLayoutEnd(menu_gui)

						if(GuiButton(menu_gui, NewID("save_preset"), 0, 0, GameTextGetTranslatedOrNot("$mp_save_preset")))then
							if(preset_name ~= " " and preset_name ~= "_" and #preset_name > 0)then
								SavePreset(preset_name)
								RefreshPresets()
							end
						end

						if(GuiButton(menu_gui, NewID("open_presets_folder"), 0, 10, GameTextGetTranslatedOrNot("$mp_open_preset_folder")))then
							os.execute("start \"\" \"" .. gamemode_preset_folder_name .. "\"")
						end
						if(GuiButton(menu_gui, NewID("generate_preset_table"), 0, 10, "[Debug] Generate Preset Table"))then
							local table_string = "[\""..preset_name.."\"] = {\n"
							table_string = table_string .. "\t[\"version\"] = "..tostring(preset_version)..",\n"
							table_string = table_string .. "\t[\"settings\"] = {\n"
							for k, v in pairs(gamemode_settings)do
								local value = v
								--print("["..type(v).."] "..tostring(v))

								if(type(v) == "string")then
									value = "\"" .. v .. "\""
								end
								table_string = table_string .. "\t\t[\"" .. k .. "\"] = " .. tostring(value) .. ",\n"
							end
							table_string = table_string .. "\t},\n"
							table_string = table_string .. "}"
							steam.utils.setClipboard(table_string)
							print("Copied preset table to clipboard")
							GamePrint("Copied preset table to clipboard")
						end
						if(GuiButton(menu_gui, NewID("refresh_presets"), 0, 0, GameTextGetTranslatedOrNot("$mp_refresh_presets")))then
							RefreshPresets()
						end
						
						GuiText(menu_gui, 0, 0, "--------------------")
						
						for i, preset in ipairs(presets) do
							GuiLayoutBeginHorizontal(menu_gui, 0, 0)
							if(GuiButton(menu_gui, NewID("remove_preset_"..tostring(preset.name)), 0, 0, GameTextGetTranslatedOrNot("$mp_remove_preset")))then
								popup.create("delete_preset_prompt", string.format(GameTextGetTranslatedOrNot("$mp_delete_preset_confirm"), preset.name),{
									{
										text = GameTextGetTranslatedOrNot("$mp_delete_preset_confirm_description"),
										color = {214 / 255, 60 / 255, 60 / 255, 1}
									},
								}, {
									{
										text = GameTextGetTranslatedOrNot("$mp_delete_preset_confirm_delete"),
										callback = function()
											RemovePreset(preset.name)
											RefreshPresets()
										end
									},
									{
										text = GameTextGetTranslatedOrNot("$mp_delete_preset_confirm_cancel"),
										callback = function()
										end
									}
								}, -6000)
								
								--[[
								RemovePreset(preset.name)
								RefreshPresets()
								]]
							end
							if(GuiButton(menu_gui, NewID("load_preset_"..tostring(preset.name)), 0, 0, ((preset.corrupt and "[invalid]") or "") .. preset.name))then
								
								local preset_info = preset
								if(preset.data.version == nil or preset.data.version == 1)then
									preset_info = {
										outdated = true,
										name = preset.name,
										data = {
											version = preset.data.version or 1,
											settings = preset.data
										}
									}
								end

								


								gamemode_settings = preset_info.data.settings
								--print("loaded: "..json.stringify(gamemode_settings))
								preset_name = preset_info.name
								--settings_changed = true

								for k, setting in ipairs(active_mode.settings or {})do
									steam.matchmaking.setLobbyData(lobby_code, "setting_"..setting.id, tostring(gamemode_settings[setting.id]))
									mp_log:print("Updated gamemode setting: "..setting.id.." to "..tostring(gamemode_settings[setting.id]))
								end

								steam.matchmaking.sendLobbyChatMsg(lobby_code, "refresh")

								if(active_mode.load_preset)then
									active_mode.load_preset(lobby_code, preset_info.data)
								end
							end
							GuiLayoutEnd(menu_gui)
						end
						

						GuiLayoutEnd(menu_gui)
					end, nil, "lobby_presets_gui")	

				end
				was_lobby_presets_open = true
			else
				was_lobby_presets_open = false
			end

			if(active_custom_menu ~= nil)then
				local active_mode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))
				if(active_mode ~= nil and active_mode.lobby_menus ~= nil)then
					for i, lobby_menu in ipairs(active_mode.lobby_menus)do
						if(lobby_menu.id == active_custom_menu)then
							DrawWindow(menu_gui, -5500 ,(((screen_width / 2) - (window_width / 2))) + 293, screen_height / 2, 150, window_height, GameTextGetTranslatedOrNot(lobby_menu.name), true, function()
								get_widget_info = function()
									local clicked, right_clicked, hovered, x, y, width, height, draw_x, draw_y, draw_width, draw_height = GuiGetPreviousWidgetInfo(menu_gui)
									local window_y = ((screen_height / 2) - (window_height / 2)) + 12
									local window_height = window_height
									
									--[[GuiLayoutBeginLayer(menu_gui)
									GuiText(menu_gui, 0, window_y, "------------------")
									GuiText(menu_gui, 0, window_y + window_height, "------------------")
									GuiLayoutEndLayer(menu_gui)]]

									return (y > window_y and y < window_y + window_height), clicked, right_clicked, hovered, x, y, width, height, draw_x, draw_y, draw_width, draw_height
								end
								if(lobby_menu.draw)then
									lobby_menu.draw(lobby_code, menu_gui, function(id, force) return NewID(id or lobby_menu.id, force) end)
								end
							end, function() 
								active_custom_menu = nil
								lobby_menu.close() 
							end, lobby_menu.id)	
						end
					end
				end
			end

			if(lobby_settings_open)then
				
				local owner = steam.matchmaking.getLobbyOwner(lobby_code)

				local internal_types = { "Public", "Private", "FriendsOnly"}
				local internal_type_map = { Public = 1, Private = 2, FriendsOnly = 3 }


				edit_lobby_type = owner == steam.user.getSteamID() and (edit_lobby_type or 1) or internal_type_map[steam.matchmaking.getLobbyData(lobby_code, "LobbyType")]

				local active_mode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))
	
				local true_max = 32
	
				local default_max_players = 8

				edit_lobby_max_players = steam.user.getSteamID() and (edit_lobby_max_players or steam.matchmaking.getLobbyMemberLimit(lobby_code)) or steam.matchmaking.getLobbyMemberLimit(lobby_code)

				edit_lobby_name = owner == steam.user.getSteamID() and (edit_lobby_name or steam.matchmaking.getLobbyData(lobby_code, "name"))  or steam.matchmaking.getLobbyData(lobby_code, "name")

				edit_lobby_seed = owner == steam.user.getSteamID() and (edit_lobby_seed or steam.matchmaking.getLobbyData(lobby_code, "seed")) or steam.matchmaking.getLobbyData(lobby_code, "seed")

				DrawWindow(menu_gui, -5500 ,(((screen_width / 2) - (window_width / 2))) - (180 / 2) - 18, screen_height / 2, 180, window_height, GameTextGetTranslatedOrNot("$mp_lobby_settings"), true, function()
					GuiLayoutBeginVertical(menu_gui, 0, 0, true, 0, 0)
	


					if(GuiButton(menu_gui, NewID("EditLobby"), 2, 0, GameTextGetTranslatedOrNot("$mp_lobby_type")..": "..lobby_types[edit_lobby_type]))then
						edit_lobby_type = edit_lobby_type + 1
						if(edit_lobby_type > #lobby_types and owner == steam.user.getSteamID())then
							edit_lobby_type = 1
							settings_changed = true
						end
					end
	
					--print(tostring(edit_lobby_gamemode))

					--[[if(GuiButton(menu_gui, NewID("EditLobby"), 2, 1, "Gamemode: "..gamemodes[edit_lobby_gamemode].name))then
						edit_lobby_gamemode = edit_lobby_gamemode + 1
						if(#gamemodes > 1)then
							gamemode_settings = {}
						end
						if(edit_lobby_gamemode > #gamemodes and owner == steam.user.getSteamID())then
							edit_lobby_gamemode = 1
						end
					end]]
					
					GuiText(menu_gui, 2, 1, GameTextGetTranslatedOrNot("$mp_gamemode")..": "..GameTextGetTranslatedOrNot(active_mode.name))
					GuiTooltip(menu_gui, GameTextGetTranslatedOrNot("$mp_cannot_change_mode_in_lobby"), "")
	
					GuiLayoutBeginHorizontal(menu_gui, 0, 0, true, 0, 0)
					GuiText(menu_gui, 2, 1, GameTextGetTranslatedOrNot("$mp_lobby_name")..": ")
					name_change_frame = name_change_frame or nil
					local lobby_name_value = GuiTextInput(menu_gui, NewID("EditLobby"), 2, 1, edit_lobby_name, 120, 25, "qwertyuiopasdfghjklzxcvbnm1234567890QWERTYUIOPASDFGHJKLZXCVBNM!@#$%^&*()_' ")
					local _, _, hover = GuiGetPreviousWidgetInfo(menu_gui)
					if(hover)then
						GameAddFlagRun("chat_bind_disabled")
					end
					if(lobby_name_value ~= edit_lobby_name and owner == steam.user.getSteamID())then
						edit_lobby_name = lobby_name_value
						name_change_frame = GameGetFrameNum()
					end

					if(name_change_frame and GameGetFrameNum() - name_change_frame > 30)then
						settings_changed = true
						name_change_frame = nil
					end

					GuiLayoutEnd(menu_gui)
					
					GuiLayoutBeginHorizontal(menu_gui, 0, 0, true, 0, 0)
					GuiText(menu_gui, 2, 3, GameTextGetTranslatedOrNot("$mp_max_players")..": ")

					max_player_change_frame = max_player_change_frame or nil

					local slider_value = GuiSlider(menu_gui, NewID("EditLobby"), 0, 4, "", edit_lobby_max_players, 2, true_max, default_max_players, 1, " $0", 120)
					if(slider_value ~= edit_lobby_max_players and owner == steam.user.getSteamID())then
						edit_lobby_max_players = slider_value
						max_player_change_frame = GameGetFrameNum()
					end

					if(max_player_change_frame and GameGetFrameNum() - max_player_change_frame > 30)then
						settings_changed = true
						max_player_change_frame = nil
					end

					GuiLayoutEnd(menu_gui)

					GuiLayoutBeginHorizontal(menu_gui, 0, 0, true, 0, 0)
					GuiText(menu_gui, 2, 4, GameTextGetTranslatedOrNot("$mp_world_seed")..": ")
					
					seed_change_frame = seed_change_frame or nil
					
					local edit_lobby_seed_value = GuiTextInput(menu_gui, NewID("EditLobby"), 2, 4, edit_lobby_seed, 120, 10, "1234567890")
					local _, _, hover = GuiGetPreviousWidgetInfo(menu_gui)
					if(hover)then
						GameAddFlagRun("chat_bind_disabled")
					end
					if(edit_lobby_seed_value ~= edit_lobby_seed and owner == steam.user.getSteamID())then
						edit_lobby_seed = edit_lobby_seed_value
						seed_change_frame = GameGetFrameNum()
					end

					if(seed_change_frame and GameGetFrameNum() - seed_change_frame > 30)then
						settings_changed = true
						seed_change_frame = nil
					end

					GuiLayoutEnd(menu_gui)

					local previous_type = "text_input"
					
					local global_offset = 1

					local extra_offset = 5
					if(active_mode.settings and #active_mode.settings > 0 and active_mode.settings[1].type == "slider")then
						extra_offset = 7
					end

					GuiLayoutBeginVertical(menu_gui, 0, extra_offset, true, 0, 0)


					--print("displaying: "..json.stringify(gamemode_settings))
					for k, setting in ipairs(active_mode.settings or {})do

						if(owner ~= steam.user.getSteamID())then
							gamemode_settings[setting.id] = steam.matchmaking.getLobbyData(lobby_code, "setting_"..setting.id)
						end

						if(gamemode_settings[setting.id] == nil)then
							gamemode_settings[setting.id] = setting.default
							--settings_changed = true
							--GlobalsSetValue("setting_next_"..setting.id, tostring(setting.default))
						else
							if(setting.type == "bool" and type(gamemode_settings[setting.id]) == "string")then
								if(gamemode_settings[setting.id] == "true")then
									gamemode_settings[setting.id] = true
								else
									gamemode_settings[setting.id] = false
								end
							elseif(setting.type == "slider" and type(gamemode_settings[setting.id]) == "string")then
								gamemode_settings[setting.id] = tonumber(gamemode_settings[setting.id])
							end
						end

						if(gamemode_settings[setting.id] ~= nil)then
							local setting_next = GlobalsGetValue("setting_next_"..setting.id)
							if(setting_next ~= nil)then
								if(setting_next ~= tostring(gamemode_settings[setting.id]))then
									GlobalsSetValue("setting_next_"..setting.id, tostring(gamemode_settings[setting.id]))
								end
							end
						end


						if(setting.require == nil or setting.require(setting))then
							--print(setting.id.."; "..tostring(setting.require).."; "..(setting.require and tostring(setting.require(setting)) or "nil"))
							if(setting.type == "enum")then
								local selected_name = ""
								local selected_index = nil

								local selected_value = gamemode_settings[setting.id]
								--print("Selected value: "..tostring(selected_value))
								if(selected_value == nil)then
									selected_value = setting.default
									gamemode_settings[setting.id] = setting.default
									settings_changed = true
								end
								
								for k, v in ipairs(setting.options)do
									if(v[1] == selected_value)then
										selected_name = v[2]
										selected_index = k
									end
								end

								-- if selected index is nil, reset to default
								if(selected_index == nil)then
									for k, v in ipairs(setting.options)do
										if(v[1] == setting.default)then
											selected_name = v[2]
											selected_index = k
											settings_changed = true
											gamemode_settings[setting.id] = setting.default
										end
									end
								end


								local offset = global_offset

								--[[if(previous_type == "text_input")then
									offset = 5
								end]]

								--[[if(previous_type == "slider")then
									offset = offset + 1
								elseif(previous_type == "enum" or previous_type == "bool")then
									offset = offset - 4
								end   ]]      

								if(GuiButton(menu_gui, NewID("EditLobby"), 2, offset, GameTextGetTranslatedOrNot(setting.name)..": "..GameTextGetTranslatedOrNot(selected_name)))then
									selected_index = selected_index + 1
									if(selected_index > #setting.options)then
										selected_index = 1
									end
									gamemode_settings[setting.id] = setting.options[selected_index][1]
									settings_changed = true
									--GlobalsSetValue("setting_next_"..setting.id, tostring(setting.options[selected_index][1]))
								end
								GuiTooltip(menu_gui, "", GameTextGetTranslatedOrNot(setting.description))

								previous_type = "enum"
								
							elseif(setting.type == "bool")then

								local offset = global_offset

								--[[if(previous_type == "text_input")then
									offset = 5
								end]]
								--[[if(previous_type == "slider")then
									offset = offset + 1
								elseif(previous_type == "enum" or previous_type == "bool")then
									offset = offset - 4
								end   ]]      

								if(GuiButton(menu_gui, NewID("EditLobby"), 2, offset, GameTextGetTranslatedOrNot(setting.name)..": "..(gamemode_settings[setting.id] and GameTextGetTranslatedOrNot("$mp_setting_enabled") or GameTextGetTranslatedOrNot("$mp_setting_disabled"))))then
									gamemode_settings[setting.id] = not gamemode_settings[setting.id]
									settings_changed = true
									--print(tostring(gamemode_settings[setting.id]))
									--GlobalsSetValue("setting_next_"..setting.id, tostring(gamemode_settings[setting.id]))
								end
								GuiTooltip(menu_gui, "", GameTextGetTranslatedOrNot(setting.description))

								previous_type = "bool"
							elseif(setting.type == "slider")then
								local offset = global_offset
					
								GuiLayoutBeginHorizontal(menu_gui, 0, offset, true, 0, 0)

								local text_width, text_height = GuiGetTextDimensions(menu_gui, GameTextGetTranslatedOrNot(setting.name)..": ")

								GuiText(menu_gui, 2, -1, GameTextGetTranslatedOrNot(setting.name)..": ")
								GuiTooltip(menu_gui, "", GameTextGetTranslatedOrNot(setting.description))

								local container_size = setting.width or 100

								if(container_size + text_width > 150)then
									container_size = 150 - text_width
								end

								setting.display_multiplier = setting.display_multiplier or 1
								setting.formatting_string = setting.formatting_string or " $0"
								setting.formatting_func = setting.formatting_func or function(value) return value end
								setting.modifier = setting.modifier

								if(setting.modifier == nil)then
									setting.modifier = function(value) return value end
								end
								setting.display_fractions = setting.display_fractions or false

								--GuiLayoutBeginHorizontal(menu_gui, 0, offset, true, 1, 1)
								local slider_value = GuiSlider(menu_gui, NewID("EditLobby"), 0, 0, "", gamemode_settings[setting.id], setting.min, setting.max, setting.default, setting.display_multiplier, " ", container_size)
								slider_value = setting.modifier(slider_value)
								local clicked, _, hovered = GuiGetPreviousWidgetInfo(menu_gui)
								-- take setting.formatting_string, replace $0 with slider_value, take display multiplier into account
								GuiColorSetForNextWidget(menu_gui, 1, 1, 1, 0.7)
								local value_text = string.gsub(setting.formatting_string, "$0", tostring(setting.display_fractions and (slider_value * setting.display_multiplier) or math.floor(slider_value * setting.display_multiplier)))
								value_text = setting.formatting_func(value_text)
								GuiText(menu_gui, 0, 0, value_text)
								--GuiLayoutEnd(menu_gui)

								was_slider_changed = was_slider_changed or {}

								if(tostring(slider_value) ~= tostring(gamemode_settings[setting.id]))then
		
									gamemode_settings[setting.id] = slider_value
									was_slider_changed[setting.id] = GameGetFrameNum()
								end

								if(was_slider_changed[setting.id] and (GameGetFrameNum() - was_slider_changed[setting.id]) > 30)then
								
									settings_changed = true
									was_slider_changed[setting.id] = nil
	
									--GlobalsSetValue("setting_next_"..setting.id, tostring(gamemode_settings[setting.id]))
								end
			

								GuiLayoutEnd(menu_gui)

								previous_type = "slider"
							end
						end
					end

					GuiLayoutEnd(menu_gui)
					--GuiText(menu_gui, 2, 6, "--------------------")

					if(--[[GuiButton(menu_gui, NewID("EditLobby"), 2, 0, GameTextGetTranslatedOrNot("$mp_update_settings"))]] settings_changed and owner == steam.user.getSteamID())then
						steam.matchmaking.setLobbyMemberLimit(lobby_code, edit_lobby_max_players)
						steam.matchmaking.setLobbyData(lobby_code, "name", edit_lobby_name)
						steam.matchmaking.setLobbyData(lobby_code, "seed", edit_lobby_seed)
						for k, setting in ipairs(active_mode.settings or {})do
							steam.matchmaking.setLobbyData(lobby_code, "setting_"..setting.id, tostring(gamemode_settings[setting.id]))
							mp_log:print("Updated gamemode setting: "..setting.id.." to "..tostring(gamemode_settings[setting.id]))
						end
						steam.matchmaking.setLobbyType(lobby_code, internal_types[edit_lobby_type])
						steam.matchmaking.sendLobbyChatMsg(lobby_code, "refresh")
						mp_log:print("Updated limit: "..tostring(edit_lobby_max_players))
						mp_log:print("Updated name: "..tostring(edit_lobby_name))
						mp_log:print("Updated type: "..tostring(internal_types[edit_lobby_type]))
						settings_changed = false
						--print("lobby settings changed!")
					end

					GuiText(menu_gui, 2, 0, " ")

					--[[
					for i = 1, 40 do
						GuiText(menu_gui, 2, 0, " ")
					end
					]]
		

					GuiLayoutEnd(menu_gui)
				end, nil, "lobby_settings_gui")	
			
			end
		end
	},
	{
		name = "CreateLobby",
		func = function()


			local window_width = 200
			local window_height = 180
		
			local window_text = GameTextGetTranslatedOrNot("$mp_create_lobby")

			lobby_type = lobby_type or 1
			gamemode_index = gamemode_index or 1

			local true_max = 32

			local default_max_players = 8

			lobby_max_players = lobby_max_players or default_max_players

			local default_lobby_name = steamutils.getTranslatedPersonaName()

			-- if default lobby name ends with "s" add ' otherwise add 's

			if(string.sub(default_lobby_name, -1) == "s")then
				default_lobby_name = string.format(GameTextGetTranslatedOrNot("$mp_default_lobby_name_s"), default_lobby_name)
			else
				default_lobby_name = string.format(GameTextGetTranslatedOrNot("$mp_default_lobby_name"), default_lobby_name)
			end

			lobby_name = lobby_name or default_lobby_name
			lobby_seed = lobby_seed or tostring(rand.range(1, 4294967295))

			DrawWindow(menu_gui, -6000, screen_width / 2, screen_height / 2, window_width, window_height, window_text, true, function()
				GuiLayoutBeginVertical(menu_gui, 0, 0, true, 0, 0)

				if(GuiButton(menu_gui, NewID("CreateLobby"), 0, 0, GameTextGetTranslatedOrNot("$mp_return_menu")))then
					if(lobby_code ~= nil)then
						steam.matchmaking.leaveLobby(lobby_code)
						lobby_code = nil
					end
					invite_menu_open = false
					selected_player = nil
					menu_status = status.main_menu
					initial_refreshes = 10
					return
				end

				GuiText(menu_gui, 2, 0, "--------------------")
				GuiText(menu_gui, 2, 0, " ")


				if(#gamemodes > 0)then

					local internal_types = { "Public", "Private", "FriendsOnly",}

					if(GuiButton(menu_gui, NewID("CreateLobby"), 2, 0, GameTextGetTranslatedOrNot("$mp_lobby_type")..": "..lobby_types[lobby_type]))then
						lobby_type = lobby_type + 1
						if(lobby_type > #lobby_types)then
							lobby_type = 1
						end
					end


					if(GuiButton(menu_gui, NewID("CreateLobby"), 2, 1, GameTextGetTranslatedOrNot("$mp_gamemode")..": "..GameTextGetTranslatedOrNot(gamemodes[gamemode_index].name)))then
						gamemode_index = gamemode_index + 1
						if(gamemode_index > #gamemodes)then
							gamemode_index = 1
						end
					end

					GuiLayoutBeginHorizontal(menu_gui, 0, 0, true, 0, 0)
					GuiText(menu_gui, 2, 1, GameTextGetTranslatedOrNot("$mp_lobby_name")..": ")
					local lobby_name_value = GuiTextInput(menu_gui, NewID("CreateLobby"), 2, 1, lobby_name, 120, 25, "qwertyuiopasdfghjklzxcvbnm1234567890QWERTYUIOPASDFGHJKLZXCVBNM!@#$%^&*()_' ")
					if(lobby_name_value ~= lobby_name)then
						lobby_name = lobby_name_value
					end
					GuiLayoutEnd(menu_gui)
					
					GuiLayoutBeginHorizontal(menu_gui, 0, 0, true, 0, 0)
					GuiText(menu_gui, 2, 3, GameTextGetTranslatedOrNot("$mp_max_players")..": ")
					local slider_value = GuiSlider(menu_gui, NewID("CreateLobby"), 0, 4, "", lobby_max_players, 2, true_max, default_max_players, 1, " $0", 120)
					if(slider_value ~= lobby_max_players)then
						lobby_max_players = slider_value
					end
					GuiLayoutEnd(menu_gui)

					GuiLayoutBeginHorizontal(menu_gui, 0, 0, true, 0, 0)
					GuiText(menu_gui, 2, 4, GameTextGetTranslatedOrNot("$mp_world_seed")..": ")
					local lobby_seed_value = GuiTextInput(menu_gui, NewID("CreateLobby"), 2, 4, lobby_seed, 120, 10, "1234567890")
					if(lobby_seed_value ~= lobby_seed)then
						lobby_seed = lobby_seed_value
					end
					GuiLayoutEnd(menu_gui)

					GuiText(menu_gui, 2, 0, " ")

					if(GuiButton(menu_gui, NewID("CreateLobby"), 2, 0, GameTextGetTranslatedOrNot("$mp_create_lobby")))then
						CreateLobby(internal_types[lobby_type], lobby_max_players, function (code) 
							msg.log("Created new lobby!")
							
							for k, setting in ipairs(gamemodes[gamemode_index].settings or {})do
								if(gamemode_settings[setting.id] == nil)then
									gamemode_settings[setting.id] = setting.default

									steam.matchmaking.setLobbyData(code, "setting_"..setting.id, tostring(setting.default))
								end
							end

							for k, data in pairs(gamemodes[gamemode_index].default_data or {})do
								steam.matchmaking.setLobbyData(code, k, data)
							end

							steam.matchmaking.setLobbyData(code, "name", lobby_name)
							steam.matchmaking.setLobbyData(code, "gamemode", tostring(gamemodes[gamemode_index].id))
							steam.matchmaking.setLobbyData(code, "gamemode_version", tostring(gamemodes[gamemode_index].version))
							steam.matchmaking.setLobbyData(code, "gamemode_name", tostring(gamemodes[gamemode_index].name))
							steam.matchmaking.setLobbyData(code, "seed", lobby_seed)
							steam.matchmaking.setLobbyData(code, "version", tostring(MP_VERSION))
							steam.matchmaking.setLobbyData(code, "in_progress", "false")
							steam.matchmaking.setLobbyData(code, "allow_in_progress_joining", gamemodes[gamemode_index].allow_in_progress_joining ~= nil and tostring(gamemodes[gamemode_index].allow_in_progress_joining)  or "true")

							if(dev_mode)then
								steam.matchmaking.setLobbyData(code, "System", "NoitaOnlineDev")
							end


							steam.friends.setRichPresence( "status", "Noita Arena - Waiting for players" )

							lobby_code = code
						end)
					end
				else
					GuiText(menu_gui, 2, 0, GameTextGetTranslatedOrNot("$mp_no_gamemodes"))
				end

				--[[
				for i = 1, 40 do
					GuiText(menu_gui, 2, 0, " ")
				end
				]]

				GuiLayoutEnd(menu_gui)
			end, function() 
				gui_closed = true; 
				invite_menu_open = false
				selected_player = nil 
			end, "create_lobby_gui")

		end
	},
	{
		name = "JoinLobby",
		func = function()


			local window_width = 200
			local window_height = 180
		
			local window_text = GameTextGetTranslatedOrNot("$mp_join_lobby")

			lobby_code_input = lobby_code_input or ""



			DrawWindow(menu_gui, -6000, screen_width / 2, screen_height / 2, window_width, window_height, window_text, true, function()
				GuiLayoutBeginVertical(menu_gui, 0, 0, true, 0, 0)

				if(GuiButton(menu_gui, NewID("JoinLobby"), 0, 0, GameTextGetTranslatedOrNot("$mp_return_menu")))then
					if(lobby_code ~= nil)then
						steam.matchmaking.leaveLobby(lobby_code)
						lobby_code = nil
					end
					invite_menu_open = false
					lobby_code_input = ""
					menu_status = status.main_menu
					initial_refreshes = 10
					return
				end

				GuiText(menu_gui, 2, 0, "--------------------")
				

				if(GuiButton(menu_gui, NewID("JoinLobby"), 2, 0, GameTextGetTranslatedOrNot("$mp_paste_code")))then
					-- Check if code only contains capital letters and is 25 characters or less
					local code = steam.utils.getClipboard()
					if(code ~= nil and code:match("^[%u]+$") and #code <= 25)then
						lobby_code_input = code
					end

				end

				GuiLayoutBeginHorizontal(menu_gui, 0, 0, true, 0, 0)
				GuiText(menu_gui, 2, 1, GameTextGetTranslatedOrNot("$mp_lobby_code")..": ")
				local lobby_code_value = GuiTextInput(menu_gui, NewID("JoinLobby"), 2, 1, lobby_code_input, 120, 25, "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
				if(lobby_code_input ~= lobby_code_value)then
					lobby_code_input = lobby_code_value
				end
				GuiLayoutEnd(menu_gui)
				

				GuiText(menu_gui, 2, 0, " ")

				if(GuiButton(menu_gui, NewID("JoinLobby"), 2, 0, GameTextGetTranslatedOrNot("$mp_join_lobby")))then
					if(lobby_code_input ~= "" and #lobby_code_input > 5)then
						lobby_code_decompressed = steam.utils.decompressSteamID(lobby_code_input)
						steam.matchmaking.joinLobby(lobby_code_decompressed, function(data)
							if(data.response == 2)then
								steam.matchmaking.leaveLobby(data.lobbyID)
								invite_menu_open = false
								selected_player = nil
								menu_status = status.joining_lobby
								show_lobby_code = false
								lobby_code = nil
							end
						end)
					end
					lobby_code_input = ""
				end
	
				--[[
				for i = 1, 40 do
					GuiText(menu_gui, 2, 0, " ")
				end
				]]

				GuiLayoutEnd(menu_gui)
			end, function() 
				gui_closed = true; 
				invite_menu_open = false 
				selected_player = nil
			end, "join_lobby_gui")

		end
	},
	{
		name = "Disconnected",
		func = function()
			local window_width = 200
			local window_height = 180
		
			local window_text = GameTextGetTranslatedOrNot("$mp_disconnected")

			lobby_code_input = lobby_code_input or ""



			DrawWindow(menu_gui, -6000, screen_width / 2, screen_height / 2, window_width, window_height, window_text, true, function()
				GuiLayoutBeginVertical(menu_gui, 0, 0, true, 0, 0)
				if(GuiButton(menu_gui, NewID("JoinLobby"), 0, 0, GameTextGetTranslatedOrNot("$mp_return_menu")))then
					if(lobby_code ~= nil)then
						steam.matchmaking.leaveLobby(lobby_code)
						lobby_code = nil
					end
					invite_menu_open = false
					selected_player = nil
					lobby_code_input = ""
					menu_status = status.main_menu
					initial_refreshes = 10
					return
				end

				GuiText(menu_gui, 2, 0, "--------------------")
				GuiText(menu_gui, 2, 0, " ")

				GuiText(menu_gui, 2, 0, GameTextGetTranslatedOrNot("$mp_disconnected"))
				GuiText(menu_gui, 2, 0, GameTextGetTranslatedOrNot("$mp_reason")..": "..disconnect_message)

				--[[
				for i = 1, 40 do
					GuiText(menu_gui, 2, 0, " ")
				end
				]]

				GuiLayoutEnd(menu_gui)
			end, function() 
				gui_closed = true; 
				invite_menu_open = false 
				selected_player = nil
			end, "disconnected_gui")
		end
	}
}

GuiZSetForNextWidget(menu_gui, 0)
if(GuiImageButton(menu_gui, NewID("MenuButton"), screen_width - 20, screen_height - 20, "", "mods/evaisa.mp/files/gfx/ui/menu.png"))then
	gui_closed = not gui_closed
	invite_menu_open = false 
	selected_player = nil
	GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", 0, 0)
end

if(not gui_closed)then
	local version_string = "Noita Online (build "..tostring(MP_VERSION).." "..GameTextGetTranslatedOrNot(VERSION_FLAVOR_TEXT)..")"
	if(lobby_code ~= nil)then
		local active_mode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))
		if(active_mode ~= nil)then
			version_string = version_string.." - "..GameTextGetTranslatedOrNot(active_mode.name).." (build "..tostring(active_mode.version).." "..GameTextGetTranslatedOrNot(active_mode.version_flavor_text)..")"
			if(active_mode.version_display)then
				version_string = active_mode.version_display(version_string)
			end
		end
	end
	local text_width, text_height = GuiGetTextDimensions(menu_gui, version_string)
	GuiZSetForNextWidget(menu_gui, 100)
	GuiText(menu_gui, screen_width / 2 - text_width / 2, screen_height - text_height, version_string)
	--print(version_string)
	windows[menu_status].func()
end