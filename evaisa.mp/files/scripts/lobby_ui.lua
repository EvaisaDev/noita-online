dofile("mods/evaisa.mp/files/scripts/gui_utils.lua")
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

gui_closed = gui_closed or false
invite_menu_open = invite_menu_open or false
lobby_settings_open = lobby_settings_open or false


local is_in_lobby = lobby_code ~= nil and true or false

menu_status = menu_status or status.main_menu

show_lobby_code = show_lobby_code or false

if(is_in_lobby)then
	menu_status = status.lobby
end

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
			print("CreateLobby failed: " .. tostring(e.result))
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
		
			local window_text = "Create or Join Lobby"
		
			DrawWindow(menu_gui, -4000, screen_width / 2, screen_height / 2, window_width, window_height, window_text, true, function()
				GuiLayoutBeginVertical(menu_gui, 0, 0, true, 0, 0)

				if(GuiButton(menu_gui, NewID(), 0, 0, "Create lobby"))then
					menu_status = status.creating_lobby
				end

				if(GuiButton(menu_gui, NewID(), 0, 0, "Join lobby with code"))then
					menu_status = status.joining_lobby
				end

				GuiText(menu_gui, 2, 0, " ")
				if(GuiButton(menu_gui, NewID(), 0, 0, "Refresh lobby list"))then
					refreshLobbies()
				end
				GuiText(menu_gui, 2, 0, " ")
				GuiText(menu_gui, 2, 0, "----- Friend Lobbies -----")
				if(#lobbies.friend > 0)then
					for k, v in ipairs(lobbies.friend)do
						if(steam.matchmaking.requestLobbyData(v))then
							local lobby_gamemode = steam.matchmaking.getLobbyData(v, "gamemode")
							local lobby_name = steam.matchmaking.getLobbyData(v, "name")

							local lobby_members = steam.matchmaking.getNumLobbyMembers(v)
							local lobby_max_players = steam.matchmaking.getLobbyMemberLimit(v)

							GuiLayoutBeginHorizontal(menu_gui, 0, 0, true, 0, 0)
							if(not IsCorrectVersion(v))then
								if(GuiButton(menu_gui, NewID(), 0, 0, "[Version Mismatch] "..lobby_name))then
									steam.matchmaking.leaveLobby(v)
									steam.matchmaking.joinLobby(v, function(e)
									end)
								end
							else
								if(GuiButton(menu_gui, NewID(), 0, 0, "("..gamemodes[tonumber(lobby_gamemode)].name..")("..tostring(lobby_members).."/"..tostring(lobby_max_players)..") "..lobby_name))then
									steam.matchmaking.leaveLobby(v)
									steam.matchmaking.joinLobby(v, function(e)
									end)
								end
							end

							GuiLayoutEnd(menu_gui)
		
						end
					end
				else
					GuiText(menu_gui, 2, 0, "No lobbies found")
				end
				GuiText(menu_gui, 2, 0, " ")
				GuiText(menu_gui, 2, 0, "----- Public Lobbies -----")
				if(#lobbies.public > 0)then
					for k, v in ipairs(lobbies.public)do
						local lobby_gamemode = steam.matchmaking.getLobbyData(v, "gamemode")
						local lobby_name = steam.matchmaking.getLobbyData(v, "name")
						local lobby_gamemode_name = steam.matchmaking.getLobbyData(v, "gamemode_name")
						local lobby_gamemode_version = steam.matchmaking.getLobbyData(v, "gamemode_version")
						local lobby_version = steam.matchmaking.getLobbyData(v, "version")

						local lobby_members = steam.matchmaking.getNumLobbyMembers(v)
						local lobby_max_players = steam.matchmaking.getLobbyMemberLimit(v)


						GuiLayoutBeginHorizontal(menu_gui, 0, 0, true, 0, 0)
						if(not IsCorrectVersion(v))then
							if(GuiButton(menu_gui, NewID(), 0, 0, "[Version Mismatch] "..lobby_name))then
								steam.matchmaking.leaveLobby(v)
								steam.matchmaking.joinLobby(v, function(e)
								end)
							end
						else
							if(GuiButton(menu_gui, NewID(), 0, 0, "("..gamemodes[tonumber(lobby_gamemode)].name..")("..tostring(lobby_members).."/"..tostring(lobby_max_players)..") "..lobby_name))then
								steam.matchmaking.leaveLobby(v)
								steam.matchmaking.joinLobby(v, function(e)
								end)
							end
						end

						GuiLayoutEnd(menu_gui)
					end
				else
					GuiText(menu_gui, 2, 0, "No lobbies found")
				end
					
				

				for i = 1, 40 do
					GuiText(menu_gui, 2, 0, " ")
				end

				GuiLayoutEnd(menu_gui)
			end, function() 
				gui_closed = true; 
				invite_menu_open = false 
			end)

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


			DrawWindow(menu_gui, -5000, screen_width / 2, screen_height / 2, window_width, window_height, function() 

				GuiColorSetForNextWidget( menu_gui, 0, 0, 0, 0.3 )
				GuiText(menu_gui, 0, 0, "Lobby - ("..((not show_lobby_code) and censorString(steam.utils.compressSteamID(lobby_code)) or steam.utils.compressSteamID(lobby_code))..")")

				GuiColorSetForNextWidget( menu_gui, (74 / 2) / 255, (62 / 2) / 255, (46 / 2) / 255, 0.5 )
				GuiImage(menu_gui, NewID("Lobby"), 1, 1.5, (show_lobby_code) and "mods/evaisa.mp/files/gfx/ui/hide.png" or "mods/evaisa.mp/files/gfx/ui/show.png", 0.5, 1)
				

				GuiColorSetForNextWidget( menu_gui, 0, 0, 0, 0.5 )
				if(GuiButton(menu_gui, NewID("Lobby"), 0, 0, show_lobby_code and " Hide" or " Show"))then
					show_lobby_code = not show_lobby_code
				end
				
				if(show_lobby_code)then
					CustomTooltip(menu_gui, function() 
						--GuiZSetForNextWidget(menu_gui, -5110)
						GuiColorSetForNextWidget( menu_gui, 1, 1, 1, 0.8 )
						--GuiText(menu_gui, 0, 0, "Hide Code")
						GuiZSetForNextWidget(menu_gui, -5110)
						GuiText(menu_gui, 0, 0, "Hide the lobby code")
					end, -5100, -60, -20)
				else
					CustomTooltip(menu_gui, function() 
						--GuiZSetForNextWidget(menu_gui, -5110)
						GuiColorSetForNextWidget( menu_gui, 1, 1, 1, 0.8 )
						--GuiText(menu_gui, 0, 0, "Show Code")
						GuiZSetForNextWidget(menu_gui, -5110)
						GuiText(menu_gui, 0, 0, "Show the lobby code")
					end, -5100, -68, -20)
				end

				GuiColorSetForNextWidget( menu_gui, (74 / 2) / 255, (62 / 2) / 255, (46 / 2) / 255, 0.5 )
				GuiImage(menu_gui, NewID("Lobby"), 6, 1.5, "mods/evaisa.mp/files/gfx/ui/copy.png", 0.5, 1)

				GuiColorSetForNextWidget( menu_gui, 0, 0, 0, 0.5 )
				if(GuiButton(menu_gui, NewID("Lobby"), -1, 0, " Copy"))then
					steam.utils.setClipboard(steam.utils.compressSteamID(lobby_code))
				end

				CustomTooltip(menu_gui, function() 
					--GuiZSetForNextWidget(menu_gui, -5110)
					GuiColorSetForNextWidget( menu_gui, 1, 1, 1, 0.8 )
					--GuiText(menu_gui, 0, 0, "Show Code")
					GuiZSetForNextWidget(menu_gui, -5110)
					GuiText(menu_gui, 0, 0, "Copy the lobby code to your clipboard.")
				end, -5100, -150, -20)
				
			end, true, function()
				
				GuiLayoutBeginVertical(menu_gui, 0, 0, true, 0, 0)

				local owner = steam.matchmaking.getLobbyOwner(lobby_code)

				if(GuiButton(menu_gui, NewID("Lobby"), 0, 0, "Leave lobby"))then
					if(gamemodes[lobby_gamemode] and gamemodes[lobby_gamemode])then
						gamemodes[lobby_gamemode].leave()
					end
					steam.matchmaking.leaveLobby(lobby_code)
					initial_refreshes = 10
					invite_menu_open = false
					menu_status = status.main_menu
					show_lobby_code = false
					lobby_code = nil
					banned_members = {}
					return
				end

	
				if(GuiButton(menu_gui, NewID("Lobby"), 0, 0, invite_menu_open and "< Invite players" or "> Invite players"))then
					invite_menu_open = not invite_menu_open
					lobby_settings_open = false
				end

				if(GuiButton(menu_gui, NewID("Lobby"), 0, 0, lobby_settings_open and "< Lobby Settings" or "> Lobby Settings"))then
					lobby_settings_open = not lobby_settings_open
					invite_menu_open = false
				end

				if(GuiButton(menu_gui, NewID("Lobby"), 0, 0, "Start Game" ) and owner == steam.user.getSteamID())then
					gui_closed = not gui_closed
					invite_menu_open = false
					steam.matchmaking.sendLobbyChatMsg(lobby_code, "start")
					steam.matchmaking.setLobbyData(lobby_code, "in_progress", "true")
				end

				GuiText(menu_gui, 2, 0, "--------------------")
				local players = steam_utils.getLobbyMembers(lobby_code)
	
				for k, v in pairs(players) do
					GuiLayoutBeginHorizontal(menu_gui, 0, 0, true, 0, 0)
	
					if(v.id ~= steam.user.getSteamID() and owner == steam.user.getSteamID())then
						if(GuiButton(menu_gui, NewID("Lobby"), 2, 0, "[Kick]"))then
							steam.matchmaking.kickUserFromLobby(lobby_code, v.id, "You were kicked from the lobby.")
						end
						if(GuiButton(menu_gui, NewID("Lobby"), 0, 0, "[Ban]"))then
							steam.matchmaking.kickUserFromLobby(lobby_code, v.id, "You were banned from the lobby.")	
							steam.matchmaking.setLobbyData(lobby_code, "banned_"..tostring(v.id), "true")
							banned_members[tostring(v.id)] = true
						end
						if(GuiButton(menu_gui, NewID("Lobby"), 0, 0, "[Owner]"))then
							steam.matchmaking.setLobbyOwner(lobby_code, v.id)
							banned_members = {}
						end
					end
					
					if(v.id == owner)then
						GuiImage(menu_gui, NewID("Lobby"), 2, -3, "mods/evaisa.mp/files/gfx/ui/crown.png", 1, 1, 1, 0)
	
						GuiText(menu_gui, -5, 0, tostring(v.name))
					else
						GuiText(menu_gui, 2, 0, tostring(v.name))
					end
	
					GuiLayoutEnd(menu_gui)
					GuiText(menu_gui, 0, -6, " ")
				end
	
				for i = 1, 40 do
					GuiText(menu_gui, 2, 0, " ")
				end

				GuiLayoutEnd(menu_gui)
			end, function() 
				gui_closed = true; 
				invite_menu_open = false 
			end)
		
			if(invite_menu_open)then

				friendfilters_ingame = friendfilters_ingame or false
				friendfilters_inlobby = friendfilters_inlobby or false
				friendfilters_offline = friendfilters_offline or false
				friendfilters_busy = friendfilters_busy or false
				friendfilters_away = friendfilters_away or false

				DrawWindow(menu_gui, -5500 ,(((screen_width / 2) - (window_width / 2))) - (150 / 2) - 18, screen_height / 2, 150, window_height, "Friends", true, function()
					GuiLayoutBeginVertical(menu_gui, 0, 0, true, 0, 0)
					local friends = steamutils.getSteamFriends();

					if(GuiButton(menu_gui, NewID("Invite"), 0, 0, friendfilters_ingame and "[X] Show only in-game" or "[ ] Show only in-game"))then
						friendfilters_ingame = not friendfilters_ingame
					end

					if(GuiButton(menu_gui, NewID("Invite"), 0, 0, friendfilters_inlobby and "[X] Show in lobby" or "[ ] Show in lobby"))then
						friendfilters_inlobby = not friendfilters_inlobby
					end

					if(GuiButton(menu_gui, NewID("Invite"), 0, 0, friendfilters_offline and "[X] Show offline" or "[ ] Show offline"))then
						friendfilters_offline = not friendfilters_offline
					end

					if(GuiButton(menu_gui, NewID("Invite"), 0, 0, friendfilters_busy and "[X] Show busy" or "[ ] Show busy"))then
						friendfilters_busy = not friendfilters_busy
					end

					if(GuiButton(menu_gui, NewID("Invite"), 0, 0, friendfilters_away and "[X] Show away" or "[ ] Show away"))then
						friendfilters_away = not friendfilters_away
					end

					GuiText(menu_gui, 2, 0, "--------------------")

					for k, v in pairs(friends)do

						local state = steam.friends.getFriendPersonaState(v.id)
						local game_info = steam.friends.getFriendGamePlayed(v.id)

						local online_filter_pass = state == 1 or (state == 0 and friendfilters_offline) or (state == 2 and friendfilters_busy) or (state == 3 and friendfilters_away) or (state == 4 and friendfilters_away)

						local ingame_filter_pass = (not game_info and not friendfilters_ingame) or (game_info and game_info.gameID ~= game_id and not friendfilters_ingame ) or (game_info and game_info.gameID == game_id)

						local inlobby_filter_pass = (not game_info) or (game_info and game_info.gameID ~= game_id) or (game_info and game_info.gameID == game_id and tostring(game_info.lobbyID) ~= "0" and friendfilters_inlobby) or (game_info and game_info.gameID == game_id and tostring(game_info.lobbyID) == "0")


						if(online_filter_pass and ingame_filter_pass and inlobby_filter_pass)then
							GuiLayoutBeginHorizontal(menu_gui, 0, 0, true, 0, 0)
							if(GuiButton(menu_gui, NewID("Invite"), 0, 0, "[Invite] "))then
								if(lobby_code ~= nil)then
									if(steam.matchmaking.inviteUserToLobby(lobby_code, v.id))then
										print("Invited "..v.name.." to lobby")
									else
										print("Failed to invite "..v.name.." to lobby")
									end
								end
							end
							GuiText(menu_gui, 2, 0, v.name)
							GuiLayoutEnd(menu_gui)
						end
					end

					for i = 1, 40 do
						GuiText(menu_gui, 2, 0, " ")
					end
		
					GuiLayoutEnd(menu_gui)
				end)	
		
			end
			if(lobby_settings_open)then
				local lobby_types = {
					"Public",
					"Private",
					"Friends Only"
				}

				
				local owner = steam.matchmaking.getLobbyOwner(lobby_code)

				local internal_types = { "Public", "Private", "FriendsOnly"}
				local internal_type_map = { Public = 1, Private = 2, FriendsOnly = 3 }


				edit_lobby_type = edit_lobby_type or 1
				edit_lobby_gamemode = edit_lobby_gamemode or tonumber(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))
	
				local true_max = 32
	
				local default_max_players = 8
	
				edit_lobby_max_players = edit_lobby_max_players or steam.matchmaking.getLobbyMemberLimit(lobby_code)

				edit_lobby_name = edit_lobby_name or steam.matchmaking.getLobbyData(lobby_code, "name")

				edit_lobby_seed = edit_lobby_seed or steam.matchmaking.getLobbyData(lobby_code, "seed")

				DrawWindow(menu_gui, -5500 ,(((screen_width / 2) - (window_width / 2))) - (180 / 2) - 18, screen_height / 2, 180, window_height, "Lobby Settings", true, function()
					GuiLayoutBeginVertical(menu_gui, 0, 0, true, 0, 0)
	
					if(GuiButton(menu_gui, NewID("EditLobby"), 2, 0, "Lobby type: "..lobby_types[edit_lobby_type]))then
						edit_lobby_type = edit_lobby_type + 1
						if(edit_lobby_type > #lobby_types and owner == steam.user.getSteamID())then
							edit_lobby_type = 1
						end
					end
	
					if(GuiButton(menu_gui, NewID("EditLobby"), 2, 1, "Gamemode: "..gamemodes[edit_lobby_gamemode].name))then
						edit_lobby_gamemode = edit_lobby_gamemode + 1
						if(edit_lobby_gamemode > #gamemodes and owner == steam.user.getSteamID())then
							edit_lobby_gamemode = 1
						end
					end
	
					GuiLayoutBeginHorizontal(menu_gui, 0, 0, true, 0, 0)
					GuiText(menu_gui, 2, 1, "Lobby name: ")
					local lobby_name_value = GuiTextInput(menu_gui, NewID("EditLobby"), 2, 1, edit_lobby_name, 120, 25, "qwertyuiopasdfghjklzxcvbnm1234567890QWERTYUIOPASDFGHJKLZXCVBNM!@#$%^&*()_' ")
					if(lobby_name_value ~= edit_lobby_name and owner == steam.user.getSteamID())then
						edit_lobby_name = lobby_name_value
					end
					GuiLayoutEnd(menu_gui)
					
					GuiLayoutBeginHorizontal(menu_gui, 0, 0, true, 0, 0)
					GuiText(menu_gui, 2, 3, "Max players: ")
					local slider_value = GuiSlider(menu_gui, NewID("EditLobby"), 0, 4, "", edit_lobby_max_players, 2, true_max, default_max_players, 1, " $0", 120)
					if(slider_value ~= edit_lobby_max_players and owner == steam.user.getSteamID())then
						edit_lobby_max_players = slider_value
					end
					GuiLayoutEnd(menu_gui)

					GuiLayoutBeginHorizontal(menu_gui, 0, 0, true, 0, 0)
					GuiText(menu_gui, 2, 4, "World seed: ")
					local edit_lobby_seed_value = GuiTextInput(menu_gui, NewID("EditLobby"), 2, 4, edit_lobby_seed, 120, 10, "1234567890")
					if(edit_lobby_seed_value ~= edit_lobby_seed and owner == steam.user.getSteamID())then
						edit_lobby_seed = edit_lobby_seed_value
					end
					GuiLayoutEnd(menu_gui)

					GuiText(menu_gui, 2, 6, "--------------------")

					if(GuiButton(menu_gui, NewID("EditLobby"), 2, 0, "Update Lobby Settings") and owner == steam.user.getSteamID())then
						steam.matchmaking.setLobbyMemberLimit(lobby_code, edit_lobby_max_players)
						steam.matchmaking.setLobbyData(lobby_code, "gamemode", tostring(edit_lobby_gamemode))
						steam.matchmaking.setLobbyData(lobby_code, "gamemode_version", tostring(gamemodes[edit_lobby_gamemode].version))
						steam.matchmaking.setLobbyData(lobby_code, "gamemode_name", tostring(gamemodes[edit_lobby_gamemode].name))
						steam.matchmaking.setLobbyData(lobby_code, "name", edit_lobby_name)
						steam.matchmaking.setLobbyData(lobby_code, "seed", edit_lobby_seed)
						steam.matchmaking.setLobbyType(lobby_code, internal_types[edit_lobby_type])
						steam.matchmaking.sendLobbyChatMsg(lobby_code, "refresh")
						print("Updated limit: "..tostring(edit_lobby_max_players))
						print("Updated gamemode: "..tostring(edit_lobby_gamemode))
						print("Updated name: "..tostring(edit_lobby_name))
						print("Updated type: "..tostring(internal_types[edit_lobby_type]))
					end

					for i = 1, 40 do
						GuiText(menu_gui, 2, 0, " ")
					end
		

					GuiLayoutEnd(menu_gui)
				end)	
		
			end
		end
	},
	{
		name = "CreateLobby",
		func = function()


			local window_width = 200
			local window_height = 180
		
			local window_text = "Create lobby"

			lobby_type = lobby_type or 1
			lobby_gamemode = lobby_gamemode or 1

			local true_max = 32

			local default_max_players = 8

			lobby_max_players = lobby_max_players or default_max_players

			local default_lobby_name = steam.friends.getPersonaName()

			-- if default lobby name ends with "s" add ' otherwise add 's

			if(string.sub(default_lobby_name, -1) == "s")then
				default_lobby_name = default_lobby_name.."' Lobby"
			else
				default_lobby_name = default_lobby_name.."'s Lobby"
			end

			lobby_name = lobby_name or default_lobby_name
			lobby_seed = lobby_seed or tostring(math.random(1, 4294967295))

			DrawWindow(menu_gui, -6000, screen_width / 2, screen_height / 2, window_width, window_height, window_text, true, function()
				GuiLayoutBeginVertical(menu_gui, 0, 0, true, 0, 0)

				if(GuiButton(menu_gui, NewID("CreateLobby"), 0, 0, "Return to menu"))then
					if(lobby_code ~= nil)then
						steam.matchmaking.leaveLobby(lobby_code)
						lobby_code = nil
					end
					invite_menu_open = false
					menu_status = status.main_menu
					initial_refreshes = 10
					return
				end

				GuiText(menu_gui, 2, 0, "--------------------")
				GuiText(menu_gui, 2, 0, " ")
				local lobby_types = {
					"Public",
					"Private",
					"Friends Only",
				}

				local internal_types = { "Public", "Private", "FriendsOnly",}

				if(GuiButton(menu_gui, NewID("CreateLobby"), 2, 0, "Lobby type: "..lobby_types[lobby_type]))then
					lobby_type = lobby_type + 1
					if(lobby_type > #lobby_types)then
						lobby_type = 1
					end
				end


				if(GuiButton(menu_gui, NewID("CreateLobby"), 2, 1, "Gamemode: "..gamemodes[lobby_gamemode].name))then
					lobby_gamemode = lobby_gamemode + 1
					if(lobby_gamemode > #gamemodes)then
						lobby_gamemode = 1
					end
				end

				GuiLayoutBeginHorizontal(menu_gui, 0, 0, true, 0, 0)
				GuiText(menu_gui, 2, 1, "Lobby name: ")
				local lobby_name_value = GuiTextInput(menu_gui, NewID("CreateLobby"), 2, 1, lobby_name, 120, 25, "qwertyuiopasdfghjklzxcvbnm1234567890QWERTYUIOPASDFGHJKLZXCVBNM!@#$%^&*()_' ")
				if(lobby_name_value ~= lobby_name)then
					lobby_name = lobby_name_value
				end
				GuiLayoutEnd(menu_gui)
				
				GuiLayoutBeginHorizontal(menu_gui, 0, 0, true, 0, 0)
				GuiText(menu_gui, 2, 3, "Max players: ")
				local slider_value = GuiSlider(menu_gui, NewID("CreateLobby"), 0, 4, "", lobby_max_players, 2, true_max, default_max_players, 1, " $0", 120)
				if(slider_value ~= lobby_max_players)then
					lobby_max_players = slider_value
				end
				GuiLayoutEnd(menu_gui)

				GuiLayoutBeginHorizontal(menu_gui, 0, 0, true, 0, 0)
				GuiText(menu_gui, 2, 4, "World seed: ")
				local lobby_seed_value = GuiTextInput(menu_gui, NewID("CreateLobby"), 2, 4, lobby_seed, 120, 10, "1234567890")
				if(lobby_seed_value ~= lobby_seed)then
					lobby_seed = lobby_seed_value
				end
				GuiLayoutEnd(menu_gui)

				GuiText(menu_gui, 2, 0, " ")

				if(GuiButton(menu_gui, NewID("CreateLobby"), 2, 0, "Create lobby"))then
					CreateLobby(internal_types[lobby_type], lobby_max_players, function (code) 
						msg.log("Created new lobby!")
						
						steam.matchmaking.setLobbyData(code, "name", lobby_name)
						steam.matchmaking.setLobbyData(code, "gamemode", tostring(lobby_gamemode))
						steam.matchmaking.setLobbyData(code, "gamemode_version", tostring(gamemodes[lobby_gamemode].version))
						steam.matchmaking.setLobbyData(code, "gamemode_name", tostring(gamemodes[lobby_gamemode].name))
						steam.matchmaking.setLobbyData(code, "seed", lobby_seed)
						steam.matchmaking.setLobbyData(code, "version", tostring(MP_VERSION))

						steam.friends.setRichPresence( "status", "Noita Arena - Waiting for players" )

						lobby_code = code
					end)
				end
	
				for i = 1, 40 do
					GuiText(menu_gui, 2, 0, " ")
				end

				GuiLayoutEnd(menu_gui)
			end, function() 
				gui_closed = true; 
				invite_menu_open = false 
			end)

		end
	},
	{
		name = "JoinLobby",
		func = function()


			local window_width = 200
			local window_height = 180
		
			local window_text = "Join lobby"

			lobby_code_input = lobby_code_input or ""



			DrawWindow(menu_gui, -6000, screen_width / 2, screen_height / 2, window_width, window_height, window_text, true, function()
				GuiLayoutBeginVertical(menu_gui, 0, 0, true, 0, 0)

				if(GuiButton(menu_gui, NewID("JoinLobby"), 0, 0, "Return to menu"))then
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
				

				if(GuiButton(menu_gui, NewID("JoinLobby"), 2, 0, "Paste code from clipboard"))then
					-- Check if code only contains capital letters and is 25 characters or less
					local code = steam.utils.getClipboard()
					if(code ~= nil and code:match("^[%u]+$") and #code <= 25)then
						lobby_code_input = code
					end

				end

				GuiLayoutBeginHorizontal(menu_gui, 0, 0, true, 0, 0)
				GuiText(menu_gui, 2, 1, "Lobby Code: ")
				local lobby_code_value = GuiTextInput(menu_gui, NewID("JoinLobby"), 2, 1, lobby_code_input, 120, 25, "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
				if(lobby_code_input ~= lobby_code_value)then
					lobby_code_input = lobby_code_value
				end
				GuiLayoutEnd(menu_gui)
				

				GuiText(menu_gui, 2, 0, " ")

				if(GuiButton(menu_gui, NewID("JoinLobby"), 2, 0, "Join lobby"))then
					if(lobby_code_input ~= "" and #lobby_code_input > 5)then
						lobby_code_decompressed = steam.utils.decompressSteamID(lobby_code_input)
						steam.matchmaking.joinLobby(lobby_code_decompressed, function(data)
							if(data.response == 2)then
								steam.matchmaking.leaveLobby(data.lobbyID)
								invite_menu_open = false
								menu_status = status.joining_lobby
								show_lobby_code = false
								lobby_code = nil
							end
						end)
					end
					lobby_code_input = ""
				end
	
				for i = 1, 40 do
					GuiText(menu_gui, 2, 0, " ")
				end

				GuiLayoutEnd(menu_gui)
			end, function() 
				gui_closed = true; 
				invite_menu_open = false 
			end)

		end
	},
	{
		name = "Disconnected",
		func = function()
			local window_width = 200
			local window_height = 180
		
			local window_text = "Disconnected"

			lobby_code_input = lobby_code_input or ""



			DrawWindow(menu_gui, -6000, screen_width / 2, screen_height / 2, window_width, window_height, window_text, true, function()
				GuiLayoutBeginVertical(menu_gui, 0, 0, true, 0, 0)
				if(GuiButton(menu_gui, NewID("JoinLobby"), 0, 0, "Return to menu"))then
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
				GuiText(menu_gui, 2, 0, " ")

				GuiText(menu_gui, 2, 0, "Disconnected.")
				GuiText(menu_gui, 2, 0, "Reason: "..disconnect_message)

				for i = 1, 40 do
					GuiText(menu_gui, 2, 0, " ")
				end

				GuiLayoutEnd(menu_gui)
			end, function() 
				gui_closed = true; 
				invite_menu_open = false 
			end)
		end
	}
}

GuiZSetForNextWidget(menu_gui, 0)
if(GuiImageButton(menu_gui, NewID("MenuButton"), screen_width - 20, screen_height - 20, "", "mods/evaisa.mp/files/gfx/ui/menu.png"))then
	gui_closed = not gui_closed
	invite_menu_open = false 
	GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", 0, 0)
end

if(not gui_closed)then
	windows[menu_status].func()
end