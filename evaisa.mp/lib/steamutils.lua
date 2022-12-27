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

return steam_utils