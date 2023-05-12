steam_utils = {}

unidecode = require('unicorndecode')

steam_utils.getTranslatedPersonaName = function(steam_id)
	local name = "Unknown"
	if(steam_id == nil)then
		name = steam.friends.getPersonaName()
	else
		name = steam.friends.getFriendPersonaName(steam_id)
	end
	
	if (name == nil or name == "") then
		return "[Name Invalid]"
	end
	
	local decoded = unidecode.decode(name)

	if(decoded == name)then
		return name
	end

	return decoded .. "(" .. tostring(name) .. ")"
end

steam_utils.getSteamFriends = function()
	local list = {}
	for i = 1, steam.friends.getFriendCount(0x04) do
		local h = steam.friends.getFriendByIndex(i - 1, 0x04)
		table.insert(list, { id = h, name = steam_utils.getTranslatedPersonaName(h) })
	end
	return list
end

steam_utils.getLobbyMembers = function(lobby_id, include_spectators)
	local list = {}
	for i = 1, steam.matchmaking.getNumLobbyMembers(lobby_id) do
		local h = steam.matchmaking.getLobbyMemberByIndex(lobby_id, i - 1)

		if (include_spectators or steam.matchmaking.getLobbyData(lobby_id, tostring(h) .. "_spectator") ~= "true") then
			--[[if(include_spectators)then
				print("Adding " .. tostring(steam_utils.getTranslatedPersonaName(h)) .. " to list")
			end]]
			table.insert(list, { id = h, name = steam_utils.getTranslatedPersonaName(h) })
		end	
	end
	return list
end

steam_utils.IsOwner = function(lobby_id)
	return steam.matchmaking.getLobbyOwner(lobby_id) == steam.user.getSteamID()
end

steam_utils.IsSpectator = function(lobby_id, player_id)
	local spectating = steam.matchmaking.getLobbyData(lobby_id, tostring(player_id and player_id or steam.user.getSteamID()) .. "_spectator") ==
		"true"
	return spectating
end

steam_utils.isInLobby = function(lobby_id, steam_id)
	local list = steam_utils.getLobbyMembers(lobby_id, true)
	for i = 1, #list do
		if (list[i].id == steam_id) then
			return true
		end
	end
	return false
end

-- BUG: does not work for private lobbies.
steam_utils.doesLobbyExist = function(lobby_id, callback)
	steam.matchmaking.addRequestLobbyListDistanceFilter(distance.worldwide)

	steam.matchmaking.requestLobbyList(function(data)
		lobby_count = data.count
		if (lobby_count > 0) then
			for i = 0, lobby_count - 1 do
				local lobby = steam.matchmaking.getLobbyByIndex(i)
				if (lobby.lobbyID ~= nil) then
					if (lobby.lobbyID == lobby_id) then
						callback(true)
						return
					end
				end
			end
		end
		callback(false)
	end)
end


local data_store = dofile("mods/evaisa.mp/lib/data_store.lua")

steam_utils.SetLocalLobbyData = function(lobby, key, value)
	if (key == "time_updated") then
		mp_log:print("Illegal lobby key: time_updated")
		return
	end

	-- Compress the lobby ID
	lobby = steam.utils.compressSteamID(lobby)

	-- Create a key to store the data in data_store
	local data_key = tostring(lobby) .. "_" .. key

	-- Store the value with the data_key in data_store
	data_store.Set(data_key, value)

	-- Get the saved list of "all_keys" from data_store
	local key_string = data_store.Get("all_keys")
	local keys = (key_string ~= nil and key_string ~= "") and json.parse(key_string) or {}

	-- Check if there's not an entry for the lobby in keys table
	if (keys[tostring(lobby)] == nil) then
		-- Create an entry for lobby in keys table and set the key as true
		keys[tostring(lobby)] = {
			[key] = true,
			["time_updated"] = os.time(),
		}
	else
		-- If the lobby already exists in keys, set the key as true
		keys[tostring(lobby)][key] = true
		keys[tostring(lobby)]["time_updated"] = os.time()
	end

	local key_string = json.stringify(keys)

	data_store.Set("all_keys", key_string)
end

steam_utils.GetLocalLobbyData = function(lobby, key)
	-- Compress the lobby ID
	lobby = steam.utils.compressSteamID(lobby)

	-- Create a key to get the data from data_store
	local data_key = tostring(lobby) .. "_" .. key

	-- Retrieve the value for the data_key
	local value = data_store.Get(data_key)

	-- Return the value
	return value
end


steam_utils.CheckLocalLobbyData = function()
	-- Get saved list of "all_keys" from data_store
	local key_string = data_store.Get("all_keys")
	local keys = (key_string ~= nil and key_string ~= "") and json.parse(key_string)

	-- if keys is nil, remove all data from data_store
	if (keys == nil) then
		if(RepairDataFolder ~= nil)then
			RepairDataFolder()
		end
		return
	end

	if(type(keys) ~= "table")then
		return
	end 

	-- Print current lobby data for debugging purposes
	--mp_log:print("Checking lobby data: " .. pretty.table(keys))

	-- Set a variable to represent 12 hours in seconds
	local twelve_hours_sec = 12 * 60 * 60

	-- Iterate through all the saved lobbies
	for lobby, lobby_keys in pairs(keys) do
		-- Check if the lobby data is older than 12 hours
		if os.time() - lobby_keys["time_updated"] > twelve_hours_sec then
			-- If lobby data is older than 12 hours, remove the lobby entry from keys table
			keys[lobby] = nil

			-- Also remove the stored data for that lobby
			for key, _ in pairs(lobby_keys) do
				if key ~= "time_updated" then
					-- Remove the data with key "{lobby}_{key}" from data_store
					data_store.Remove(tostring(lobby) .. "_" .. key)
					mp_log:print("Removed old lobby data: " .. tostring(lobby) .. "_" .. key)
				end
			end
		end
	end

	-- Update the "all_keys" entry in data_store with the current keys table
	local updated_key_string = json.stringify(keys)
	data_store.Set("all_keys", updated_key_string)
end

steam_utils.RemoveLocalLobbyData = function(lobby, key)
	-- Compress the lobby ID
	lobby = steam.utils.compressSteamID(lobby)
	local key_string = data_store.Get("all_keys")
	local keys = (key_string ~= nil and key_string ~= "") and json.parse(key_string) or {}

	data_store.Remove(tostring(lobby) .. "_" .. key)

	for lob, lobby_keys in pairs(keys) do
		if (lob == lobby) then
			for k, _ in pairs(lobby_keys) do
				if (k == key) then
					keys[lob][key] = nil
					data_store.Set("all_keys", json.stringify(keys))
					return
				end
			end
		end
	end
end

steam_utils.messageTypes = {
	AllPlayers = 0,
	OtherPlayers = 1,
	Clients = 2,
	Host = 3,
	Spectators = 4,
}

message_handlers = {
	[steam_utils.messageTypes.AllPlayers] = function(data, lobby, reliable, include_spectators)
		local members = steamutils.getLobbyMembers(lobby, include_spectators)
		for k, member in pairs(members) do
			networking_log:print("Sending message ["..bitser.loads(data)[1].."] to " .. member.name)
			
			local success, size = 0, 0

			if (reliable) then
				success, size = steam.networking.sendString(member.id, data)
			else
				success, size = steam.networking.sendStringUnreliable(member.id, data)
			end

			success = tonumber(tostring(success))
			--GamePrint("Sent message of size " .. tostring(size) .. " to " .. member.name .. " (" .. tostring(success) .. ")")
			if (success ~= 1) then
				GamePrint("Failed to send message to " .. member.name .. " (" .. tostring(success) .. ")")
				pretty.table(steam.networking.getConnectionInfo(member.id))
			else
				bytes_sent = bytes_sent + size
			end
		end
	end,
	[steam_utils.messageTypes.OtherPlayers] = function(data, lobby, reliable, include_spectators)
		local members = steamutils.getLobbyMembers(lobby, include_spectators)
		for k, member in pairs(members) do
			if (member.id ~= steam.user.getSteamID()) then
				networking_log:print("Sending message ["..bitser.loads(data)[1].."] to " .. member.name)
				--print("Sending to " .. member.name)

				local success, size = 0, 0

				if (reliable) then
					success, size = steam.networking.sendString(member.id, data)
				else
					success, size = steam.networking.sendStringUnreliable(member.id, data)
				end

				success = tonumber(tostring(success))
				--GamePrint("Sent message of size " .. tostring(size) .. " to " .. member.name .. " (" .. tostring(success) .. ")")
				if (success ~= 1) then
					GamePrint("Failed to send message to " .. member.name .. " (" .. tostring(success) .. ")")
				else
					bytes_sent = bytes_sent + size
				end
			end
		end
	end,
	[steam_utils.messageTypes.Clients] = function(data, lobby, reliable, include_spectators)
		local members = steamutils.getLobbyMembers(lobby, include_spectators)
		for k, member in pairs(members) do
			if (member.id ~= steam.user.getSteamID() and member.id ~= steam.matchmaking.getLobbyOwner(lobby)) then
				networking_log:print("Sending message ["..bitser.loads(data)[1].."] to " .. member.name)
				local success, size = 0, 0

				if (reliable) then
					success, size = steam.networking.sendString(member.id, data)
				else
					success, size = steam.networking.sendStringUnreliable(member.id, data)
				end


				success = tonumber(tostring(success))
				--GamePrint("Sent message of size " .. tostring(size) .. " to " .. member.name .. " (" .. tostring(success) .. ")")
				if (success ~= 1) then
					GamePrint("Failed to send message to " .. member.name .. " (" .. tostring(success) .. ")")
				else
					bytes_sent = bytes_sent + size
				end
			end
		end
	end,
	[steam_utils.messageTypes.Host] = function(data, lobby, reliable)
		networking_log:print("Sending message ["..bitser.loads(data)[1].."] to Host")
		local success, size = 0, 0

		if (reliable) then
			success, size = steam.networking.sendString(steam.matchmaking.getLobbyOwner(lobby), data)
		else
			success, size = steam.networking.sendStringUnreliable(steam.matchmaking.getLobbyOwner(lobby), data)
		end

		success = tonumber(tostring(success))
		--GamePrint("Sent message of size " .. tostring(size) .. " to " .. steam.friends.getFriendPersonaName(steam.matchmaking.getLobbyOwner(lobby)) .. " (" .. tostring(success) .. ")")
		if (success ~= 1) then
			GamePrint("Failed to send message to Host (" .. tostring(success) .. ")")
		else
			bytes_sent = bytes_sent + size
		end
	end,
	[steam_utils.messageTypes.Spectators] = function(data, lobby, reliable)
		local members = steamutils.getLobbyMembers(lobby, true)
		for k, member in pairs(members) do
			local spectating = steam.matchmaking.getLobbyData(lobby_code, tostring(member.id) .. "_spectator") == "true"
			if (member.id ~= steam.user.getSteamID() and spectating) then
				networking_log:print("Sending message ["..bitser.loads(data)[1].."] to " .. member.name)
				local success, size = 0, 0

				if (reliable) then
					success, size = steam.networking.sendString(member.id, data)
				else
					success, size = steam.networking.sendStringUnreliable(member.id, data)
				end

				success = tonumber(tostring(success))
				--GamePrint("Sent message of size " .. tostring(size) .. " to " .. member.name .. " (" .. tostring(success) .. ")")
				if (success ~= 1) then
					GamePrint("Failed to send message to " .. member.name .. " (" .. tostring(success) .. ")")
				else
					bytes_sent = bytes_sent + size
				end
			end
		end
	end,
}

--[[
steam_utils.sendData = function(data, messageType, lobby, reliable)

	--print("Sending data")
	--print(json.stringify(data))
	--print(tostring(bitser.dumps(data)))
	
	local encodedData = bitser.dumps(data)--json.stringify(data)
	if(encodedData ~= nil and (type(encodedData) == "string" or type(encodedData) == "number"))then
		if(type(encodedData) == "number")then
			encodedData = tostring(encodedData)
		end
		message_handlers[messageType](encodedData, lobby, reliable)
	else
		GamePrint("Failed to send data, encodedData is nil or not a string")
	end
end

steam_utils.sendDataToPlayer = function(data, player, reliable)
	local encodedData = bitser.dumps(data)--json.stringify(data)
	if(encodedData ~= nil and (type(encodedData) == "string" or type(encodedData) == "number"))then
		if(type(encodedData) == "number")then
			encodedData = tostring(encodedData)
		end
		local success, size = 0, 0

		if(reliable)then
			success, size = steam.networking.sendStringReliable(player, encodedData)
		else
			success, size = steam.networking.sendString(player, encodedData)
		end

		success = tonumber(tostring(success))
		if(success ~= 1)then
			GamePrint("Failed to send message to " .. steam.friends.getFriendPersonaName(player) .. " (" .. tostring(success) .. ")")
		else
			bytes_sent = bytes_sent + size
		end
	else
		GamePrint("Failed to send data, encodedData is nil or not a string")
	end
end
]]
steam_utils.send = function(event, message, messageType, lobby, reliable, include_spectators)
	local data = { event, message }

	if (not reliable) then
		table.insert(data, GameGetFrameNum())
	end

	local encodedData = bitser.dumps(data)

	if (encodedData ~= nil and (type(encodedData) == "string" or type(encodedData) == "number")) then
		if (type(encodedData) == "number") then
			encodedData = tostring(encodedData)
		end
		message_handlers[messageType](encodedData, lobby, reliable, include_spectators)
	else
		GamePrint("Failed to send data, encodedData is nil or not a string")
	end
end

steam_utils.sendToPlayer = function(event, message, player, reliable)
	local data = { event, message }

	if (not reliable) then
		table.insert(data, GameGetFrameNum())
	end

	local encodedData = bitser.dumps(data)

	if (encodedData ~= nil and (type(encodedData) == "string" or type(encodedData) == "number")) then
		if (type(encodedData) == "number") then
			encodedData = tostring(encodedData)
		end
		local success, size = 0, 0

		if (reliable) then
			success, size = steam.networking.sendString(player, encodedData)
		else
			success, size = steam.networking.sendStringUnreliable(player, encodedData)
		end

		success = tonumber(tostring(success))
		if (success ~= 1) then
			GamePrint("Failed to send message to " .. steamutils.getTranslatedPersonaName(player) .. " (" .. tostring(success) .. ")")
		else
			bytes_sent = bytes_sent + size
		end
	else
		GamePrint("Failed to send data, encodedData is nil or not a string")
	end
end


steam_utils.parseData = function(data)
	local decodedData = bitser.loads(data) --json.parse(data)

	return decodedData
end

return steam_utils
