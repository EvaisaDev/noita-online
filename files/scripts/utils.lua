players = players or {}

function AllPlayers()
	return players
end

function AddPlayer(player)
	players[player.id] = player
end

function RemovePlayer(player_id)
	players[player_id] = nil
end