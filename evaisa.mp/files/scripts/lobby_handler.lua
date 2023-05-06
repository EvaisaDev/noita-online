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
	local active_mode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))
	if(active_mode)then
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
	local active_mode = FindGamemode(steam.matchmaking.getLobbyData(lobbycode, "gamemode"))
	--local gamemode = steam.matchmaking.getLobbyData(lobbycode, "gamemode")
	print("Gamemode: "..tostring(active_mode.id))
	print("Version: "..tostring(gamemode_version))
	if(active_mode ~= nil and gamemode_version ~= nil)then
		if(active_mode ~= nil)then
			if(active_mode.version > tonumber(gamemode_version))then
				disconnect({
					lobbyID = lobbycode,
					message = "The host is using an outdated version of the gamemode: "..active_mode.name
				})
				return false
			elseif(active_mode.version < tonumber(gamemode_version))then
				disconnect({
					lobbyID = lobbycode,
					message = "You are using an outdated version of the gamemode: "..active_mode.name
				})
				return false
			end
		else
			disconnect({
				lobbyID = lobbycode,
				message = "Gamemode missing: "..active_mode.name
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
	if(version ~= tostring(MP_VERSION))then
		return false
	end
	if(active_mode ~= nil and gamemode_version ~= nil)then
		if(active_mode ~= nil)then
			if(active_mode.version ~= tonumber(gamemode_version))then
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
	local bitser = dofile("mods/evaisa.mp/lib/bitser.lua")
    local save_folder = os.getenv('APPDATA'):gsub("\\Roaming", "").."\\LocalLow\\Nolla_Games_Noita\\save00\\mod_config.xml"

	local things = {}

	for k, v in ipairs(ModGetActiveModIDs())do
		things[v] = true
	end

    local file,err = io.open(save_folder,'rb')
    if file then
        local content = file:read("*all")

        local data = {}

        local parsedModData = nxml.parse(content)
        for elem in parsedModData:each_child() do
            if(elem.name == "Mod")then
                local modID = elem.attr.name
                local steamID = elem.attr.workshop_item_id
    
				if(things[modID])then

					local infoFile = "mods/"..modID.."/mod.xml"
					if(steamID ~= "0")then
						infoFile = "../../workshop/content/881100/"..steamID.."/mod.xml"
					end

					local file2,err = io.open(infoFile,'rb')
					if file2 then
						local content2 = file2:read("*all")
						local parsedModInfo = nxml.parse(content2)

						if(elem.attr.enabled == "1")then

							table.insert(data, {workshop_item_id = steamID, id = modID, name = parsedModInfo.attr.name, description = parsedModInfo.attr.description, settings_fold_open = (elem.attr.settings_fold_open == "1" and true or false), enabled = (elem.attr.enabled == "1" and true or false)})
						end
					end

				end
            end
        end

        file:close()

		return data
    end
	return nil
end

function defineLobbyUserData(lobby)
	if(mod_data ~= nil)then
		--print("Setting mod data: "..mod_data)
		steam.matchmaking.setLobbyMemberData(lobby, "mod_data", json.stringify(mod_data))
	end
end

function getLobbyUserData(lobby, userid)
	local player_mod_data = steam.matchmaking.getLobbyMemberData(lobby, userid, "mod_data")
	if(player_mod_data ~= nil)then
		--print("Getting mod data: "..player_mod_data)
		local data_received = json.parse(player_mod_data)
		print(player_mod_data)
		return data_received
	end
	return nil
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
						new_chat_message = true
						was_found = true
						break
					end
				end
				if(not was_found)then
					-- insert at end
					table.insert(chat_log, split_data[i])
					new_chat_message = true
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

	local activeSystem = "NoitaOnline"

	if(dev_mode)then
		activeSystem = "NoitaOnlineDev"
	end

	steam.matchmaking.addRequestLobbyListStringFilter("System", activeSystem, "Equal")


	for _, lobby in ipairs(getFriendLobbies())do
		if(lobby ~= nil)then
			if(indexed_lobby[lobby] == nil)then
				if(steam.matchmaking.requestLobbyData(lobby))then
					local lobby_type = steam.matchmaking.getLobbyData(lobby, "LobbyType")

					if(steam.matchmaking.getLobbyData(lobby, "System") ~= nil and steam.matchmaking.getLobbyData(lobby, "System") == activeSystem)then
						local banned = steam.matchmaking.getLobbyData(lobby, "banned_"..tostring(steam.user.getSteamID()))
						if((lobby_type == "Public" or lobby_type == "FriendsOnly") and banned ~= "true")then
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
		if(lobby_count > 0)then
			for i = 0, lobby_count-1 do

				local lobby = steam.matchmaking.getLobbyByIndex(i)
				if(lobby.lobbyID ~= nil)then
					local lobby_type = steam.matchmaking.getLobbyData(lobby.lobbyID, "LobbyType")

					if(steam.matchmaking.getLobbyData(lobby.lobbyID, "System") ~= nil and steam.matchmaking.getLobbyData(lobby.lobbyID, "System") == activeSystem)then
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
		end
	end)


	return lobbies
end