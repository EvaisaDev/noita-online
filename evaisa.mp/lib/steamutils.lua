steam_utils = {}

unidecode = require('unicorndecode')

username_cache = {}

last_language = nil

steam_utils.truncateNameStreaming = function(name, id)
	local name = name:sub(1, 1) .. "..."

	if lobby_code ~= nil and id ~= nil then
		local members = steam_utils.getLobbyMembersIDs(lobby_code, true)
		for i = 1, #members do
			if members[i] == id then
				name = "(" .. tostring(i) .. ")" .. name
				break
			end
		end
	end

	return name
end


steam_utils.getTranslatedPersonaName = function(steam_id, no_streamer_mode)
	
	if(steam_id == nil)then
		no_streamer_mode = true
	end

	local name = "Unknown"
	if(not (steam_id ~= nil and tonumber(tostring(steam_id)) == nil))then

		local language = GameTextGetTranslatedOrNot("$current_language")

		if (last_language ~= language) then
			username_cache = {}
			last_language = language
		end

		if(username_cache[steam_id] ~= nil)then
			name = username_cache[steam_id]
			goto continue
		end
		
		if(steam_id == nil)then
			name = steam.friends.getPersonaName()
			steam_id = 0
		else
			name = steam.friends.getFriendPersonaName(steam_id)
		end

		local supported = check_string(name)

		if(not supported)then
			name = unidecode.decode(name)
		end


		if (name == nil or name == "") then
			name = "Unknown"
		end
		
		-- cache name
		username_cache[steam_id] = name

		::continue::
	end
	
	-- truncate name after first letter if streamer mode is enabled
	if(ModSettingGet("evaisa.mp.streamer_mode") and not no_streamer_mode)then
		name = steam_utils.truncateNameStreaming(name, steam_id)
	end



	return name
end

steam_utils.getSteamFriends = function()
	local list = {}
	for i = 1, steam.friends.getFriendCount(0x04) do
		local h = steam.friends.getFriendByIndex(i - 1, 0x04)

		if(tonumber(tostring(h)) == nil)then
			goto continue
		end

		table.insert(list, { id = h, name = steam_utils.getTranslatedPersonaName(h) })
		::continue::
	end
	return list
end

function color_split(abgr_int)
    local r = bit.band(abgr_int, 0x000000FF)
    local g = bit.band(abgr_int, 0x0000FF00)
    local b = bit.band(abgr_int, 0x00FF0000)
    local a = bit.band(abgr_int, 0xFF000000)

    g = bit.rshift(g, 8)
    b = bit.rshift(b, 16)
    a = bit.rshift(a, 24)

    return r,g,b,a
end

function color_merge(r,g,b,a)
    local abgr_int = 0
    abgr_int = bit.bor(abgr_int, r)
    abgr_int = bit.bor(abgr_int, bit.lshift(g, 8))
    abgr_int = bit.bor(abgr_int, bit.lshift(b, 16))
    abgr_int = bit.bor(abgr_int, bit.lshift(a, 24))

    return abgr_int
end

local steam_id = nil
steam_utils.getSteamID = function()
	if (steam_id == nil) then
		steam_id = steam.user.getSteamID()
	end
	return steam_id
end

steam_utils.getNumLobbyMembers = function()
	return total_lobby_members
end

local lfs = require("lfs")
local fs = require("fs")

-- clear avatar cache directory
function clear_avatar_cache()
	local cache_folder = "data/evaisa.mp/cache/avatars/"
	-- create folder if it doesn't exist
	local path = ""
    for folder_name in cache_folder:gmatch("([^/]+)")do
        path = path .. folder_name
        fs.mkdir(path, true)
        path = path .. "/"
    end

	for file in lfs.dir(cache_folder) do
		if (file ~= "." and file ~= "..") then
			local f = cache_folder .. file
			os.remove(f)
		end
	end
end

cached_avatars = cached_avatars or {}

steam_utils.getUserAvatar = function(user_id)

	if(user_id == nil or ModSettingGet("evaisa.mp.streamer_mode"))then
		return "mods/evaisa.mp/files/gfx/ui/no_avatar.png"
	end

	if(cached_avatars[user_id] ~= nil)then
		return cached_avatars[user_id]
	end

	steam.friends.requestUserInformation(user_id, false)

	local handle = steam.friends.getSmallFriendAvatar(user_id)
	if(handle == nil)then
		cached_avatars[user_id] = "mods/evaisa.mp/files/gfx/ui/no_avatar.png"
	end

	local cache_folder = "data/evaisa.mp/cache/avatars/"

	local path = ""
    for folder_name in cache_folder:gmatch("([^/]+)")do
        path = path .. folder_name
        fs.mkdir(path, true)
        path = path .. "/"
    end

	local image_data = steam.utils.getImageData(handle)
	local width, height = steam.utils.getImageSize(handle)

	if(image_data == nil)then
		cached_avatars[user_id] = "mods/evaisa.mp/files/gfx/ui/no_avatar.png"
		return "mods/evaisa.mp/files/gfx/ui/no_avatar.png"
	end

	local path = cache_folder .. tostring(user_id) .. ".png"

	local png = pngencoder(width, height)

	for y = 1, height do
		for x = 1, width do
			local index = (y - 1) * width + x
			local pixel = image_data[index]
			local r, g, b, a = color_split(pixel)
			
			png:write { r, g, b }
		end
	end

	local data = table.concat(png.output)

	local file = io.open(path, "wb")
	file:write(data)
	file:close()

	cached_avatars[user_id] = path

	return path
end

lobby_members = lobby_members or {}
lobby_members_no_spectators = lobby_members_no_spectators or {}
was_streamer_mode = was_streamer_mode or false

steam_utils.getLobbyMembers = function(lobby_id, include_spectators, update_cache)
	-- implement cache

	if(was_streamer_mode and not ModSettingGet("evaisa.mp.streamer_mode"))then
		update_cache = true
		was_streamer_mode = false
	elseif(not was_streamer_mode and ModSettingGet("evaisa.mp.streamer_mode"))then
		update_cache = true
		was_streamer_mode = true
	end
	

	if(not update_cache)then
		if(include_spectators and lobby_members[tostring(lobby_id)])then
			--print("Returning cached lobby members")
			return lobby_members[tostring(lobby_id)]
		elseif(not include_spectators and lobby_members_no_spectators[tostring(lobby_id)])then
			--print("Returning cached lobby members without spectators")
			return lobby_members_no_spectators[tostring(lobby_id)]
		end
	end

	lobby_members[tostring(lobby_id)] = {}
	lobby_members_no_spectators[tostring(lobby_id)] = {}

	for i = 1, steam.matchmaking.getNumLobbyMembers(lobby_id) do
		local h = steam.matchmaking.getLobbyMemberByIndex(lobby_id, i - 1)

		-- if spectator
		local is_spectator = steam.matchmaking.getLobbyData(lobby_id, tostring(h) .. "_spectator") == "true"

		if(not is_spectator)then
			table.insert(lobby_members_no_spectators[tostring(lobby_id)], {
				id = h, 
				name = steam_utils.getTranslatedPersonaName(h, h == steam_utils.getSteamID()),
				is_spectator = is_spectator
			})
		end

		table.insert(lobby_members[tostring(lobby_id)], {
			id = h, 
			name = steam_utils.getTranslatedPersonaName(h, h == steam_utils.getSteamID()),
			is_spectator = is_spectator
		})
	end

	if(include_spectators)then
		return lobby_members[tostring(lobby_id)]
	else
		return lobby_members_no_spectators[tostring(lobby_id)]
	end
	
end

steam_utils.updateCacheSpectators = function(lobby_id)
	if(lobby_members[tostring(lobby_id)] == nil)then
		return
	end
	for i = 1, #lobby_members[tostring(lobby_id)] do
		local member = lobby_members[tostring(lobby_id)][i]
		member.is_spectator = steam.matchmaking.getLobbyData(lobby_id, tostring(member.id) .. "_spectator") == "true"
	end
end

lobby_members_ids = lobby_members_ids or {}

steam_utils.getLobbyMembersIDs = function(lobby_id, include_spectators, update_cache)
	-- implement cache
	if(not update_cache and lobby_members_ids[tostring(lobby_id)])then
		goto return_list
	end

	lobby_members_ids[tostring(lobby_id)] = {}

	for i = 1, steam.matchmaking.getNumLobbyMembers(lobby_id) do
		local h = steam.matchmaking.getLobbyMemberByIndex(lobby_id, i - 1)

		table.insert(lobby_members_ids[tostring(lobby_id)], h)
	end

	::return_list::

	local out = {}

	for i = 1, #lobby_members_ids[tostring(lobby_id)] do
		local member = lobby_members_ids[tostring(lobby_id)][i]
		table.insert(out, member)
	end

	return out

end

steam_utils.getPlayerCount = function(lobby, include_spectators)
	local members = steamutils.getLobbyMembers(lobby, include_spectators)
	return #members
end

steam_utils.IsOwner = function(user)
	if(user ~= nil)then
		return steam_utils.getLobbyOwner() == user
	end
	return steam_utils.getLobbyOwner() == steam_utils.getSteamID()
end

steam_utils.getLobbyOwner = function()
	if(lobby_code == nil)then
		return nil
	end
	if(lobby_owner == nil)then
		lobby_owner = steam.matchmaking.getLobbyOwner(lobby_code)
	end
	return lobby_owner
end

steam_utils.IsSpectator = function(lobby_id, player_id)
	local spectating = steam.matchmaking.getLobbyData(lobby_id, tostring(player_id and player_id or steam_utils.getSteamID()) .. "_spectator") ==
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


steam_utils.Leave = function(lobby_id)

	local active_mode = FindGamemode(steam.matchmaking.getLobbyData(lobby_id, "gamemode"))
	if (active_mode) then
		active_mode.leave(lobby_id)
	end

	cached_lobby_data = {}
	cached_lobby_user_data = {}
	initial_refreshes = 10
	delay.reset()
	is_awaiting_spectate = false
	gui_closed = false
	gamemode_settings = {}
	steam.matchmaking.leaveLobby(lobby_id)
	invite_menu_open = false
	show_lobby_code = false
	lobby_code = nil
	banned_members = {}
end


local datastore = dofile("mods/evaisa.mp/lib/data_store.lua")
local data_store = datastore.new(os.getenv('APPDATA'):gsub("\\Roaming", "").."\\LocalLow\\Nolla_Games_Noita\\save00\\evaisa.mp_data")
local persistent_bans = datastore.new(os.getenv('APPDATA'):gsub("\\Roaming", "").."\\LocalLow\\Nolla_Games_Noita\\save00\\evaisa.mp_bans")

steam_utils.IsPlayerBlacklisted = function(steam_id)
	local value = persistent_bans.Get(tostring(steam_id))
	if (value == nil) then
		return false
	end
	return true
end

steam_utils.BlacklistPlayer = function(steam_id)
	persistent_bans.Set(tostring(steam_id), steam.utils.compressSteamID(steam_id))
end

steam_utils.UnblacklistPlayer = function(steam_id)
	persistent_bans.Remove(tostring(steam_id))
end

steam_utils.GetBlacklistedPlayers = function()
	local keys = persistent_bans.Keys()
	local out = {}
	for k, v in pairs(keys) do
		local value = persistent_bans.Get(v)
		if (value ~= nil) then
			table.insert(out, steam.utils.decompressSteamID(value))
		end
	end
	return out
end

steam_utils.AddLobbyFlag = function(lobby, flag)
	local flags = steam.matchmaking.getLobbyData(lobby, "flags")
	if (flags == nil or flags == "") then
		flags = flag
	else
		flags = flags .. "," .. flag
	end

	print("Added flag: " .. flag)

	steam_utils.TrySetLobbyData(lobby, "flags", flags)
end

steam_utils.RemoveLobbyFlag = function(lobby, flag)
	local flags = steam.matchmaking.getLobbyData(lobby, "flags")
	if (flags == nil or flags == "") then
		return
	end
	local flag_table = {}
	for f in flags:gmatch("([^,]+)") do
		if (f ~= flag) then
			table.insert(flag_table, f)
		end
	end
	local new_flags = table.concat(flag_table, ",")

	print("Removed flag: " .. flag)

	steam_utils.TrySetLobbyData(lobby, "flags", new_flags)
end

steam_utils.GetLobbyFlags = function(lobby)
	local flags = steam.matchmaking.getLobbyData(lobby, "flags")
	if (flags == nil or flags == "") then
		return {}
	end
	local out = {}
	for f in flags:gmatch("([^,]+)") do
		table.insert(out, f)
	end
	return out
end

steam_utils.HasLobbyFlag = function(lobby, flag)
	local flags = steam.matchmaking.getLobbyData(lobby, "flags")
	local has_flag = false
	if (flags ~= nil and flags ~= "") then

		for f in flags:gmatch("([^,]+)") do
			if (f == flag) then
				has_flag = true
				break
			end
		end
	end

	print("Has flag: " .. tostring(has_flag))
	return has_flag
end

steam_utils.GetLobbyData = function(key)
	if(lobby_code == nil)then
		return nil
	end
	local value = cached_lobby_data[key]
	if (value == nil or value == "") then
		-- run getLobbyData to make sure
		local code = lobby_code
		value = steam.matchmaking.getLobbyData(code, key)

		cached_lobby_data[key] = value

		return value
	end
	return value
end


steam_utils.TrySetLobbyData = function(lobby, key, value)
	if(cached_lobby_data[key] == value)then
		return
	end
	try(function()
		local result = steam.matchmaking.setLobbyData(lobby, key, value)
		-- if retult is boolean and true
		if (type(result) == "boolean" and result) then
			cached_lobby_data[key] = value
		end
	end).catch(function(err)
		mp_log:print("Failed to set lobby data: " .. key .. " = " .. value)
		mp_log:print(err)
	end)
end

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
	local keys = (key_string ~= nil and key_string ~= "") and bitser.loads(key_string) or {}
	
	if(type(keys) ~= "table")then
		keys = {}
	end

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

	local key_string = bitser.dumps(keys)

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

lobby_data_cache = lobby_data_cache or {}

steam_utils.CheckLocalLobbyData = function()
	-- Get saved list of "all_keys" from data_store
	local key_string = data_store.Get("all_keys")
	local keys = (key_string ~= nil and key_string ~= "") and bitser.loads(key_string)

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
	local updated_key_string = bitser.dumps(keys)
	data_store.Set("all_keys", updated_key_string)
end

steam_utils.RemoveLocalLobbyData = function(lobby, key)
	-- Compress the lobby ID
	lobby = steam.utils.compressSteamID(lobby)
	local key_string = data_store.Get("all_keys")
	local keys = (key_string ~= nil and key_string ~= "") and bitser.loads(key_string) or {}

	data_store.Remove(tostring(lobby) .. "_" .. key)

	for lob, lobby_keys in pairs(keys) do
		if (lob == lobby) then
			for k, _ in pairs(lobby_keys) do
				if (k == key) then
					keys[lob][key] = nil
					data_store.Set("all_keys", bitser.dumps(keys))
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
	[steam_utils.messageTypes.AllPlayers] = function(data, lobby, reliable, include_spectators, event)
		local members = steamutils.getLobbyMembers(lobby, include_spectators)
		for k, member in pairs(members) do
			--networking_log:print("Sending message ["..bitser.loads(data)[1].."] to " .. member.name)
			
			local success, size = 0, 0

			if(member.id == steam_utils.getSteamID())then
				HandleMessage({msg_size = 0, user = steam_utils.getSteamID(), data = data})
				goto continue
			end

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
				local id = event
				if(id ~= nil and type(id) == "string")then
					if(bytes_sent_per_type[id] == nil)then
						bytes_sent_per_type[id] = 0
					end
					bytes_sent_per_type[id] = bytes_sent_per_type[id] + size
				end
				bytes_sent = bytes_sent + size
			end

			::continue::
		end
	end,
	[steam_utils.messageTypes.OtherPlayers] = function(data, lobby, reliable, include_spectators, event)
		local members = steamutils.getLobbyMembers(lobby, include_spectators)
		for k, member in pairs(members) do
			if (member.id ~= steam_utils.getSteamID()) then
				--networking_log:print("Sending message ["..bitser.loads(data)[1].."] to " .. member.name)
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
					local id = event
					if(id ~= nil and type(id) == "string")then
						if(bytes_sent_per_type[id] == nil)then
							bytes_sent_per_type[id] = 0
						end
						bytes_sent_per_type[id] = bytes_sent_per_type[id] + size
					end
					bytes_sent = bytes_sent + size
				end
			end
		end
	end,
	[steam_utils.messageTypes.Clients] = function(data, lobby, reliable, include_spectators, event)
		local members = steamutils.getLobbyMembers(lobby, include_spectators)
		for k, member in pairs(members) do
			if (member.id ~= steam_utils.getSteamID() and member.id ~= steam.matchmaking.getLobbyOwner(lobby)) then
				--networking_log:print("Sending message ["..bitser.loads(data)[1].."] to " .. member.name)
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
					local id = event
					if(id ~= nil and type(id) == "string")then
						if(bytes_sent_per_type[id] == nil)then
							bytes_sent_per_type[id] = 0
						end
						bytes_sent_per_type[id] = bytes_sent_per_type[id] + size
					end
					bytes_sent = bytes_sent + size
				end
			end
		end
	end,
	[steam_utils.messageTypes.Host] = function(data, lobby, reliable, include_spectators, event)
		--networking_log:print("Sending message ["..bitser.loads(data)[1].."] to Host")
		local success, size = 0, 0

		-- if we are the player hosting the lobby, send the message to ourselves

		if(steam_utils.IsOwner())then
			HandleMessage({msg_size = 0, user = steam_utils.getSteamID(), data = data})
			goto continue
		end


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
			local id = event
			if(id ~= nil and type(id) == "string")then
				if(bytes_sent_per_type[id] == nil)then
					bytes_sent_per_type[id] = 0
				end
				bytes_sent_per_type[id] = bytes_sent_per_type[id] + size
			end
			bytes_sent = bytes_sent + size
		end

		::continue::
	end,
	[steam_utils.messageTypes.Spectators] = function(data, lobby, reliable, include_spectators, event)
		local members = steamutils.getLobbyMembers(lobby, true)
		for k, member in pairs(members) do
			local spectating = steam.matchmaking.getLobbyData(lobby_code, tostring(member.id) .. "_spectator") == "true"
			if (member.id ~= steam_utils.getSteamID() and spectating) then
				--networking_log:print("Sending message ["..bitser.loads(data)[1].."] to " .. member.name)
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
					local id = event
					if(id ~= nil and type(id) == "string")then
						if(bytes_sent_per_type[id] == nil)then
							bytes_sent_per_type[id] = 0
						end
						bytes_sent_per_type[id] = bytes_sent_per_type[id] + size
					end
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
		message_handlers[messageType](encodedData, lobby, reliable, include_spectators, event)
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

local function split(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(str, delimiter, from)
    while delim_from do
        table.insert(result, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delimiter, from)
    end
    table.insert(result, string.sub(str, from))
    return result
end


steam_utils.parseData = function(data)
	local decodedData = nil
	
	local str = data--zstd:decompress(data)

	decodedData = bitser.loads(str)

	return decodedData
end

return steam_utils
