game_id = 881100

package.path = package.path .. ";./mods/evaisa.mp/lib/?.lua"
package.cpath = package.cpath .. ";./mods/evaisa.mp/bin/?.dll"
package.cpath = package.cpath .. ";./mods/evaisa.mp/bin/?.exe"

ModRegisterAudioEventMappings("mods/evaisa.mp/GUIDs.txt")

dofile("data/scripts/lib/coroutines.lua")

np = require("noitapatcher")
bitser = require("bitser")

MP_VERSION = 1.10
Version_string = "325897135236"

Checksum_passed = false
Spawned = false

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
local pollnet = require("pollnet")

--GamePrint("Making api call")

dofile("mods/evaisa.mp/files/scripts/debugging.lua")

http_get = function(url, callback)
	local req_sock = pollnet.http_get(url)

    async( function ()
		while(true)do
			if not req_sock then return end
			local happy, msg = req_sock:poll()
			if not happy then
			req_sock:close() -- good form
			req_sock = nil
			return
			end
			if msg then
				callback(msg)
				req_sock:close()
				break
			end
			wait(1)
		end
	end)

end

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

bytes_sent = 0
last_bytes_sent = 0
bytes_received = 0
last_bytes_received = 0

function OnWorldPreUpdate()
	wake_up_waiting_threads(1)
	math.randomseed( os.time() )

	if(steam and not Checksum_passed and Spawned)then
		GamePrint("Checksum failed, please ensure you are running the latest version of Noita Online")
	end

	if steam and Checksum_passed then 
		--pretty.table(steam.networking)
		lobby_code = lobby_code or nil
		dofile("mods/evaisa.mp/files/scripts/lobby_ui.lua")
		dofile("mods/evaisa.mp/files/scripts/chat_ui.lua")

		if(lobby_code ~= nil)then
			local lobby_gamemode = tonumber(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))

			if(GameGetFrameNum() % 60 == 0)then
				last_bytes_sent = bytes_sent
				last_bytes_received = bytes_received
				bytes_sent = 0
				bytes_received = 0
			end
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

			byte_rate_gui = byte_rate_gui or GuiCreate()
			GuiStartFrame(byte_rate_gui)
			local screen_width, screen_height = GuiGetScreenDimensions(byte_rate_gui)

			local output_string = last_bytes_sent < 1024 and tostring(last_bytes_sent) .. " B/s" or tostring(math.floor(last_bytes_sent / 1024)) .. " KB/s"

			local input_string = last_bytes_received < 1024 and tostring(last_bytes_received) .. " B/s" or tostring(math.floor(last_bytes_received / 1024)) .. " KB/s"
			
			local text_width, text_height = GuiGetTextDimensions(byte_rate_gui, "in: "..input_string.." | out: "..output_string)

			GuiText(byte_rate_gui, screen_width - text_width - 50, 1, "in: "..input_string.." | out: "..output_string)

			if(game_in_progress)then
				local owner = steam.matchmaking.getLobbyOwner(lobby_code)


				if(owner == steam.user.getSteamID())then
					if(GameGetFrameNum() % 2 == 0)then
						local seed = tostring(math.random(1, 1000000))
						
						steam.matchmaking.setLobbyData(lobby_code, "update_seed", seed)
					end
				end
				
				gamemodes[lobby_gamemode].update(lobby_code)
				
				local messages = steam.networking.pollMessages() or {}
				for k, v in ipairs(messages)do
					bytes_received = bytes_received + v.msg_size
					if(gamemodes[lobby_gamemode].message)then
						gamemodes[lobby_gamemode].message(lobby_code, steamutils.parseData(v.data), v.user)
					end
				end
			end
		end
	end
end

function OnProjectileFired(shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message, unknown1, unknown2, unknown3)
	if steam and Checksum_passed then 
		--pretty.table(steam.networking)
		lobby_code = lobby_code or nil

		if(lobby_code ~= nil)then
			local lobby_gamemode = tonumber(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))

			if(game_in_progress)then
				if(gamemodes[lobby_gamemode].on_projectile_fired)then
					gamemodes[lobby_gamemode].on_projectile_fired(lobby_code, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message, unknown1, unknown2, unknown3)
				end
			end
		end
	end
    
end

function OnProjectileFiredPost(shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message, unknown1, unknown2, unknown3)
	if steam and Checksum_passed then 
		--pretty.table(steam.networking)
		lobby_code = lobby_code or nil

		if(lobby_code ~= nil)then
			local lobby_gamemode = tonumber(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))

			if(game_in_progress)then
				if(gamemodes[lobby_gamemode].on_projectile_fired_post)then
					gamemodes[lobby_gamemode].on_projectile_fired_post(lobby_code, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message, unknown1, unknown2, unknown3)
				end
			end
		end
	end
	
end

function OnWorldPostUpdate()
	if steam and Checksum_passed then 
		--pretty.table(steam.networking)
		lobby_code = lobby_code or nil

		if(lobby_code ~= nil)then
			local lobby_gamemode = tonumber(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))

			if(game_in_progress)then
				gamemodes[lobby_gamemode].late_update(lobby_code)
				
				local messages = steam.networking.pollMessages() or {}
				for k, v in ipairs(messages)do
					bytes_received = bytes_received + v.msg_size
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
	print("Session request from ["..tostring(steam.friends.getFriendPersonaName(steamID)).."]")
	if(lobby_code ~= nil and steamutils.isInLobby(lobby_code, steamID))then
		local success = steam.networking.acceptSession(steamID)
		print("Session accepted: "..tostring(success))
	end
end

function steam.networking.onSessionFailed(steamID, endReason, endDebug, connectionDescription)
	if(lobby_code ~= nil and steamutils.isInLobby(lobby_code, steamID))then
		print("Session failed with ["..tostring(steam.friends.getFriendPersonaName(steamID)).."]: "..tostring(endReason))
		print("Debug: "..tostring(endDebug))
		print("Connection description: "..tostring(connectionDescription))
	end
end

local get_content = ModTextFileGetContent
local set_content = ModTextFileSetContent

function OnMagicNumbersAndWorldSeedInitialized()
	gamemodes = dofile("mods/evaisa.mp/data/gamemodes.lua")
	steam.init()
	steam.friends.setRichPresence( "status", "Noita Online - Menu" )

	http_get("http://evaisa.dev/noita-online-checksum.txt", function (data)
		
		Checksum_passed = data == Version_string

		if(Checksum_passed)then
			print("Checksum passed: "..tostring(data))
		end
	end)
end

function OnWorldInitialized()
	--pretty.table(physics)
	ModTextFileGetContent = get_content
	ModTextFileSetContent = set_content
end

function OnPlayerSpawned(player)

	print(pretty.table(bitser))

	-- replace contents of "mods/evaisa.forcerestart/filechange.txt" with a random number between 0 and 10000000
	--local file = io.open("mods/evaisa.forcerestart/filechange.txt", "w")
	--file:write(math.random(0, 10000000))
	--file:close()
	Spawned = true

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