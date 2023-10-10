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

string.bytes = function(str)
	local bytes = 0
	for i = 1, #str do
		bytes = bytes + str:byte(i)
	end
	return bytes
end

get_content = ModTextFileGetContent
set_content = ModTextFileSetContent

dofile("mods/evaisa.mp/lib/ffi_extensions.lua")

table.insert(package.loaders, 2, load)

logger = require("logger")("noita_online_logs")
mp_log = logger.init("noita-online.log")
networking_log = logger.init("networking.log")
debug_log = logger.init("debugging.log")
debug_info = logger.init("debug_info.log", nil, true)

------ TRANSLATIONS -------

dofile("mods/evaisa.mp/lib/translations.lua")

register_localizations("mods/evaisa.mp/translations.csv", 2)

---------------------------



local function readWord(file)
	local byte1, byte2 = file:read(1), file:read(1)
	if not byte1 or not byte2 then
	return nil
	end
	return byte1:byte() + byte2:byte() * 256
end

local function readDword(file)
	local word1, word2 = readWord(file), readWord(file)
	if not word1 or not word2 then
	return nil
	end
	return word1 + word2 * 65536
end

local function checkLAA(filename)
	local file, err = io.open(filename, "rb")
	if not file then
	  print("Error opening file: " .. err)
	  return false
	end
  
	file:seek("set", 0x3C)
	local peOffset = readDword(file)
  
	file:seek("set", peOffset + 4) -- Go to IMAGE_FILE_HEADER
	local characteristicsOffset = peOffset + 22 -- Offset of "Characteristics" field
  
	file:seek("set", characteristicsOffset)
	local characteristics = readWord(file)
  
	file:close()
  
	return bit.band(characteristics, 0x20) == 0x20 -- Properly check the IMAGE_FILE_LARGE_ADDRESS_AWARE flag
end

local function LAAPatch()
	local batch = string.format([[
		@echo off
		taskkill /F /IM "noita.exe"
		timeout /t 5

		echo Running LAA-enabling script

		start mods/evaisa.mp/bin/laac.exe noita.exe

		echo LAA-enabling script finished, starting Noita

		timeout /t 5

		start noita.exe

		echo You can close this window.
	]])

	--

	local batchname = "enablelaa.bat"
	local batchfile = io.open(batchname, "w")
	batchfile:write(batch)
	batchfile:close()

	os.execute("start "..batchname)
end
lobby_data_last_frame = {}
lobby_data_updated_this_frame = {}

ModRegisterAudioEventMappings("mods/evaisa.mp/GUIDs.txt")

dofile_once("mods/evaisa.mp/files/scripts/gui_utils.lua")

dofile("data/scripts/lib/coroutines.lua")

local utf8 = require 'lua-utf8'

np = require("noitapatcher")
bitser = require("bitser")
binser = require("binser")
profiler = dofile("mods/evaisa.mp/lib/profiler.lua")
delay = dofile("mods/evaisa.mp/lib/delay.lua")

popup = dofile("mods/evaisa.mp/files/scripts/popup.lua")

MP_VERSION = 1.62	
VERSION_FLAVOR_TEXT = "$mp_beta"
noita_online_download = "https://github.com/EvaisaDev/noita-online/releases"
Version_string = "63479623967237"

debug_info:print("Version: " .. tostring(MP_VERSION))

rng = dofile("mods/evaisa.mp/lib/rng.lua")
rand = nil

in_game = false
Spawned = false
Starting = nil

disable_print = false

dev_mode = false

debug_info:print("Dev mode: " .. tostring(dev_mode))

function GetNoitaVersionHash()
	local file = "_version_hash.txt"
	local f = io.open(file, "r")
	if f then
		local hash = f:read("*all")
		f:close()
		return hash
	end
	return nil
end

local noita_version_hash = GetNoitaVersionHash()

-- strip newlines and such from hash
noita_version_hash = noita_version_hash:gsub("%s+", "")

debug_info:print("Noita hash: " .. tostring(noita_version_hash))

last_noita_version = ModSettingGet("evaisa.mp.last_noita_version_hash") or ""
laa_check_done = true
if(noita_version_hash ~= nil)then
	mp_log:print("Noita version hash: " .. noita_version_hash)
	if(last_noita_version ~= noita_version_hash)then
		ModSettingSet("evaisa.mp.last_noita_version_hash", noita_version_hash)
		--laa_check_done = false
	else
		--laa_check_done = true
	end
end
base64 = require("base64")

msg = require("msg")
pretty = require("pretty_print")
local ffi = require "ffi"

debug_info:print("Beta build: " .. tostring(GameIsBetaBuild()))
debug_info:print("Using controller: " .. tostring(GameGetIsGamepadConnected()))

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
np.InstallDamageDetailsPatch()
np.SilenceLogs("Warning - streaming didn\'t find any chunks it could stream away...\n")
--[[np.EnableExtendedLogging(true)
np.EnableLogFiltering(true)

function FilterLog(source, function_name, line, ...)
	debug_log:print(source .. " " .. function_name .. " " .. line .. " " .. table.concat({...}, " "))
	return false
end]]

--GameSDK = require("game_sdk")

steam = require("luasteam")
--require("physics")
steamutils = dofile_once("mods/evaisa.mp/lib/steamutils.lua")
json = dofile_once("mods/evaisa.mp/lib/json.lua")

pretty = require("pretty_print")

local is_invalid_version = (PhysicsBodyIDGetBodyAABB == nil)

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
bindings = nil

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

local function ReceiveMessages(gamemode, ignore)
	local messages = steam.networking.pollMessages() or {}
	if(ignore)then
		return
	end
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

----- debugging spell stuff ------


--ModTextFileSetContent("mods/gun_flag.lua", [[
--for i, action in ipairs(actions)do
--	if(i > 4)then
--		action.spawn_requires_flag = action.id
--	end
--end
--]])

--ModLuaFileAppend("data/scripts/gun/gun_actions.lua", "mods/gun_flag.lua")

----------------------------------

local spawned_popup = false
local init_cleanup = false
local connection_popup_open = false
local connection_popup_was_open_timer = 0
local laa_check_busy = false
local invalid_version_popup_open = false

function OnWorldPreUpdate()

	--input:Update()

	wake_up_waiting_threads(1)
	--math.randomseed( os.time() )

	if (not IsPaused()) then
		popup.update()
	end


	if steam and GameGetFrameNum() >= 60 then


		--[[if(not laa_check_done)then
			laa_enabled = checkLAA("noita.exe")
			print("LAA: " .. tostring(laa_enabled))

			
			if(not laa_enabled)then
				laa_check_busy = true
				popup.create("laa_message", GameTextGetTranslatedOrNot("$mp_laa_message"), {
					GameTextGetTranslatedOrNot("$mp_laa_description"),
					{
						text = GameTextGetTranslatedOrNot("$mp_laa_warning"),
						color = {217 / 255,52 / 255,52 / 255, 1}
					}
				}, {
					{
						text = GameTextGetTranslatedOrNot("$mp_laa_patch"),
						callback = function()
							LAAPatch("noita.exe", "noita")
							laa_check_busy = false
						end
					},
					{
						text = GameTextGetTranslatedOrNot("$mp_close_popup"),
						callback = function()
							laa_check_busy = false
						end
					},
				}, -6000)
			end
			laa_check_done = true
		end]]

		if(is_invalid_version)then
			
			if(not invalid_version_popup_open)then
				invalid_version_popup_open = true
				popup.create("invalid_version_message", GameTextGetTranslatedOrNot("$mp_invalid_version"),
				GameTextGetTranslatedOrNot("$mp_invalid_version_description"), {
					{
						text = GameTextGetTranslatedOrNot("$mp_close_popup"),
						callback = function()
							invalid_version_popup_open = false
						end
					}
				}, -6000)

			end
			return
		end
		
		if(not laa_check_busy)then
			if(not steam.utils.loggedOn())then
				if(GameGetFrameNum() % (60 * 5) == 0)then
					GamePrint("Failed to connect to steam servers, are you logged into steam friends list?")
				end
				
				if(connection_popup_was_open_timer > 0)then
					connection_popup_was_open_timer = connection_popup_was_open_timer - 1
				end



				if(not connection_popup_open and connection_popup_was_open_timer <= 0)then
					connection_popup_open = true
					connection_popup_was_open_timer = 60 * 60 * 2
					popup.create("connection_message", GameTextGetTranslatedOrNot("$mp_steam_connection_failed_title"),
					GameTextGetTranslatedOrNot("$mp_steam_connection_failed_description"), {
						{
							text = GameTextGetTranslatedOrNot("$mp_close_popup"),
							callback = function()
								if(lobby_code ~= nil)then
									connection_popup_open = false
								end
							end
						}
					}, -6000)
				end
			end


			if(input == nil)then
				input = dofile_once("mods/evaisa.mp/lib/input.lua")
			end

			if(bindings == nil)then
				bindings = dofile_once("mods/evaisa.mp/lib/keybinds.lua")
				bindings:RegisterBinding("chat_submit", "Noita Online", "Chat Send", "Key_RETURN", "key", false, true, false, false)
				bindings:RegisterBinding("chat_submit2", "Noita Online", "Chat Send Alt", "Key_KP_ENTER", "key", false, true, false, false)
				bindings:RegisterBinding("chat_open", "Noita Online", "Open Chat", "Key_t", "key", false, true, false, false)
			
				-- loop through gamemodes
				for k, v in ipairs(gamemodes) do
					if(v.binding_register ~= nil)then
						v.binding_register(bindings)
					end
				end
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
			
			ResetIDs()
			ResetWindowStack()

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

				delay.update()

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
							-- run gamemode on_leave
							if (lobby_gamemode and lobby_gamemode.disconnected ~= nil) then
								lobby_gamemode.disconnected(lobby_code, v)
							end
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

					
				end
				ReceiveMessages(lobby_gamemode, not game_in_progress)
			end
		end
	end
end

function OnProjectileFired(shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message,
						   unknown1, multicast_index, unknown3)
	if steam then
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
	if steam then
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
	if steam then
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
				--ReceiveMessages(lobby_gamemode)
			end
		end
	end
	GameRemoveFlagRun("chat_bind_disabled")
	lobby_data_updated_this_frame = {}
	if(bindings ~= nil and not IsPaused())then
		bindings:Update()
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
					
					delay.new(30, function()
						for k, setting in ipairs(lobby_gamemode.settings or {}) do
							gamemode_settings[setting.id] = steam.matchmaking.getLobbyData(lobby_code, "setting_" ..
								setting.id)
						end
	
						if (lobby_gamemode.refresh) then
							lobby_gamemode.refresh(lobby_code)
						end
					end, function(frames) end)

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
	if(lobby_code ~= nil)then
		local current_lobby_data = {}
		local lobby_data_count = steam.matchmaking.getLobbyDataCount(lobby_code)
		for i = 1, lobby_data_count do
			local data = steam.matchmaking.getLobbyDataByIndex(lobby_code, i -1 )
			current_lobby_data[data.key] = data.value
			--print("Lobby data: " .. data.key .. " = " .. data.value)
			if(not lobby_data_last_frame[data.key] or lobby_data_last_frame[data.key] ~= data.value)then
				lobby_data_updated_this_frame[data.key] = true
				--print("Updated lobby data: " .. data.key .. " to " .. data.value)
			end
		end
		lobby_data_last_frame = current_lobby_data
	else
		lobby_data_last_frame = {}
		lobby_data_updated_this_frame = {}
	end
end

function steam.matchmaking.onLobbyChatUpdate(data)
	--pretty.table(data)
	handleBanCheck(data.userChanged)
	handleInProgressCheck(data.userChanged)
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
					--print("Refreshing lobby data in 30 frames")
					delay.new(30, function()
						for k, setting in ipairs(lobby_gamemode.settings or {}) do
							gamemode_settings[setting.id] = steam.matchmaking.getLobbyData(lobby_code, "setting_" ..
								setting.id)
						end
	
						if (lobby_gamemode.refresh) then
							lobby_gamemode.refresh(lobby_code)
						end
					end, function(frames) end)


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

	debug_info:print("Gamemodes: [")

	-- get installed modes
	for k, v in ipairs(gamemodes)do
		debug_info:print("  "..tostring(v.id).."@"..tostring(v.version))
	end

	debug_info:print("]")

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

local fix_falsely_enabled_gamemodes = function()
	print("Fixing falsely enabled gamemodes")
	local nxml = dofile("mods/evaisa.mp/lib/nxml.lua")
	local save_folder = os.getenv('APPDATA'):gsub("\\Roaming", "") ..
		"\\LocalLow\\Nolla_Games_Noita\\save00\\mod_config.xml"

	local things = {}

	for k, v in ipairs(ModGetActiveModIDs()) do
		things[v] = true
	end

	local file, err = io.open(save_folder, 'rb')
	if file then
		
		local content = file:read("*all")

		local parsedModData = nxml.parse(content)
		for elem in parsedModData:each_child() do
			if (elem.name == "Mod") then
				local modID = elem.attr.name
				local steamID = elem.attr.workshop_item_id

				if (things[modID]) then
					local infoFile = "mods/" .. modID .. "/mod.xml"
					if (steamID ~= "0") then
						infoFile = "../../workshop/content/881100/" .. steamID .. "/mod.xml"
					end

					local file2, err = io.open(infoFile, 'rb')
					if file2 then
						local content2 = file2:read("*all")
						local parsedModInfo = nxml.parse(content2)

						local download_link = parsedModInfo.attr.download_link
						local is_game_mode = parsedModInfo.attr.is_game_mode == "1"

						if (elem.attr.enabled == "1" and is_game_mode) then
							elem.attr.enabled = "0"
							print("Disabling " .. modID)
						end
					end
				end
			end
		end
		file:close()


		local new_content = tostring(parsedModData)
		
		local file, err = io.open(save_folder, 'wb')
		if file then
			file:write(new_content)
			file:close()
		end
		
	end
end

function OnPlayerSpawned(player)

	fix_falsely_enabled_gamemodes()
	ModSettingRemove("lobby_data_store")
	GameRemoveFlagRun("game_paused")
	rand = rng.new(os.time()+GameGetFrameNum())
	delay.reset()
	--ModSettingRemove("lobby_data_store")
	--print(pretty.table(bitser))

	-- replace contents of "mods/evaisa.forcerestart/filechange.txt" with a random number between 0 and 10000000
	--local file = io.open("mods/evaisa.forcerestart/filechange.txt", "w")
	--file:write(math.random(0, 10000000))
	--file:close()

	--mp_log:print(bitser.loads(""))

	Spawned = true
end
