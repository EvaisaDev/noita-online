game_id = 881100

package.path = package.path .. ";./mods/evaisa.mp/lib/?.lua"
package.path = package.path .. ";./mods/evaisa.mp/lib/?/init.lua"
package.cpath = package.cpath .. ";./mods/evaisa.mp/bin/?.dll"
package.cpath = package.cpath .. ";./mods/evaisa.mp/bin/?.exe"

local function load(modulename)
    local errmsg = ""
    for path in string.gmatch(package.path, "([^;]+)") do
      local filename = string.gsub(path, "%?", modulename)
      local file = io.open(filename, "rb")
      if file then
        -- Compile and return the module
        return assert(loadstring(assert(file:read("*a")), filename))
      end
      errmsg = errmsg.."\n\tno file '"..filename.."' (checked with custom loader)"
    end
    return errmsg
end

get_content = ModTextFileGetContent
set_content = ModTextFileSetContent

table.insert(package.loaders, 2, load)

ModRegisterAudioEventMappings("mods/evaisa.mp/GUIDs.txt")

dofile("data/scripts/lib/coroutines.lua")

np = require("noitapatcher")
bitser = require("bitser")
binser = require("binser")
profiler = dofile("mods/evaisa.mp/lib/profiler.lua")

MP_VERSION = 1.41
Version_string = "63479623967237"

rng = dofile("mods/evaisa.mp/lib/rng.lua")

Checksum_passed = false
Spawned = false

disable_print = false

dev_mode = false

base64 = require("base64")

msg = require("msg")
pretty = require("pretty_print")
local ffi = require "ffi"


local application_id = 943584660334739457LL

np.EnableGameSimulatePausing(false)
np.SilenceLogs("Warning - streaming didn\'t find any chunks it could stream away...\n")

--GameSDK = require("game_sdk")

steam = require("luasteam")
require("physics")
steamutils = dofile_once("mods/evaisa.mp/lib/steamutils.lua")
json = dofile_once("mods/evaisa.mp/lib/json.lua")

pretty = require("pretty_print")
--local pollnet = require("pollnet")

--GamePrint("Making api call")

dofile("mods/evaisa.mp/files/scripts/debugging.lua")

local request = require("luajit-request")
local extended_logging_enabled = (ModSettingGet("evaisa.betterlogger.extended_logging") == nil or ModSettingGet("evaisa.betterlogger.extended_logging") == true) and true or false

if(not (ModIsEnabled("evaisa.betterlogger") and extended_logging_enabled))then
	local old_print = print
	print = function(...)
		if not disable_print then
			local content = ...
			local source = debug.getinfo(2).source
		
			old_print("["..source.."]: "..tostring(content))

		end
	end
end

function OnPausedChanged(paused, is_wand_pickup)
	local players = EntityGetWithTag("player_unit") or {}

	if(players[1])then
		np.RegisterPlayerEntityId(players[1])
		local inventory_gui = EntityGetFirstComponentIncludingDisabled(players[1], "InventoryGuiComponent")
		local controls_component = EntityGetFirstComponentIncludingDisabled(players[1], "ControlsComponent")
		if(paused)then
			--EntitySetComponentIsEnabled(players[1], inventory_gui, false)
			np.EnableInventoryGuiUpdate(false)
			np.EnablePlayerItemPickUpper(false)
			ComponentSetValue2(controls_component, "enabled", false)
		else
			--EntitySetComponentIsEnabled(players[1], inventory_gui, true)
			np.EnableInventoryGuiUpdate(true)
			np.EnablePlayerItemPickUpper(true)
			ComponentSetValue2(controls_component, "enabled", true)
		end
	end

	if(paused)then
		GameAddFlagRun("game_paused")
		GamePrint("paused")
	else
		GameRemoveFlagRun("game_paused")
		GamePrint("unpaused")
	end
end

function IsPaused()
	return GameHasFlagRun("game_paused")
end

--[[
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

end]]

if type(Steam) == 'boolean' then Steam = nil end

instance = instance or nil

activity = activity or nil


game_in_progress = false

gamemode_settings = gamemode_settings or {}

dofile("mods/evaisa.mp/files/scripts/lobby_handler.lua")
dofile_once("mods/evaisa.mp/files/scripts/utils.lua")
dofile_once("mods/evaisa.mp/files/scripts/gui_utils.lua")
dofile_once("data/scripts/lib/utilities.lua")
dofile_once("mods/evaisa.mp/lib/keyboard.lua")

keys_down = {}

input = dofile_once("mods/evaisa.mp/lib/input.lua")
dofile("mods/evaisa.mp/data/gamemodes.lua")

bytes_sent = 0
last_bytes_sent = 0
bytes_received = 0
last_bytes_received = 0
active_members = {}
member_message_frames = {}
gamemode_index = 1

function FindGamemode(id)
	for k, v in pairs(gamemodes) do
		if(v.id == id)then
			return v, k
		end
	end
	return nil
end

local function ReceiveMessages(gamemode)
	local messages = steam.networking.pollMessages() or {}
	for k, v in ipairs(messages)do
		local data = steamutils.parseData(v.data)

		bytes_received = bytes_received + v.msg_size
		if(gamemode.message)then
			gamemode.message(lobby_code, data, v.user)
		end
		if(gamemode.received)then
			if(data[1] and type(data[1]) == "string" and data[2])then
				local event = data[1]
				local message = data[2]
				local frame = data[3]
				if(data[3])then
					-- check if frame is newer than member message frame
					if(not member_message_frames[tostring(v.user)] or member_message_frames[tostring(v.user)] <= frame)then
						member_message_frames[tostring(v.user)] = frame

						--GamePrint("Received event: "..event)

						gamemode.received(lobby_code, event, message, v.user)
					end
				else
					gamemode.received(lobby_code, event, message, v.user)
				end
			end
		end
	end
end

function OnWorldPreUpdate()
	local pressed, shift_held = hack_update_keys()

	keys_down = {}

	for _, key in ipairs(pressed) do
		keys_down[key] = true
	end

	wake_up_waiting_threads(1)
	--math.randomseed( os.time() )

	if(steam and not Checksum_passed and Spawned)then
		GamePrint("Checksum failed, please ensure you are running the latest version of Noita Online")
	end

	if steam and Checksum_passed then 
		--pretty.table(steam.networking)
		lobby_code = lobby_code or nil
		
		if(not IsPaused())then
			dofile("mods/evaisa.mp/files/scripts/lobby_ui.lua")
			dofile("mods/evaisa.mp/files/scripts/chat_ui.lua")
		end
		if(GameGetFrameNum() % (60 * 10) == 0)then
			steamutils.CheckLocalLobbyData()
		end

		if(lobby_code ~= nil)then
			local lobby_gamemode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))

			if(lobby_gamemode == nil)then
				return
			end

			--game_in_progress = steam.matchmaking.getLobbyData(lobby_code, "in_progress") == "true"

			--print("a")

			if(GameGetFrameNum() % 10 == 0)then
				-- get lobby members
				local current_members = {}
				for i = 1, steam.matchmaking.getNumLobbyMembers(lobby_code) do
					local h = steam.matchmaking.getLobbyMemberByIndex(lobby_code, i - 1)
					if(not active_members[tostring(h)])then
						active_members[tostring(h)] = h
					end
					if(not member_message_frames[tostring(h)])then
						member_message_frames[tostring(h)] = 0
					end
					current_members[tostring(h)] = true
				end
				for k, v in pairs(active_members) do
					if(not current_members[k])then
						active_members[k] = nil
						member_message_frames[k] = nil
						steam.networking.closeSession(v)
						print("Closed session with " .. steam.friends.getFriendPersonaName(v))
					end
				end
			end

			--print("b")

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

			--print("c")

			byte_rate_gui = byte_rate_gui or GuiCreate()
			GuiStartFrame(byte_rate_gui)
			local screen_width, screen_height = GuiGetScreenDimensions(byte_rate_gui)

			local output_string = last_bytes_sent < 1024 and tostring(last_bytes_sent) .. " B/s" or tostring(math.floor(last_bytes_sent / 1024)) .. " KB/s"

			local input_string = last_bytes_received < 1024 and tostring(last_bytes_received) .. " B/s" or tostring(math.floor(last_bytes_received / 1024)) .. " KB/s"
			
			local text_width, text_height = GuiGetTextDimensions(byte_rate_gui, "in: "..input_string.." | out: "..output_string)

			GuiText(byte_rate_gui, screen_width - text_width - 50, 1, "in: "..input_string.." | out: "..output_string)

			--print("d")

			--print("Game in progress: "..tostring(game_in_progress))

			if(game_in_progress)then

				--print("the hell??")

				local owner = steam.matchmaking.getLobbyOwner(lobby_code)

				--print("e")
				if(owner == steam.user.getSteamID())then
					if(GameGetFrameNum() % 2 == 0)then
						local seed = tostring(math.random(1, 1000000))
						
						--print("f")

						steam.matchmaking.setLobbyData(lobby_code, "update_seed", seed)
					end
				end

				lobby_gamemode.update(lobby_code)

				ReceiveMessages(lobby_gamemode)

			end
		end
	end
end

function OnProjectileFired(shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message, unknown1, unknown2, unknown3)

	if steam and Checksum_passed then 
		--pretty.table(steam.networking)
		lobby_code = lobby_code or nil

		if(lobby_code ~= nil)then
			local lobby_gamemode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))

			if(game_in_progress)then
				if(lobby_gamemode.on_projectile_fired)then
					lobby_gamemode.on_projectile_fired(lobby_code, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message, unknown1, unknown2, unknown3)
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
			local lobby_gamemode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))

			if(game_in_progress)then
				if(lobby_gamemode.on_projectile_fired_post)then
					lobby_gamemode.on_projectile_fired_post(lobby_code, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message, unknown1, unknown2, unknown3)
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
			local lobby_gamemode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))

			if(game_in_progress)then
				lobby_gamemode.late_update(lobby_code)
				
				--[[
				local messages = steam.networking.pollMessages() or {}
				for k, v in ipairs(messages)do
					bytes_received = bytes_received + v.msg_size
					if(lobby_gamemode.message)then
						lobby_gamemode.message(lobby_code, steamutils.parseData(v.data), v.user)
					end
				end
				]]

				ReceiveMessages(lobby_gamemode)
			end
		end
	end
end

function steam.matchmaking.onLobbyEnter(data)

	for k, v in pairs(active_members)do
		active_members[k] = nil
		member_message_frames[k] = nil
		steam.networking.closeSession(v)
		print("Closed session with " .. steam.friends.getFriendPersonaName(v))
	end

	game_in_progress = false
	if(data.response ~= 2)then
		lobby_code = data.lobbyID
		print("Code set to: "..tostring(lobby_code).."["..type(lobby_code).."]")
		ModSettingSet("last_lobby_code", tostring(lobby_code))
		local lobby_gamemode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))

		if handleVersionCheck() then
			if handleGamemodeVersionCheck(lobby_code) then
				if(lobby_gamemode)then
					game_in_progress = steam.matchmaking.getLobbyData(lobby_code, "in_progress") == "true"
					if(game_in_progress)then
						gui_closed = true
					end
					lobby_gamemode.enter(lobby_code)


					defineLobbyUserData(lobby_code)
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
		gamemode_settings = {}
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
		local lobby_gamemode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))
		
		if handleVersionCheck() then
			if handleGamemodeVersionCheck(lobby_code) then
				if(lobby_gamemode)then
					if(lobby_gamemode.start)then
						lobby_gamemode.start(lobby_code)
					end
					game_in_progress = true
					gui_closed = true
				else
					disconnect({
						lobbyID = lobby_code,
						message = "Gamemode missing: "..tostring(lobby_gamemode.id)
					})
				end
			end
		end
	elseif(data.fromOwner and data.message == "restart")then
		local lobby_gamemode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))
		
		if handleVersionCheck() then
			if handleGamemodeVersionCheck(lobby_code) then
				if(lobby_gamemode)then
					if(lobby_gamemode.start)then
						lobby_gamemode.start(lobby_code, false)
					end
					game_in_progress = true
					gui_closed = true
				else
					disconnect({
						lobbyID = lobby_code,
						message = "Gamemode missing: "..tostring(lobby_gamemode.id)
					})
				end
			end
		end	
	elseif(data.fromOwner and data.message == "refresh")then
		local lobby_gamemode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))

		if handleVersionCheck() then
			if handleGamemodeVersionCheck(lobby_code) then
				if(lobby_gamemode)then
					--game_in_progress = false

					for k, setting in ipairs(lobby_gamemode.settings or {})do
						gamemode_settings[setting.id] = steam.matchmaking.getLobbyData(lobby_code, "setting_"..setting.id)
					end

					if(lobby_gamemode.refresh)then
						lobby_gamemode.refresh(lobby_code)
					end
				else
					disconnect({
						lobbyID = lobby_code,
						message = "Gamemode missing: "..tostring(lobby_gamemode.id)
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

function OnMagicNumbersAndWorldSeedInitialized()
	gamemodes = dofile("mods/evaisa.mp/data/gamemodes.lua")
	steam.init()
	steam.friends.setRichPresence( "status", "Noita Online - Menu" )
	mod_data = ModData()

	local response = request.send("http://evaisa.dev/noita-online-checksum.txt")

	if(response ~= nil)then
		Checksum_passed = response.body == Version_string
		print("Checksum passed: "..tostring(response.body))
	end

--[[
	http_get("http://evaisa.dev/noita-online-checksum.txt", function (data)
		
		Checksum_passed = data == Version_string

		if(Checksum_passed)then
			print("Checksum passed: "..tostring(data))
		end
	end)]]
end

function OnWorldInitialized()
	--pretty.table(physics)
	ModTextFileGetContent = get_content
	ModTextFileSetContent = set_content
end

function OnPlayerSpawned(player)
	ModSettingRemove("lobby_data_store")
	GameRemoveFlagRun("game_paused")
	--ModSettingRemove("lobby_data_store")
	--print(pretty.table(bitser))

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
					gamemode_settings = {}
					steam.matchmaking.leaveLobby(lobCode)
				end
			end
			ModSettingRemove("last_lobby_code")
			lobby_code = nil
		end
	end

end