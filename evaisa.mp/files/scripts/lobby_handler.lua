lobby_count = lobby_count or 0
lobbies = lobbies or {friend = {}, public = {}}

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
	
	if(#split_data >= 3)then
		if(split_data[1] == "disconnect")then
			if(split_data[2] == tostring(steam.user.getSteamID()))then
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
	if(lobby_gamemode and gamemodes[lobby_gamemode] and gamemodes[lobby_gamemode])then
		gamemodes[lobby_gamemode].leave()
	end
	steam.matchmaking.leaveLobby(data.lobbyID)
	invite_menu_open = false
	menu_status = status.disconnected
	disconnect_message = SplitMessage(data.message, 30)
	show_lobby_code = false
	lobby_code = nil
	banned_members = {}
end

function handleBanCheck(user)
	if(banned_members[tostring(user)] ~= nil)then
		print("Disconnected member: "..tostring(user))
		steam.matchmaking.kickUserFromLobby(lobby_code, user, "You are banned from this lobby.")	
	end
end

function handleVersionCheck()
	local version = steam.matchmaking.getLobbyData(lobby_code, "version")
	if(version > tostring(MP_VERSION))then
		disconnect({
			lobbyID = lobby_code,
			message = "You are using an outdated version of Noita Online"
		})
		return false
	elseif(version < tostring(MP_VERSION))then
		disconnect({
			lobbyID = lobby_code,
			message = "The host is using an outdated version of Noita Online"
		})
		return false
	end
	return true
end

function handleGamemodeVersionCheck(lobbycode)
	local gamemode_version = steam.matchmaking.getLobbyData(lobbycode, "gamemode_version")
	local gamemode = steam.matchmaking.getLobbyData(lobbycode, "gamemode")
	print("Gamemode: "..tostring(gamemode))
	print("Version: "..tostring(gamemode_version))
	if(gamemode ~= nil and gamemode_version ~= nil)then
		gamemode = tonumber(gamemode)
		if(gamemodes[gamemode] ~= nil)then
			if(gamemodes[gamemode].version > tonumber(gamemode_version))then
				disconnect({
					lobbyID = lobbycode,
					message = "The host is using an outdated version of the gamemode: "..gamemodes[gamemode].name
				})
				return false
			elseif(gamemodes[gamemode].version < tonumber(gamemode_version))then
				disconnect({
					lobbyID = lobbycode,
					message = "You are using an outdated version of the gamemode: "..gamemodes[gamemode].name
				})
				return false
			end
		else
			disconnect({
				lobbyID = lobbycode,
				message = "Gamemode missing: "..gamemodes[gamemode].name
			})
			return false
		end
	end
	return true
end


function IsCorrectVersion(lobby)
	local version = steam.matchmaking.getLobbyData(lobby, "version")
	local gamemode_version = steam.matchmaking.getLobbyData(lobby, "gamemode_version")
	local gamemode = steam.matchmaking.getLobbyData(lobby, "gamemode")
	if(version ~= tostring(MP_VERSION))then
		return false
	end
	if(gamemode ~= nil and gamemode_version ~= nil)then
		gamemode = tonumber(gamemode)
		if(gamemodes[gamemode] ~= nil)then
			if(gamemodes[gamemode].version ~= tonumber(gamemode_version))then
				return false
			end
		else
			return false
		end
	end
	return true
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

	-- split message by ;
	local message = data.message
	local split_data = {}
	for token in string.gmatch(message, "[^;]+") do
		table.insert(split_data, token)
	end
	
	-- check if first item is "chat"
	if(#split_data > 1 and split_data[1] == "chat")then
		--print("Chat message received: "..data.message)
		-- add remainder of data to chat_log table
		-- reverse loop through table
		for i = 1, #split_data do
			if(i ~= 1)then
				--table.insert(chat_log, split_data[i])
				-- loop through chat_log and find the first index that matches a empty string ""
				local was_found = false
				for j = 1, #chat_log do
					if(chat_log[j] == " ")then
						chat_log[j] = split_data[i]
						was_found = true
						break
					end
				end
				if(not was_found)then
					-- insert at end
					GamePrint(tostring(split_data[i]))
					table.insert(chat_log, split_data[i])
				end
			end
		end
	end
end

function getFriendLobbies()
	local friend_lobbies = {}

	local friends = steamutils.getSteamFriends();

	for k, v in pairs(friends)do
		local game_info = steam.friends.getFriendGamePlayed(v.id)

		if(game_info and game_info.gameID == game_id and tostring(game_info.lobbyID) ~= "0" and game_info.lobbyID ~= nil)then
			table.insert(friend_lobbies, game_info.lobbyID)
		end
	end

	return friend_lobbies
end

function refreshLobbies()
	lobbies = {friend = {}, public = {}}
	local indexed_lobby = {}
			
	--steam.matchmaking.addRequestLobbyListStringFilter("LobbyType", "Public", "Equal")
	steam.matchmaking.addRequestLobbyListDistanceFilter(distance.worldwide)
	steam.matchmaking.addRequestLobbyListStringFilter("NewSystem", "True", "Equal")


	for _, lobby in ipairs(getFriendLobbies())do
		if(lobby ~= nil)then
			if(indexed_lobby[lobby] == nil)then
				if(steam.matchmaking.requestLobbyData(lobby))then
					local lobby_type = steam.matchmaking.getLobbyData(lobby, "LobbyType")
					local banned = steam.matchmaking.getLobbyData(lobby, "banned_"..tostring(steam.user.getSteamID()))
					if((lobby_type == "Public" or lobby_type == "FriendsOnly") and banned ~= "true")then
						table.insert(lobbies.friend, lobby)
						indexed_lobby[lobby] = true
					end
				end
			end
		end
	end

	steam.matchmaking.requestLobbyList(function(data)
		lobby_count = data.count
		if(lobby_count > 0)then
			for i = 0, lobby_count-1 do

				local lobby = steam.matchmaking.getLobbyByIndex(i)
				if(lobby.lobbyID ~= nil)then
					local lobby_type = steam.matchmaking.getLobbyData(lobby.lobbyID, "LobbyType")
					local banned = steam.matchmaking.getLobbyData(lobby.lobbyID, "banned_"..tostring(steam.user.getSteamID()))
					if((lobby_type == "Public" or lobby_type == "FriendsOnly") and banned ~= "true")then
						if(indexed_lobby[lobby.lobbyID] == nil)then
							--indexed_lobby[lobby.lobbyID] = true
							table.insert(lobbies.public, lobby.lobbyID)
						end
					end
				end
			end
		end
	end)


	return lobbies
end