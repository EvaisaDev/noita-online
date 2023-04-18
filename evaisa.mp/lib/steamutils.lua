steam_utils = {}

steam_utils.getSteamFriends = function()
	local list = {}
	for i = 1, steam.friends.getFriendCount(0x04) do
	  local h = steam.friends.getFriendByIndex(i - 1, 0x04)
	  table.insert(list, {id = h, name = steam.friends.getFriendPersonaName(h)})
	end
	return list
end

steam_utils.getLobbyMembers = function(lobby_id)
	local list = {}
	for i = 1, steam.matchmaking.getNumLobbyMembers(lobby_id) do
	  local h = steam.matchmaking.getLobbyMemberByIndex(lobby_id, i - 1)
	  table.insert(list, {id = h, name = steam.friends.getFriendPersonaName(h)})
	end
	return list
end

steam_utils.IsOwner = function(lobby_id)
	return steam.matchmaking.getLobbyOwner(lobby_id) == steam.user.getSteamID()
end

steam_utils.isInLobby = function(lobby_id, steam_id)
	local list = steam_utils.getLobbyMembers(lobby_id)
	for i = 1, #list do
		if(list[i].id == steam_id)then
			return true
		end
	end
	return false
end

steam_utils.SetLocalLobbyData = function(lobby, key, value)
	lobby = steam.utils.compressSteamID(lobby)
	--ModSettingRemove("lobby_data_store")
	local data_store = ModSettingGet("lobby_data_store")
	--print("datastore: "..tostring(data_store))
	local lobby_data = {}
	if(data_store)then
		lobby_data = json.parse(data_store)--bitser.loads(data_store)
	end

	if(lobby_data == nil)then
		lobby_data = {}
	end

	if(lobby_data[lobby] == nil)then
		lobby_data[lobby] = {}
	end

	lobby_data[lobby][key] = value

	ModSettingSet("lobby_data_store", json.stringify(lobby_data)--[[bitser.dumps(lobby_data)]])
end

steam_utils.GetLocalLobbyData = function(lobby, key)
	lobby = steam.utils.compressSteamID(lobby)
	--ModSettingRemove("lobby_data_store")
	local data_store = ModSettingGet("lobby_data_store")
	local lobby_data
	if(data_store == nil or data_store == "")then
		lobby_data = {}
	else
		lobby_data =  json.parse(data_store)
	end

	if(lobby_data[lobby] == nil)then
		return nil
	end

	return lobby_data[lobby][key]
end

steam_utils.CheckLocalLobbyData = function()
	-- destroy data for any lobbies which no longer exist
	local data_store = ModSettingGet("lobby_data_store")
	local lobby_data
	if(data_store == nil or data_store == "")then
		lobby_data = {}
	else
		lobby_data =  json.parse(data_store)
	end

	for k, v in pairs(lobby_data)do
		local lobby_id = steam.utils.decompressSteamID(k)
		if(not steam.matchmaking.requestLobbyData(lobby_id))then
			lobby_data[k] = nil
		end
	end

	ModSettingSet("lobby_data_store", json.stringify(lobby_data))
end

steam_utils.messageTypes = {
	AllPlayers = 0,
	OtherPlayers = 1,
	Clients = 2,
	Host = 3,
}

local json = dofile("mods/evaisa.mp/lib/json.lua")

message_handlers = {
	[steam_utils.messageTypes.AllPlayers] = function (data, lobby) 
		local members = steamutils.getLobbyMembers(lobby)
		for k, member in pairs(members)do
			
			local success, size = steam.networking.sendString(member.id, data)
			success = tonumber(tostring(success))
			--GamePrint("Sent message of size " .. tostring(size) .. " to " .. member.name .. " (" .. tostring(success) .. ")")
			if(success ~= 1)then
				
				GamePrint("Failed to send message to " .. member.name .. " (" .. tostring(success) .. ")")
				pretty.table(steam.networking.getConnectionInfo(member.id))
			else
				bytes_sent = bytes_sent + size
			end
		end
	end,
	[steam_utils.messageTypes.OtherPlayers] = function (data, lobby) 
		local members = steamutils.getLobbyMembers(lobby)
		for k, member in pairs(members)do
			if(member.id ~= steam.user.getSteamID())then
				local success, size = steam.networking.sendString(member.id, data)
				success = tonumber(tostring(success))
				--GamePrint("Sent message of size " .. tostring(size) .. " to " .. member.name .. " (" .. tostring(success) .. ")")
				if(success ~= 1)then
					GamePrint("Failed to send message to " .. member.name .. " (" .. tostring(success) .. ")")
				else
					bytes_sent = bytes_sent + size
				end
			end
		end
	end,
	[steam_utils.messageTypes.Clients] = function (data, lobby) 
		local members = steamutils.getLobbyMembers(lobby)
		for k, member in pairs(members)do
			if(member.id ~= steam.user.getSteamID() and member.id ~= steam.matchmaking.getLobbyOwner(lobby))then
				local success, size = steam.networking.sendString(member.id, data)
				success = tonumber(tostring(success))
				--GamePrint("Sent message of size " .. tostring(size) .. " to " .. member.name .. " (" .. tostring(success) .. ")")
				if(success ~= 1)then
					GamePrint("Failed to send message to " .. member.name .. " (" .. tostring(success) .. ")")
				else
					bytes_sent = bytes_sent + size
				end
			end
		end
	end,
	[steam_utils.messageTypes.Host] = function (data, lobby) 
		local success, size = steam.networking.sendString(steam.matchmaking.getLobbyOwner(lobby), data)
		success = tonumber(tostring(success))
		--GamePrint("Sent message of size " .. tostring(size) .. " to " .. steam.friends.getFriendPersonaName(steam.matchmaking.getLobbyOwner(lobby)) .. " (" .. tostring(success) .. ")")
		if(success ~= 1)then
			GamePrint("Failed to send message to Host (" .. tostring(success) .. ")")
		else
			bytes_sent = bytes_sent + size
		end
	end,
}

steam_utils.sendData = function(data, messageType, lobby)

	--print("Sending data")
	--print(json.stringify(data))
	--print(tostring(bitser.dumps(data)))
	
	local encodedData = bitser.dumps(data)--json.stringify(data)
	if(encodedData ~= nil and (type(encodedData) == "string" or type(encodedData) == "number"))then
		if(type(encodedData) == "number")then
			encodedData = tostring(encodedData)
		end
		message_handlers[messageType](encodedData, lobby)
	else
		GamePrint("Failed to send data, encodedData is nil or not a string")
	end
end

steam_utils.sendDataToPlayer = function(data, player)
	local encodedData = bitser.dumps(data)--json.stringify(data)
	if(encodedData ~= nil and (type(encodedData) == "string" or type(encodedData) == "number"))then
		if(type(encodedData) == "number")then
			encodedData = tostring(encodedData)
		end
		local success, size = steam.networking.sendString(player, encodedData)
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

steam_utils.parseData = function(data)
	local decodedData = bitser.loads(data)--json.parse(data)
	return decodedData
end

return steam_utils