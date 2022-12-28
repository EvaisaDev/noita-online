gamemodes = {
	--[[{
		name = "CoopTest",
		enter = function(lobby) -- Runs when the player enters a lobby
			local seed = tonumber(steam.matchmaking.getLobbyData(lobby, "seed") or 1)
			SetWorldSeed( seed )
		end,
		start = function(lobby) -- Runs when the host presses the start game button.

		end,
		update = function(lobby) -- Runs every frame while the game is in progress.

		end,
		message = function(lobby, data, user)

		end,
	}]]
}