game_id = 881100

package.path = package.path .. ";./mods/evaisa.mp/lib/?.lua"
package.cpath = package.cpath .. ";./mods/evaisa.mp/bin/?.dll"
package.cpath = package.cpath .. ";./mods/evaisa.mp/bin/?.exe"

MP_VERSION = 1.1

base64 = require("base64")

msg = require("msg")
pretty = require("pretty_print")
local ffi = require "ffi"

local application_id = 943584660334739457LL

--GameSDK = require("game_sdk")

steam = require("luasteam")
require("physics")
steamutils = dofile_once("mods/evaisa.mp/lib/steamutils.lua")

pretty = require("pretty_print")


if type(Steam) == 'boolean' then Steam = nil end

instance = instance or nil

activity = activity or nil


game_in_progress = false

dofile("mods/evaisa.mp/files/scripts/lobby_handler.lua")
dofile_once("mods/evaisa.mp/files/scripts/utils.lua")
dofile_once("mods/evaisa.mp/files/scripts/gui_utils.lua")
dofile_once("data/scripts/lib/utilities.lua")
dofile_once("mods/evaisa.mp/lib/keyboard.lua")
dofile("mods/evaisa.mp/data/gamemodes.lua")
function OnWorldPreUpdate()
	if steam then 
		--pretty.table(steam.networking)
		lobby_code = lobby_code or nil
		dofile("mods/evaisa.mp/files/scripts/lobby_ui.lua")
		dofile("mods/evaisa.mp/files/scripts/chat_ui.lua")

		if(lobby_code ~= nil)then
			local lobby_gamemode = tonumber(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))

			--[[
			local players = get_players()
			
			if(players[1] ~= nil)then
				local player = players[1]
				
				GetUpdatedEntityID = function()
					return player
				end
				dofile("mods/evaisa.mp/files/scripts/player_update.lua")
			end
			]]

			if(game_in_progress)then
				local owner = steam.matchmaking.getLobbyOwner(lobby_code)

				if(owner == steam.user.getSteamID())then
					steam.matchmaking.setLobbyData(lobby_code, "update_seed", tostring(math.random(1, 1000000)))
				end
				
				gamemodes[lobby_gamemode].update(lobby_code)
				
				local messages = steam.networking.pollMessages() or {}
				for k, v in ipairs(messages)do
					if(gamemodes[lobby_gamemode].message)then
						gamemodes[lobby_gamemode].message(lobby_code, steamutils.parseData(v.data), v.user)
					end
				end
			end
		end
	end
end

function OnWorldPostUpdate()
	if steam then 
		--pretty.table(steam.networking)
		lobby_code = lobby_code or nil

		if(lobby_code ~= nil)then
			local lobby_gamemode = tonumber(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))

			if(game_in_progress)then
				gamemodes[lobby_gamemode].late_update(lobby_code)
				
				local messages = steam.networking.pollMessages() or {}
				for k, v in ipairs(messages)do
					if(gamemodes[lobby_gamemode].message)then
						gamemodes[lobby_gamemode].message(lobby_code, steamutils.parseData(v.data), v.user)
					end
				end
			end
		end
	end
end

function steam.matchmaking.onLobbyEnter(data)
	game_in_progress = false
	if(data.response ~= 2)then
		lobby_code = data.lobbyID
		print("Code set to: "..tostring(lobby_code).."["..type(lobby_code).."]")
		ModSettingSet("last_lobby_code", tostring(lobby_code))
		local lobby_gamemode = tonumber(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))

		if handleVersionCheck() then
			if handleGamemodeVersionCheck(lobby_code) then
				if(gamemodes[lobby_gamemode])then
					game_in_progress = steam.matchmaking.getLobbyData(lobby_code, "in_progress") == "true"
					if(game_in_progress)then
						gui_closed = true
					end
					gamemodes[lobby_gamemode].enter(lobby_code)
				end
			end
		end
	else
		msg.log("Invalid lobby ID")
	end
end

function steam.matchmaking.onLobbyDataUpdate(data)
	--pretty.table(data)
end

function steam.matchmaking.onLobbyChatUpdate(data)
	--pretty.table(data)
	handleBanCheck(data.userChanged)
end

function steam.matchmaking.onGameLobbyJoinRequested(data)
	---pretty.table(data)
	if(steam.extra.isSteamIDValid(data.lobbyID))then
		steam.matchmaking.leaveLobby(data.lobbyID)
		steam.matchmaking.joinLobby(data.lobbyID, function(e)
			if(e.response == 2)then
				steam.matchmaking.leaveLobby(e.lobbyID)
				invite_menu_open = false
				menu_status = status.main_menu
				initial_refreshes = 10
				show_lobby_code = false
				lobby_code = nil
			end
		end)
	else
		-- force refresh
		refreshLobbies()
	end
end


function steam.matchmaking.onLobbyChatMsgReceived(data)
	--pretty.table(data)
	--[[ 
		example data: 

		{
			lobbyID = 9223372036854775807,
			userID = 76361198523269435,
			type = 1,
			chatID = 1,
			fromOwner = true,
			message = "disconnect;76561198983269435;You were kicked from the lobby."
		}
	]]

	print(tostring(data.message))

	handleDisconnect(data)
	handleChatMessage(data)

	if(data.fromOwner and data.message == "start")then
		local lobby_gamemode = tonumber(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))
		
		if handleVersionCheck() then
			if handleGamemodeVersionCheck(lobby_code) then
				if(gamemodes[lobby_gamemode])then
					if(gamemodes[lobby_gamemode].start)then
						gamemodes[lobby_gamemode].start(lobby_code)
					end
					game_in_progress = true
					gui_closed = true
				else
					disconnect({
						lobbyID = lobby_code,
						message = "Gamemode missing: "..tostring(lobby_gamemode)
					})
				end
			end
		end
	elseif(data.fromOwner and data.message == "refresh")then
		local lobby_gamemode = tonumber(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))

		if handleVersionCheck() then
			if handleGamemodeVersionCheck(lobby_code) then
				if(gamemodes[lobby_gamemode])then
					game_in_progress = false
					if(gamemodes[lobby_gamemode].refresh)then
						gamemodes[lobby_gamemode].refresh(lobby_code)
					end
				else
					disconnect({
						lobbyID = lobby_code,
						message = "Gamemode missing: "..tostring(lobby_gamemode)
					})
				end
			end
		end
	end
end

--[[
function steam.networking.onP2PSessionRequest(data)
	pretty.table(data)
	--steam.networking.acceptP2PSessionWithUser(data.userID)
end

function steam.networking.onP2PSessionConnectFail(data)
	pretty.table(data)
end
]]

function steam.networking.onSessionRequest(steamID)
	--pretty.table(data)
	if(lobby_code ~= nil and steamutils.isInLobby(lobby_code, steamID))then
		local success = steam.networking.acceptSession(steamID)
		GamePrint("Session accepted: "..tostring(success))
	end
end

local get_content = ModTextFileGetContent
local set_content = ModTextFileSetContent

function OnMagicNumbersAndWorldSeedInitialized()
	gamemodes = dofile("mods/evaisa.mp/data/gamemodes.lua")
	
	steam.init()

	steam.friends.setRichPresence( "status", "Noita Online - Menu" )
end

function OnWorldInitialized()
	--pretty.table(physics)
	ModTextFileGetContent = get_content
	ModTextFileSetContent = set_content
end

function OnPlayerSpawned(player)

	-- replace contents of "mods/evaisa.forcerestart/filechange.txt" with a random number between 0 and 10000000
	--local file = io.open("mods/evaisa.forcerestart/filechange.txt", "w")
	--file:write(math.random(0, 10000000))
	--file:close()

	local lastCode = ModSettingGet("last_lobby_code")
	--print("Code: "..tostring(lastCode))
	if(steam)then
		if(lastCode ~= nil and lastCode ~= "")then
			local lobCode = steam.extra.parseUint64(lastCode)
			if(tostring(lobCode) ~= "0")then
				if(steam.extra.isSteamIDValid(lobCode))then
					steam.matchmaking.leaveLobby(lobCode)
				end
			end
			ModSettingRemove("last_lobby_code")
			lobby_code = nil
		end
	end

end