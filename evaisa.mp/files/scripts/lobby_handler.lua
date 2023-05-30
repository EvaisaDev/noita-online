lobby_count = lobby_count or 0
lobbies = lobbies or { friend = {}, public = {} }

distance = {
	close = "Close",
	default = "Default",
	far = "Far",
	worldwide = "Worldwide"
}

disconnect_message = disconnect_message or ""
banned_members = banned_members or {}

local function SplitMessage(message, characters)
	-- split string at first space after X characters
	-- concatenate with \n\t
	local split = {}
	local i = 1
	while i <= #message do
		local j = i + characters
		if j > #message then
			j = #message
		end
		local k = string.find(message, " ", j)
		if k == nil then
			k = #message
		end
		table.insert(split, string.sub(message, i, k))
		i = k + 1
	end
	return table.concat(split, "\n")
end

function handleDisconnect(data)
	local message = data.message
	local split_data = {}
	for token in string.gmatch(message, "[^;]+") do
		table.insert(split_data, token)
	end

	if (#split_data >= 3) then
		if (split_data[1] == "disconnect") then
			if (split_data[2] == tostring(steam.user.getSteamID())) then
				msg.log("You were disconnected from the lobby.")
				steam.matchmaking.leaveLobby(data.lobbyID)
				invite_menu_open = false
				menu_status = status.disconnected
				disconnect_message = SplitMessage(split_data[3], 30)
				show_lobby_code = false
				lobby_code = nil
				banned_members = {}
			end
		end
	end
end

function disconnect(data)
	msg.log("You were disconnected from the lobby.")
	local active_mode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))
	if (active_mode) then
		active_mode.leave(data.lobbyID)
	end
	gui_closed = false
	gamemode_settings = {}
	steam.matchmaking.leaveLobby(data.lobbyID)
	invite_menu_open = false
	menu_status = status.disconnected
	disconnect_message = SplitMessage(data.message, 30)
	show_lobby_code = false
	lobby_code = nil
	banned_members = {}
end

function handleBanCheck(user)
	if (banned_members[tostring(user)] ~= nil) then
		mp_log:print("Disconnected member: " .. tostring(user))
		steam.matchmaking.kickUserFromLobby(lobby_code, user, GameTextGetTranslatedOrNot("$mp_banned_warning"))
	end
end

function handleVersionCheck()
	local version = steam.matchmaking.getLobbyData(lobby_code, "version")
	if (version > tostring(MP_VERSION)) then
		disconnect({
			lobbyID = lobby_code,
			message = GameTextGetTranslatedOrNot("$mp_client_outdated")
		})
		return false
	elseif (version < tostring(MP_VERSION)) then
		disconnect({
			lobbyID = lobby_code,
			message = GameTextGetTranslatedOrNot("$mp_host_outdated")
		})
		return false
	end
	return true
end

function handleGamemodeVersionCheck(lobbycode)
	local gamemode_version = steam.matchmaking.getLobbyData(lobbycode, "gamemode_version")
	local active_mode = FindGamemode(steam.matchmaking.getLobbyData(lobbycode, "gamemode"))
	--local gamemode = steam.matchmaking.getLobbyData(lobbycode, "gamemode")
	mp_log:print("Gamemode: " .. tostring(active_mode.id))
	mp_log:print("Version: " .. tostring(gamemode_version))
	if (active_mode ~= nil and gamemode_version ~= nil) then
		if (active_mode ~= nil) then
			if (active_mode.version > tonumber(gamemode_version)) then
				disconnect({
					lobbyID = lobbycode,
					message = string.format(GameTextGetTranslatedOrNot("$mp_host_gamemode_outdated"), GameTextGetTranslatedOrNot(active_mode.name))
				})
				return false
			elseif (active_mode.version < tonumber(gamemode_version)) then
				disconnect({
					lobbyID = lobbycode,
					message = string.format(GameTextGetTranslatedOrNot("$mp_client_gamemode_outdated"), GameTextGetTranslatedOrNot(active_mode.name))
				})
				return false
			end
		else
			disconnect({
				lobbyID = lobbycode,
				message = string.format(GameTextGetTranslatedOrNot("$mp_gamemode_missing"), GameTextGetTranslatedOrNot(active_mode.name))
			})
			return false
		end
	end
	return true
end

function IsCorrectVersion(lobby)
	local version = steam.matchmaking.getLobbyData(lobby, "version")
	local gamemode_version = steam.matchmaking.getLobbyData(lobby, "gamemode_version")
	--local gamemode = steam.matchmaking.getLobbyData(lobby, "gamemode")
	local active_mode = FindGamemode(steam.matchmaking.getLobbyData(lobby, "gamemode"))
	if (version ~= tostring(MP_VERSION)) then
		return false
	end
	if (active_mode ~= nil and gamemode_version ~= nil) then
		if (active_mode ~= nil) then
			if (active_mode.version ~= tonumber(gamemode_version)) then
				return false
			end
		else
			return false
		end
	end
	return true
end

function ModData()
	local nxml = dofile("mods/evaisa.mp/lib/nxml.lua")
	local save_folder = os.getenv('APPDATA'):gsub("\\Roaming", "") ..
		"\\LocalLow\\Nolla_Games_Noita\\save00\\mod_config.xml"

	local things = {}

	for k, v in ipairs(ModGetActiveModIDs()) do
		things[v] = true
	end

	local file, err = io.open(save_folder, 'rb')
	if file then

		mp_log:print("Reading mod config file")

		local content = file:read("*all")

		local data = {
		}

		if (StreamingGetIsConnected()) then
			table.insert(data,
				{
					workshop_item_id = "0",
					name = GameTextGetTranslatedOrNot("$mp_mod_twitch_integration_name"),
					description = GameTextGetTranslatedOrNot("$mp_mod_twitch_integration_description"),
					enabled = true
				})
		end

		local parsedModData = nxml.parse(content)
		for elem in parsedModData:each_child() do
			if (elem.name == "Mod") then
				local modID = elem.attr.name
				local steamID = elem.attr.workshop_item_id

				if (things[modID]) then
					local infoFile = "mods/" .. modID .. "/mod.xml"
					if (steamID ~= "0") then
						infoFile = "../../workshop/content/881100/" .. steamID .. "/mod.xml"
					end

					local file2, err = io.open(infoFile, 'rb')
					if file2 then
						local content2 = file2:read("*all")
						local parsedModInfo = nxml.parse(content2)

						local download_link = parsedModInfo.attr.download_link

						if (elem.attr.enabled == "1") then
							table.insert(data,
								{
									workshop_item_id = steamID,
									id = modID,
									name = parsedModInfo.attr.name,
									description = parsedModInfo.attr.description,
									download_link = download_link,
									settings_fold_open = (elem.attr.settings_fold_open == "1" and true or false),
									enabled = (elem.attr.enabled == "1" and true or false)
								})
						end
					end
				end
			end
		end

		file:close()

		mp_log:print("Mod data: "..json.stringify(data))

		return data
	end
	return nil
end

function defineLobbyUserData(lobby)
	--mp_log:print("Defining lobby user data")
	local mod_data = ModData()
	if (mod_data ~= nil) then
		mp_log:print("Setting mod data: "..json.stringify(mod_data))
		steam.matchmaking.setLobbyMemberData(lobby, "mod_data", json.stringify(mod_data))
	end
end

function handleModCheck()
	local required_mods = (steam.matchmaking.getLobbyData(lobby_code, "required_mods") ~= nil and steam.matchmaking.getLobbyData(lobby_code, "required_mods") ~= "") and bitser.loads(steam.matchmaking.getLobbyData(lobby_code, "required_mods")) or {}

	local player_mods = ModData()

	--print(json.stringify(required_mods))

	
	for i = #required_mods, 1, -1 do
		local v = required_mods[i]
		for k2, v2 in pairs(player_mods) do
			if (v2.id == v[1]) then
				table.remove(required_mods, i)
			end
		end
	end

	if (#required_mods > 0) then

		local mods_string = ""
		for i, v in ipairs(required_mods) do
			if(i == #required_mods) then
				mods_string = mods_string .. v[2] .. " ("..v[1]..")"
			else
				mods_string = mods_string .. v[2] .. " ("..v[1].."), "
			end
		end

		disconnect({
			lobbyID = lobby_code,
			message = string.format(GameTextGetTranslatedOrNot("$mp_client_missing_mods"), mods_string)
		})
		return false
	end
	
	return true
end

function getLobbyUserData(lobby, userid)
	if(lobby == nil) then
		return nil
	end
	if(userid == nil)then
		return nil
	end 
	local player_mod_data = steam.matchmaking.getLobbyMemberData(lobby, userid, "mod_data")
	if (player_mod_data ~= nil and player_mod_data ~= "") then
		local player_name = steam.friends.getFriendPersonaName(userid)
		--mp_log:print(player_name.." mods: "..player_mod_data)
		--print("Getting mod data: "..player_mod_data)
		local data_received = json.parse(player_mod_data)
		--mp_log:print(player_mod_data)
		return data_received
	end
	return nil
end

local reverse_chat_direction = ModSettingGet("evaisa.mp.flip_chat_direction")


local function split_message(msg)
	local words = {}
	local index = 1
	for word in string.gmatch(msg, "%S+") do
		words[index] = word
		index = index + 1
	end

	local chunks = {}
	local chunk = ""
	for i, word in ipairs(words) do
		if utf8.len(chunk .. " " .. word) <= 50 then
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

				local msg = split_data[i]

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

function getFriendLobbies()
	local friend_lobbies = {}

	local friends = steamutils.getSteamFriends();

	for k, v in pairs(friends) do
		local game_info = steam.friends.getFriendGamePlayed(v.id)

		if (game_info and game_info.gameID == game_id and tostring(game_info.lobbyID) ~= "0" and game_info.lobbyID ~= nil) then
			table.insert(friend_lobbies, game_info.lobbyID)
		end
	end

	return friend_lobbies
end

function refreshLobbies()
	lobbies = { friend = {}, public = {} }
	local indexed_lobby = {}

	--steam.matchmaking.addRequestLobbyListStringFilter("LobbyType", "Public", "Equal")
	steam.matchmaking.addRequestLobbyListDistanceFilter(distance.worldwide)

	local activeSystem = "NoitaOnline"

	if (dev_mode) then
		activeSystem = "NoitaOnlineDev"
	end

	steam.matchmaking.addRequestLobbyListStringFilter("System", activeSystem, "Equal")
	

	for _, lobby in ipairs(getFriendLobbies()) do
		if (lobby ~= nil) then
			if (indexed_lobby[lobby] == nil) then
				if (steam.matchmaking.requestLobbyData(lobby)) then
					local lobby_type = steam.matchmaking.getLobbyData(lobby, "LobbyType")

					if (steam.matchmaking.getLobbyData(lobby, "System") ~= nil and steam.matchmaking.getLobbyData(lobby, "System") == activeSystem) then
						local banned = steam.matchmaking.getLobbyData(lobby, "banned_" ..
							tostring(steam.user.getSteamID()))
						if ((lobby_type == "Public" or lobby_type == "FriendsOnly") and banned ~= "true") then
							table.insert(lobbies.friend, lobby)
							indexed_lobby[lobby] = true
						end
					end
				end
			end
		end
	end

	steam.matchmaking.requestLobbyList(function(data)
		lobby_count = data.count
		if (lobby_count > 0) then
			for i = 0, lobby_count - 1 do
				local lobby = steam.matchmaking.getLobbyByIndex(i)
				if (lobby.lobbyID ~= nil) then
					local lobby_type = steam.matchmaking.getLobbyData(lobby.lobbyID, "LobbyType")

					if (steam.matchmaking.getLobbyData(lobby.lobbyID, "System") ~= nil and steam.matchmaking.getLobbyData(lobby.lobbyID, "System") == activeSystem) then
						local banned = steam.matchmaking.getLobbyData(lobby.lobbyID,
							"banned_" .. tostring(steam.user.getSteamID()))
						if ((lobby_type == "Public" or lobby_type == "FriendsOnly") and banned ~= "true") then
							if (indexed_lobby[lobby.lobbyID] == nil) then
								--indexed_lobby[lobby.lobbyID] = true
								table.insert(lobbies.public, lobby.lobbyID)
							end
						end
					end
				end
			end
		end
	end)


	return lobbies
end

function StartGame()
	local lobby_gamemode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))

	if handleVersionCheck() and handleModCheck() then
		if handleGamemodeVersionCheck(lobby_code) then
			if (lobby_gamemode) then

				spectating = steamutils.IsSpectator(lobby_code)

				--print("Are we spectating? " .. tostring(spectating))

				if (spectating) then
					if (lobby_gamemode.spectate ~= nil) then
						lobby_gamemode.spectate(lobby_code)
					elseif (lobby_gamemode.start ~= nil) then
						lobby_gamemode.start(lobby_code)
					end
				else
					if (lobby_gamemode.start ~= nil) then
						lobby_gamemode.start(lobby_code)
					end
				end

				in_game = true
				game_in_progress = true

				gui_closed = true
			else
				disconnect({
					lobbyID = lobby_code,
					message = string.format(GameTextGetTranslatedOrNot("$mp_gamemode_missing"), tostring(steam.matchmaking.getLobbyData(lobby_code, "gamemode")))
				})
			end
		end
	end
end

function StopGame()
	local lobby_gamemode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))

	if handleVersionCheck() and handleModCheck() then
		if handleGamemodeVersionCheck(lobby_code) then
			if (lobby_gamemode) then
				if (lobby_gamemode.stop ~= nil) then
					lobby_gamemode.stop(lobby_code)
				end

				if(steamutils.IsOwner(lobby_code))then
					steam.matchmaking.setLobbyData(lobby_code, "in_progress", "false")
				end

				in_game = false
				game_in_progress = false

				gui_closed = false
			else
				disconnect({
					lobbyID = lobby_code,
					message = string.format(GameTextGetTranslatedOrNot("$mp_gamemode_missing"), tostring(steam.matchmaking.getLobbyData(lobby_code, "gamemode")))
				})
			end
		end
	end
end