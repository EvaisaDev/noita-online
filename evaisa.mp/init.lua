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
		errmsg = errmsg .. "\n\tno file '" .. filename .. "' (checked with custom loader)"
	end
	return errmsg
end

get_content = ModTextFileGetContent
set_content = ModTextFileSetContent

dofile("mods/evaisa.mp/lib/ffi_extensions.lua")

table.insert(package.loaders, 2, load)

logger = require("logger")("noita_online_logs")
mp_log = logger.init("noita-online.log")
networking_log = logger.init("networking.log")
--debug_log = logger.init("debugging.log")

------ TRANSLATIONS -------

dofile("mods/evaisa.mp/lib/translations.lua")

register_localizations("mods/evaisa.mp/translations.csv", 2)

---------------------------


ModRegisterAudioEventMappings("mods/evaisa.mp/GUIDs.txt")

dofile_once("mods/evaisa.mp/files/scripts/gui_utils.lua")

dofile("mods/evaisa.mp/lib/timeofday.lua")
dofile("data/scripts/lib/coroutines.lua")

local utf8 = require 'lua-utf8'

np = require("noitapatcher")
bitser = require("bitser")
binser = require("binser")
profiler = dofile("mods/evaisa.mp/lib/profiler.lua")

popup = dofile("mods/evaisa.mp/files/scripts/popup.lua")

MP_VERSION = 1.441	
VERSION_FLAVOR_TEXT = "$mp_alpha"
noita_online_download = "https://discord.com/invite/zJyUSHGcme"
Version_string = "63479623967237"

rng = dofile("mods/evaisa.mp/lib/rng.lua")

Checksum_passed = false
in_game = false
Spawned = false
Starting = nil

disable_print = false

dev_mode = true

base64 = require("base64")

msg = require("msg")
pretty = require("pretty_print")
local ffi = require "ffi"

function RepairDataFolder()
	local data_folder_name = os.getenv('APPDATA'):gsub("\\Roaming", "") ..
		"\\LocalLow\\Nolla_Games_Noita\\save00\\evaisa.mp_data"
	-- remove the folder
	os.execute('del /q "' .. data_folder_name .. '\\*.*"')
	print("Repaired data folder.")
	GamePrint("Repairing data folder")
end

local serialization_version = "2"
if ((ModSettingGet("last_serialization_version") or "1") ~= serialization_version) then
	RepairDataFolder()
	ModSettingSet("last_serialization_version", serialization_version)
end

local application_id = 943584660334739457LL

np.InstallShootProjectileFiredCallbacks()
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
local extended_logging_enabled = (ModSettingGet("evaisa.betterlogger.extended_logging") == nil or ModSettingGet("evaisa.betterlogger.extended_logging") == true) and
	true or false

if (not (ModIsEnabled("evaisa.betterlogger") and extended_logging_enabled)) then
	local old_print = print
	print = function(...)
		if not disable_print then
			local content = ...
			local source = debug.getinfo(2).source
			local line = debug.getinfo(2).currentline

			old_print("[" .. source .. ":" .. tostring(line) .. "]: " .. tostring(content))
		end
	end
end

function OnPausedChanged(paused, is_wand_pickup)
	local players = EntityGetWithTag("player_unit") or {}

	if (players[1]) then
		np.RegisterPlayerEntityId(players[1])
		local inventory_gui = EntityGetFirstComponentIncludingDisabled(players[1], "InventoryGuiComponent")
		local controls_component = EntityGetFirstComponentIncludingDisabled(players[1], "ControlsComponent")
		if (paused) then
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

	if (paused) then
		GameAddFlagRun("game_paused")
		--GamePrint("paused")
	else
		GameRemoveFlagRun("game_paused")
		--GamePrint("unpaused")
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
dofile_once("data/scripts/lib/utilities.lua")
input = nil 

bytes_sent = 0
last_bytes_sent = 0
bytes_received = 0
last_bytes_received = 0
active_members = {}
member_message_frames = {}
gamemode_index = 1

gamemodes = {}

function FindGamemode(id)
	for k, v in pairs(gamemodes) do
		if (v.id == id) then
			return v, k
		end
	end
	return nil
end

local function ReceiveMessages(gamemode)
	local messages = steam.networking.pollMessages() or {}
	for k, v in ipairs(messages) do
		local data = steamutils.parseData(v.data)

		bytes_received = bytes_received + v.msg_size
		if (gamemode.message) then
			gamemode.message(lobby_code, data, v.user)
		end
		if (gamemode.received) then
			if (data[1] and type(data[1]) == "string" and data[2]) then
				local event = data[1]
				local message = data[2]
				local frame = data[3]
				if (data[3]) then
					-- check if frame is newer than member message frame
					if (not member_message_frames[tostring(v.user)] or member_message_frames[tostring(v.user)] <= frame) then
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

local spawned_popup = false
local init_cleanup = false
local connection_popup_open = false

function OnWorldPreUpdate()

	--input:Update()


	wake_up_waiting_threads(1)
	--math.randomseed( os.time() )

	if (not IsPaused()) then
		popup.update()
	end

	if (steam and not Checksum_passed and Spawned) then
		if (not spawned_popup) then
			GamePrint("Checksum failed, please ensure you are running the latest version of Noita Online")
			spawned_popup = true
			popup.create("update_message", GameTextGetTranslatedOrNot("$mp_outdated_warning_title"),
				GameTextGetTranslatedOrNot("$mp_outdated_warning_description"), {
					{
						text = GameTextGetTranslatedOrNot("$mp_get_updated_version"),
						callback = function()
							os.execute("start explorer \"" .. noita_online_download .. "\"")
						end
					},
					{
						text = GameTextGetTranslatedOrNot("$mp_close_popup"),
						callback = function()
						end
					}
				}, -6000)
		end
	end

	if steam and Checksum_passed and GameGetFrameNum() >= 60 then

		if(not steam.utils.loggedOn())then
			GamePrint("Failed to connect to steam servers, are you logged into steam friends list?")
			if(not connection_popup_open)then
				connection_popup_open = true
				popup.create("update_message", GameTextGetTranslatedOrNot("$mp_steam_connection_failed_title"),
				GameTextGetTranslatedOrNot("$mp_steam_connection_failed_description"), {
					{
						text = GameTextGetTranslatedOrNot("$mp_close_popup"),
						callback = function()
							connection_popup_open = false
						end
					}
				}, -6000)
			end
		end


		if(input == nil)then
			input = dofile_once("mods/evaisa.mp/lib/input.lua")
		end

		if(init_cleanup == false)then
			local lastCode = ModSettingGet("last_lobby_code")
			--print("Code: "..tostring(lastCode))
			if (steam) then
				if (lastCode ~= nil and lastCode ~= "") then
					local lobCode = steam.extra.parseUint64(lastCode)
					if (tostring(lobCode) ~= "0") then
						if (steam.extra.isSteamIDValid(lobCode)) then
							gamemode_settings = {}
							steam.matchmaking.leaveLobby(lobCode)
						end
					end
					ModSettingRemove("last_lobby_code")
					lobby_code = nil
				end
			end
			init_cleanup = true
		end

		--pretty.table(steam.networking)
		lobby_code = lobby_code or nil

		if (not IsPaused()) then
			dofile("mods/evaisa.mp/files/scripts/lobby_ui.lua")
			dofile("mods/evaisa.mp/files/scripts/chat_ui.lua")
		end
		if (GameGetFrameNum() % (60 * 10) == 0) then
			steamutils.CheckLocalLobbyData()
		end

		if (lobby_code ~= nil) then
			local lobby_gamemode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))

			if (lobby_gamemode == nil) then
				return
			end

			if(Starting ~= nil)then
				Starting = Starting - 1
				if(Starting < 0)then
					Starting = 0
				end
			end

			if(Starting == 0)then
				StartGame()
				Starting = nil
			end

			--game_in_progress = steam.matchmaking.getLobbyData(lobby_code, "in_progress") == "true"

			--print("a")

			if (GameGetFrameNum() % 10 == 0) then
				-- get lobby members
				local current_members = {}
				for i = 1, steam.matchmaking.getNumLobbyMembers(lobby_code) do
					local h = steam.matchmaking.getLobbyMemberByIndex(lobby_code, i - 1)
					if (not active_members[tostring(h)]) then
						active_members[tostring(h)] = h
					end
					if (not member_message_frames[tostring(h)]) then
						member_message_frames[tostring(h)] = 0
					end
					current_members[tostring(h)] = true
				end
				for k, v in pairs(active_members) do
					if (not current_members[k]) then
						active_members[k] = nil
						member_message_frames[k] = nil
						steam.networking.closeSession(v)
						mp_log:print("Closed session with " .. steamutils.getTranslatedPersonaName(v))
					end
				end
			end

			--print("b")

			if (GameGetFrameNum() % 60 == 0) then
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

			local output_string = last_bytes_sent < 1024 and tostring(last_bytes_sent) .. " B/s" or
				tostring(math.floor(last_bytes_sent / 1024)) .. " KB/s"

			local input_string = last_bytes_received < 1024 and tostring(last_bytes_received) .. " B/s" or
				tostring(math.floor(last_bytes_received / 1024)) .. " KB/s"

			local text_width, text_height = GuiGetTextDimensions(byte_rate_gui,
				"in: " .. input_string .. " | out: " .. output_string)

			GuiText(byte_rate_gui, screen_width - text_width - 50, 1, "in: " .. input_string .. " | out: " ..
				output_string)

			--print("d")

			--print("Game in progress: "..tostring(game_in_progress))

			if (game_in_progress) then
				--print("the hell??")

				local owner = steam.matchmaking.getLobbyOwner(lobby_code)



				--print("e")
				if (owner == steam.user.getSteamID()) then
					if (GameGetFrameNum() % 2 == 0) then
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

function OnProjectileFired(shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message,
						   unknown1, multicast_index, unknown3)
	if steam and Checksum_passed then
		--pretty.table(steam.networking)
		lobby_code = lobby_code or nil

		if (lobby_code ~= nil) then
			local lobby_gamemode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))

			if (game_in_progress) then
				if (lobby_gamemode.on_projectile_fired) then
					lobby_gamemode.on_projectile_fired(lobby_code, shooter_id, projectile_id, rng, position_x, position_y,
						target_x, target_y, send_message, unknown1, multicast_index, unknown3)
				end
			end
		end
	end
end

function OnProjectileFiredPost(shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message,
							   unknown1, multicast_index, unknown3)
	if steam and Checksum_passed then
		--pretty.table(steam.networking)
		lobby_code = lobby_code or nil

		if (lobby_code ~= nil) then
			local lobby_gamemode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))

			if (game_in_progress) then
				if (lobby_gamemode.on_projectile_fired_post) then
					lobby_gamemode.on_projectile_fired_post(lobby_code, shooter_id, projectile_id, rng, position_x,
						position_y, target_x, target_y, send_message, unknown1, multicast_index, unknown3)
				end
			end
		end
	end
end

function OnWorldPostUpdate()
	if steam and Checksum_passed then
		--pretty.table(steam.networking)
		lobby_code = lobby_code or nil

		if (lobby_code ~= nil) then
			local lobby_gamemode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))

			if (game_in_progress) then
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
	for k, v in pairs(active_members) do
		active_members[k] = nil
		member_message_frames[k] = nil
		steam.networking.closeSession(v)
		mp_log:print("Closed session with " .. steamutils.getTranslatedPersonaName(v))
	end
	input:Clear()
	Starting = nil
	in_game = false
	game_in_progress = false
	if (data.response ~= 2) then
		lobby_code = data.lobbyID
		mp_log:print("Code set to: " .. tostring(lobby_code) .. "[" .. type(lobby_code) .. "]")
		ModSettingSet("last_lobby_code", tostring(lobby_code))
		local lobby_gamemode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))

		if handleVersionCheck() and handleModCheck() then
			if handleGamemodeVersionCheck(lobby_code) then
				if (lobby_gamemode) then
					defineLobbyUserData(lobby_code)
					
					--[[game_in_progress = steam.matchmaking.getLobbyData(lobby_code, "in_progress") == "true"
					if(game_in_progress)then
						gui_closed = true
					end]]
					lobby_gamemode.enter(lobby_code)
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
	if (steam.extra.isSteamIDValid(data.lobbyID)) then
		gamemode_settings = {}
		steam.matchmaking.leaveLobby(data.lobbyID)
		steam.matchmaking.joinLobby(data.lobbyID, function(e)
			if (e.response == 2) then
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

function StartGame()
	local lobby_gamemode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))

	if handleVersionCheck() and handleModCheck() then
		if handleGamemodeVersionCheck(lobby_code) then
			if (lobby_gamemode) then

				spectating = steamutils.IsSpectator(lobby_code)

				--print("Are we spectating? " .. tostring(spectating))

				if (spectating) then
					if (lobby_gamemode.spectate ~= nil) then
						lobby_gamemode.spectate(lobby_code)
					elseif (lobby_gamemode.start ~= nil) then
						lobby_gamemode.start(lobby_code)
					end
				else
					if (lobby_gamemode.start ~= nil) then
						lobby_gamemode.start(lobby_code)
					end
				end

				in_game = true
				game_in_progress = true

				gui_closed = true
			else
				disconnect({
					lobbyID = lobby_code,
					message = string.format(GameTextGetTranslatedOrNot("$mp_gamemode_missing"), tostring(lobby_gamemode.id))
				})
			end
		end
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
	mp_log:print(tostring(data.message))

	handleDisconnect(data)
	handleChatMessage(data)

	local owner = steam.matchmaking.getLobbyOwner(lobby_code)


	if (data.fromOwner and data.message == "start" or data.message == "restart") then
		if(owner == steam.user.getSteamID())then
			StartGame()
		else
			Starting = 30
		end
	elseif (data.fromOwner and data.message == "refresh") then
		local lobby_gamemode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))

		if handleVersionCheck() and handleModCheck() then
			if handleGamemodeVersionCheck(lobby_code) then
				if (lobby_gamemode) then
					--game_in_progress = false

					for k, setting in ipairs(lobby_gamemode.settings or {}) do
						gamemode_settings[setting.id] = steam.matchmaking.getLobbyData(lobby_code, "setting_" ..
							setting.id)
					end

					if (lobby_gamemode.refresh) then
						lobby_gamemode.refresh(lobby_code)
					end
				else
					disconnect({
						lobbyID = lobby_code,
						message = string.format(GameTextGetTranslatedOrNot("$mp_gamemode_missing"), tostring(lobby_gamemode.id))--"Gamemode missing: " .. tostring(lobby_gamemode.id)
					})
				end
			end
		end
	elseif (owner == steam.user.getSteamID() and data.message == "spectate") then
		local user = data.userID
		print("Toggling spectator for " .. tostring(steamutils.getTranslatedPersonaName(user)))
		local spectating = steamutils.IsSpectator(lobby_code, user)
		steam.matchmaking.setLobbyData(lobby_code, tostring(user) .. "_spectator", spectating and "false" or "true")
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
	mp_log:print("Session request from [" .. tostring(steamutils.getTranslatedPersonaName(steamID)) .. "]")
	if (lobby_code ~= nil and steamutils.isInLobby(lobby_code, steamID)) then
		local success = steam.networking.acceptSession(steamID)
		mp_log:print("Session accepted: " .. tostring(success))
	end
end

function steam.networking.onSessionFailed(steamID, endReason, endDebug, connectionDescription)
	if (lobby_code ~= nil and steamutils.isInLobby(lobby_code, steamID)) then
		mp_log:print("Session failed with [" ..
			tostring(steamutils.getTranslatedPersonaName(steamID)) .. "]: " .. tostring(endReason))
		mp_log:print("Debug: " .. tostring(endDebug))
		mp_log:print("Connection description: " .. tostring(connectionDescription))
	end
end

function OnMagicNumbersAndWorldSeedInitialized()

	-- write to file
	-- ModTextFileGetContent("data/translations/common.csv")
	-- using io library to write to "noita_online_logs/translations.csv"
	local file = io.open("noita_online_logs/translations.csv", "w")
	local translations_content = ModTextFileGetContent("data/translations/common.csv")
	file:write(translations_content)
	file:close()
	
	--print(translations_content)

	__loaded["mods/evaisa.mp/data/gamemodes.lua"] = nil
	gamemodes = dofile("mods/evaisa.mp/data/gamemodes.lua")

	steam.init()
	steam.friends.setRichPresence("status", "Noita Online - Menu")



	mod_data = ModData()

	local response = request.send("http://evaisa.dev/noita-online-checksum.txt")

	if (response ~= nil) then
		Checksum_passed = response.body == Version_string
		mp_log:print("Checksum passed: " .. tostring(response.body))
	end

	--[[
	http_get("http://evaisa.dev/noita-online-checksum.txt", function (data)
		
		Checksum_passed = data == Version_string

		if(Checksum_passed)then
			mp_log:print("Checksum passed: "..tostring(data))
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

	--mp_log:print(bitser.loads(""))

	Spawned = true
end
