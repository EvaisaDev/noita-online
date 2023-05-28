gamemodes = {
	--[[
	{
		id = "cooptest",
		name = "CoopTest",
		version = 1,
		settings = { -- lobby settings
		},
		default_data = { -- lobby data which is set when a lobby is created
			key = "value",
		},
		refresh = function(lobby) -- runs when lobby settings are changed.

		end,
		enter = function(lobby) -- Runs when the player enters a lobby
			local seed = tonumber(steam.matchmaking.getLobbyData(lobby, "seed") or 1)
		end,
		start = function(lobby) -- Runs when the gamemode starts for non spectators (start button pressed or running game entered)

		end,
		spectate = function(lobby) -- Runs when the gamemode starts for spectators (start button pressed or running game entered)

		end,
		update = function(lobby) -- Runs every frame while the game is in progress.

		end,
		late_update = function(lobby) -- runs at the end of every frame while the game is in progress.

		end,
		leave = function(lobby) -- runs when the local player leaves the lobby

		end,
		disconnected = function(lobby, user) -- runs when a player disconnects

		end,
		received = function(lobby, event, message, user)

		end,
    	on_projectile_fired = function(lobby, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message, unknown1, multicast_index, unknown3)

		end,
    	on_projectile_fired_post = function(lobby, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message, unknown1, multicast_index, unknown3)

		end,
	}
	]]
}

return gamemodes