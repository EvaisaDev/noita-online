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

steam_utils.doesLobbyExist = function(lobby_id, callback)
	steam.matchmaking.addRequestLobbyListDistanceFilter(distance.worldwide)

	steam.matchmaking.requestLobbyList(function(data)
		lobby_count = data.count
		if(lobby_count > 0)then
			for i = 0, lobby_count-1 do

				local lobby = steam.matchmaking.getLobbyByIndex(i)
				if(lobby.lobbyID ~= nil)then
					if(lobby.lobbyID == lobby_id)then
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
	
    -- Compress the lobby ID
    lobby = steam.utils.compressSteamID(lobby)

    -- Create a key to store the data in data_store
    local data_key = tostring(lobby).."_"..key

    -- Store the value with the data_key in data_store
    data_store.Set(data_key, value)
    
    -- Get the saved list of "all_keys" from data_store
	local key_string = data_store.Get("all_keys")
    local keys = (key_string ~= nil and key_string ~= "") and bitser.loads(key_string) or {}

    -- Check if there's not an entry for the lobby in keys table
    if(keys[tostring(lobby)] == nil) then
        -- Create an entry for lobby in keys table and set the key as true
        keys[tostring(lobby)] = {
            [key] = true
        }
    else
        -- If the lobby already exists in keys, set the key as true
        keys[tostring(lobby)][key] = true
        
    end

    -- Store the updated keys in data_store with key "all_keys"

	--print(json.stringify(keys))

	local key_string = bitser.dumps(keys)

	--print("key_string: "..tostring(key_string))

    data_store.Set("all_keys", key_string)
end

steam_utils.GetLocalLobbyData = function(lobby, key)
    -- Compress the lobby ID
    lobby = steam.utils.compressSteamID(lobby)

    -- Create a key to get the data from data_store
    local data_key = tostring(lobby).."_"..key

    -- Retrieve the value for the data_key
    local value = data_store.Get(data_key)

    -- Return the value
    return value
end


steam_utils.CheckLocalLobbyData = function()
    -- destroy data for any lobbies which no longer exist

    -- Get the saved list of "all_keys" from data_store
	local key_string = data_store.Get("all_keys")
    local keys = (key_string ~= nil and key_string ~= "") and bitser.loads(key_string) or {}
    -- Iterate through the lobby keys
    for lob, lobby_keys in pairs(keys) do
        -- Check if the lobby no longer exists
		local decompressed_id = steam.utils.decompressSteamID(lob)

		steam_utils.doesLobbyExist(decompressed_id, function(exists)
			if(not exists)then
					
				print("Attempting to delete lobby data for lobby: "..tostring(lob))

				

				-- Iterate through the keys for the current lobby
				for key, _ in pairs(lobby_keys) do
					-- Remove each key-value pair for the current lobby
					data_store.Remove(tostring(lob).."_"..key)
				end
				-- Remove the current lobby from the "all_keys" list
				keys[lob] = nil

				--print("keys: "..json.stringify(keys))

				-- Store the updated keys in data_store
				data_store.Set("all_keys", bitser.dumps(keys))
			end
			
			--print("Does lobby exist?: ("..tostring(decompressed_id).."): "..tostring(exists))
		end)

    end


end

steam_utils.RemoveLocalLobbyData = function(lobby, key)
	-- Compress the lobby ID
	lobby = steam.utils.compressSteamID(lobby)
	local key_string = data_store.Get("all_keys")
    local keys = (key_string ~= nil and key_string ~= "") and bitser.loads(key_string) or {}

	data_store.Remove(tostring(lobby).."_"..key)

	for lob, lobby_keys in pairs(keys) do
		if(lob == lobby)then
			for k, _ in pairs(lobby_keys) do
				if(k == key)then
					keys[lob][key] = nil
					data_store.Set("all_keys", bitser.dumps(keys))
					return
				end
			end
		end
	end
end


--[[
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
]]

steam_utils.messageTypes = {
	AllPlayers = 0,
	OtherPlayers = 1,
	Clients = 2,
	Host = 3,
	Spectators = 4,
}

message_handlers = {
	[steam_utils.messageTypes.AllPlayers] = function (data, lobby, reliable) 
		local members = steamutils.getLobbyMembers(lobby)
		for k, member in pairs(members)do
			
			local success, size = 0, 0

			if(reliable)then
				success, size = steam.networking.sendString(member.id, data)
			else
				success, size = steam.networking.sendStringUnreliable(member.id, data)
			end
			
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
	[steam_utils.messageTypes.OtherPlayers] = function (data, lobby, reliable) 
		local members = steamutils.getLobbyMembers(lobby)
		for k, member in pairs(members)do
			if(member.id ~= steam.user.getSteamID())then
				local success, size = 0, 0

				if(reliable)then
					success, size = steam.networking.sendString(member.id, data)
				else
					success, size = steam.networking.sendStringUnreliable(member.id, data)
				end

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
	[steam_utils.messageTypes.Clients] = function (data, lobby, reliable) 
		local members = steamutils.getLobbyMembers(lobby)
		for k, member in pairs(members)do
			if(member.id ~= steam.user.getSteamID() and member.id ~= steam.matchmaking.getLobbyOwner(lobby))then
				local success, size = 0, 0

				if(reliable)then
					success, size = steam.networking.sendString(member.id, data)
				else
					success, size = steam.networking.sendStringUnreliable(member.id, data)
				end


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
	[steam_utils.messageTypes.Host] = function (data, lobby, reliable) 
		local success, size = 0, 0

		if(reliable)then
			success, size = steam.networking.sendString(steam.matchmaking.getLobbyOwner(lobby), data)
		else
			success, size = steam.networking.sendStringUnreliable(steam.matchmaking.getLobbyOwner(lobby), data)
		end

		success = tonumber(tostring(success))
		--GamePrint("Sent message of size " .. tostring(size) .. " to " .. steam.friends.getFriendPersonaName(steam.matchmaking.getLobbyOwner(lobby)) .. " (" .. tostring(success) .. ")")
		if(success ~= 1)then
			GamePrint("Failed to send message to Host (" .. tostring(success) .. ")")
		else
			bytes_sent = bytes_sent + size
		end
	end,
	[steam_utils.messageTypes.Spectators] = function (data, lobby, reliable)
		local members = steamutils.getLobbyMembers(lobby)
		for k, member in pairs(members)do
			local spectating = steam.matchmaking.getLobbyData(lobby_code, tostring(member.id).."_spectator") == "true"
			if(member.id ~= steam.user.getSteamID() and member.id ~= steam.matchmaking.getLobbyOwner(lobby) and spectating)then
				local success, size = 0, 0

				if(reliable)then
					success, size = steam.networking.sendString(member.id, data)
				else
					success, size = steam.networking.sendStringUnreliable(member.id, data)
				end

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

steam_utils.send = function(event, message, messageType, lobby, reliable)
	local data = {event,message}

	if(not reliable)then
		table.insert(data, GameGetFrameNum())
	end

	local encodedData = bitser.dumps(data)

	if(encodedData ~= nil and (type(encodedData) == "string" or type(encodedData) == "number"))then
		if(type(encodedData) == "number")then
			encodedData = tostring(encodedData)
		end
		message_handlers[messageType](encodedData, lobby, reliable)
	else
		GamePrint("Failed to send data, encodedData is nil or not a string")
	end
end

steam_utils.sendToPlayer = function(event, message, player, reliable)
	local data = {event,message}

	if(not reliable)then
		table.insert(data, GameGetFrameNum())
	end

	local encodedData = bitser.dumps(data)

	if(encodedData ~= nil and (type(encodedData) == "string" or type(encodedData) == "number"))then
		if(type(encodedData) == "number")then
			encodedData = tostring(encodedData)
		end
		local success, size = 0, 0

		if(reliable)then
			success, size = steam.networking.sendString(player, encodedData)
		else
			success, size = steam.networking.sendStringUnreliable(player, encodedData)
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


steam_utils.parseData = function(data)
	local decodedData = bitser.loads(data)--json.parse(data)
	
	return decodedData
end

return steam_utils