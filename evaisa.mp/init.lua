--------- STATIC VARIABLES ---------

game_id = 881100
--discord_app_id = 943584660334739457LL
MP_VERSION = 355
VERSION_FLAVOR_TEXT = "$mp_beta"
noita_online_download = "https://github.com/EvaisaDev/noita-online/releases"
Version_string = "63479623967237"
exceptions_in_logger = true
dev_mode = false
debugging = false
disable_print = false


-----------------------------------


------ TRANSLATIONS -------

dofile("mods/evaisa.mp/lib/translations.lua")

register_localizations("mods/evaisa.mp/translations.csv", 2)

---------------------------

------ Path definitions -------
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

---------------------------

local ffi = require"ffi"


string.bytes = function(str)
	local bytes = 0
	for i = 1, #str do
		bytes = bytes + str:byte(i)
	end
	return bytes
end


----------------- Gui Option Jankery ----------------

local gui_option_cache = {}

local gui_option_add = GuiOptionsAdd
local gui_option_remove = GuiOptionsRemove

function GuiOptionsAdd(gui, option)
	gui_option_cache[gui] = gui_option_cache[gui] or {}
	gui_option_cache[gui][option] = true
	gui_option_add(gui, option)
end

function GuiOptionsRemove(gui, option)
	if(gui_option_cache[gui] and gui_option_cache[gui][option])then
		gui_option_remove(gui, option)
		gui_option_cache[gui][option] = nil
	end
end

-- epic new function truly
function GuiOptionsHas(gui, option)
	return gui_option_cache[gui] and gui_option_cache[gui][option]
end

function GuiOptionsList(gui)
	local options = {}

	if(gui_option_cache[gui])then
		for k, v in pairs(gui_option_cache[gui])do
			table.insert(options, k)
		end
	end

	return options
end





get_content = ModTextFileGetContent
set_content = ModTextFileSetContent

dofile("mods/evaisa.mp/lib/ffi_extensions.lua")
if(ModIsEnabled("NoitaDearImGui"))then
	imgui = load_imgui({mod="noita-online", version="1.19"})
	implot = imgui.implot
end

local inspect = dofile("mods/evaisa.mp/lib/inspect.lua")


table.insert(package.loaders, 2, load)

logger = require("logger")("noita_online_logs")
mp_log = logger.init("noita-online.log")
networking_log = logger.init("networking.log")
debug_log = logger.init("debugging.log")
exception_log = logger.init("exceptions.log")
debug_info = logger.init("debug_info.log", nil, true)

if(not debugging)then
	networking_log.enabled = false
end



try = dofile("mods/evaisa.mp/lib/try_catch.lua")

--fontbuilder = dofile("mods/evaisa.mp/lib/fontbuilder.lua")

game_config = dofile("mods/evaisa.mp/lib/game_config.lua")

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
nxml = dofile("mods/evaisa.mp/lib/nxml.lua")
local utf8 = require 'lua-utf8'

pngencoder = require("pngencoder")
np = require("noitapatcher")
bitser = require("bitser")
smallfolk = require("smallfolk")
binser = require("binser")
zstandard = require("zstd")
zstd = zstandard:new()
delay = dofile("mods/evaisa.mp/lib/delay.lua")
streaming = dofile("mods/evaisa.mp/lib/streaming.lua")

popup = dofile("mods/evaisa.mp/files/scripts/popup.lua")

profile = dofile("mods/evaisa.mp/lib/profile.lua")

local profile_next = false
local profiler_rate = math.floor(ModSettingGet("evaisa.mp.profiler_rate") or 1)

local profiler_folder_name = "noita_online_logs/profiler"

-- create profiler folder
if not os.rename(profiler_folder_name, profiler_folder_name) then
	os.execute("mkdir \"" .. profiler_folder_name .. "\"")
end

local profiler_result_file = nil
local profiler_result_content = ""


debug_info:print("Build: " .. tostring(MP_VERSION))

rng = dofile("mods/evaisa.mp/lib/rng.lua")
rand = nil

in_game = false
Spawned = false
Starting = nil

lobby_gamemode = nil



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

noita_version_hash = GetNoitaVersionHash()

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

local serialization_version = "3"
if ((ModSettingGet("last_serialization_version") or "1") ~= serialization_version) then
	RepairDataFolder()
	ModSettingSet("last_serialization_version", serialization_version)
end

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

np.EnableLogFiltering(true)

function FilterLog(source, function_name, line, ...)
	debug_log:print(source .. " " .. function_name .. " " .. line .. " " .. table.concat({...}, " "))
	-- if contains "Lua error" or "Stack traceback"
	if (string.find(table.concat({...}, " "), "Lua error") or string.find(table.concat({...}, " "), "Stack traceback")) then
		exception_log:print(source .. " " .. function_name .. " " .. line .. " " .. table.concat({...}, " "))
		return true
	end
	return false
end

--GameSDK = require("game_sdk")

steam = require("luasteam")


--GameSDK = nil
--discord_sdk = nil


--require("physics")
steamutils = dofile_once("mods/evaisa.mp/lib/steamutils.lua")
clear_avatar_cache()
json = dofile_once("mods/evaisa.mp/lib/json.lua")

pretty = require("pretty_print")

local is_invalid_version = (PhysicsBodyIDGetBodyAABB == nil)

--local pollnet = require("pollnet")

--GamePrint("Making api call")

dofile("mods/evaisa.mp/files/scripts/debugging.lua")

dofile("mods/evaisa.mp/lib/character_support.lua")

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

	if(not is_wand_pickup)then
		profiler_rate = math.floor(ModSettingGet("evaisa.mp.profiler_rate") or 1)
	end

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

bytes_sent_per_type = {}
bytes_received_per_type = {}

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

function TryHandleMessage(lobby_code, event, message, user, ignore)
	try(function()
		if (lobby_gamemode ~= nil) then

			if(event ~= "hm_timer_clear" and event ~= "ready")then
				--print(event)
			end

			local owner = steam.matchmaking.getLobbyOwner(lobby_code)
	
			local from_owner = user == owner
	
			if (from_owner and event == "start" or event == "restart") then

				print("Starting game")
				
				if(lobby_gamemode.apply_start_data)then
					lobby_gamemode.apply_start_data(lobby_code, message)
				end

				if(owner == steam_utils.getSteamID())then
					StartGame()
				else
					Starting = 30
				end
			elseif (from_owner and event == "refresh") then

				print("Refreshing lobby data")
	
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
			elseif (owner == steam_utils.getSteamID() and event == "spectate") then
				print("Toggling spectator for " .. tostring(steamutils.getTranslatedPersonaName(user)))
				local spectating = steamutils.IsSpectator(lobby_code, user)
				steam_utils.TrySetLobbyData(lobby_code, tostring(user) .. "_spectator", spectating and "false" or "true")
			end

			--print("ignore? "..tostring(ignore))

			if (lobby_gamemode.received and not ignore) then
				lobby_gamemode.received(lobby_code, event, message, user)
			end
		end
	end).catch(function(ex)
		exception_log:print(tostring(ex))
		if(exceptions_in_logger)then
			print(tostring(ex))
		end
	end)
end

function HandleMessage(v, ignore)
		
	if(is_awaiting_spectate)then
		return
	end

	local data = steamutils.parseData(v.data)

	bytes_received = bytes_received + v.msg_size

	if (lobby_gamemode == nil) then
		return
	end

	-- old api
	if (lobby_gamemode.message and not ignore) then
		lobby_gamemode.message(lobby_code, data, v.user)
	end
	
	if (data[1] and type(data[1]) == "string" and data[2]) then
		if(bytes_received_per_type[data[1]] == nil)then
			bytes_received_per_type[data[1]] = 0
		end
		bytes_received_per_type[data[1]] = bytes_received_per_type[data[1]] + v.msg_size
		local event = data[1]
		local message = data[2]
		local frame = data[3]

		if (data[3]) then
			if (not member_message_frames[tostring(v.user)] or member_message_frames[tostring(v.user)] <= frame) then
				member_message_frames[tostring(v.user)] = frame
				TryHandleMessage(lobby_code, event, message, v.user, ignore)
			end
		else
			TryHandleMessage(lobby_code, event, message, v.user, ignore)
		end
	else
		print("Invalid message: "..tostring(data))
	end
end

local function ReceiveMessages(ignore)
	local messages = steam.networking.pollMessages() or {}
	if(is_awaiting_spectate)then
		return
	end
	for k, v in ipairs(messages) do
		HandleMessage(v, ignore)
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


local did_frame = false
local profiler_paused = false
local profiler_frames = {}
local profiler_data = {}
local profiler_steps = 0
local profiler_labels = {}

function OnWorldPreUpdate()
	try(function()
		if(GameHasFlagRun("mp_blocked_load"))then
			return
		end

		if(profile_next and GameGetFrameNum() % profiler_rate == 0)then
			did_frame = true
			profile.start()
			--print("Profiling frame: "..GameGetFrameNum())
		else
			did_frame = false
		end

		if (input ~= nil and input:WasKeyPressed("f8")) then
			profile_next = not profile_next
			if(profile_next)then
				profile.clear()
				profiler_result_file = io.open(profiler_folder_name.."/"..os.date("%Y-%m-%d_%H-%M-%S")..".csv", "w+")
				profiler_result_content = "Snapshot,Rank,Function,Calls,Time,Avg. Time,Code\n"

				profiler_frames = {}
				profiler_data = {}
				profiler_steps = 0
				profiler_labels = {}
				print("Starting profiler")
			else
				profiler_result_file:write(profiler_result_content)
				profiler_result_file:close()
				print("Stopping profiler")
			end
		end 

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
				if(not steam.user.loggedOn())then
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

				--[[if(GameSDK ~= nil and discord_sdk ~= nil)then
					GameSDK.runCallbacks(discord_sdk.corePtr)
				end]]


				if(input == nil)then
					input = dofile_once("mods/evaisa.mp/lib/input.lua")
				end

				if(bindings == nil)then
					bindings = dofile_once("mods/evaisa.mp/lib/keybinds.lua")

					-- keyboards bindings
					bindings:RegisterBinding("chat_submit", "Noita Online [keyboard]", "Chat Send", "Key_RETURN", "key", false, true, false, false)
					bindings:RegisterBinding("chat_submit2", "Noita Online [keyboard]", "Chat Send Alt", "Key_KP_ENTER", "key", false, true, false, false)
					bindings:RegisterBinding("chat_open", "Noita Online [keyboard]", "Open Chat", "Key_t", "key", false, true, false, false)
					bindings:RegisterBinding("lobby_menu_open", "Noita Online [keyboard]", "Open Lobby Menu", "Key_y", "key", false, true, false, false)
				
					-- gamepad bindings
					bindings:RegisterBinding("chat_submit_gp", "Noita Online [gamepad]", "Chat Send", "", "button", false, false, true, false, true)
					bindings:RegisterBinding("chat_open_gp", "Noita Online [gamepad]", "Open Chat", "", "button", false, false, true, false, true)
					bindings:RegisterBinding("lobby_menu_open_gp", "Noita Online [gamepad]", "Open Lobby Menu", "", "button", false, false, true, false, true)
					
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
									
									steam_utils.Leave(lobCode)
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


					--print("b")

					if (GameGetFrameNum() % 60 == 0) then

						steam_utils.updateCacheSpectators(lobby_code)
						
						last_bytes_sent = bytes_sent
						last_bytes_received = bytes_received
						bytes_sent = 0
						bytes_received = 0

						local function format_bytes(bytes)
							return bytes < 1024 and tostring(bytes) .. " B/s" or tostring(math.floor(bytes / 1024)) .. " KB/s"
						end

						local output_string = last_bytes_sent < 1024 and tostring(last_bytes_sent) .. " B/s" or tostring(math.floor(last_bytes_sent / 1024)) .. " KB/s"

						local input_string = last_bytes_received < 1024 and tostring(last_bytes_received) .. " B/s" or tostring(math.floor(last_bytes_received / 1024)) .. " KB/s"

						local network_string = "Data throughput: ".."in: " .. input_string .. " | out: " .. output_string

						for k, v in pairs(bytes_sent_per_type) do
							if(bytes_received_per_type[k] == nil)then
								bytes_received_per_type[k] = 0
							end
							local sent = v
							local received = bytes_received_per_type[k]
							network_string = network_string .. "\n["..k.."]: out: "..format_bytes(sent).." | in: "..format_bytes(received)
						end

						bytes_sent_per_type = {}
						bytes_received_per_type = {}

						networking_log:print(network_string.."\n")
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

						lobby_gamemode.update(lobby_code)

						
					end
					ReceiveMessages(not game_in_progress)
				end
			end
		end
	end).catch(function(ex)
		exception_log:print(tostring(ex))
		if(exceptions_in_logger)then
			print(tostring(ex))
		end
	end)
end

function OnProjectileFired(shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message,
						   unknown1, multicast_index, unknown3)
	try(function()
		if steam then
			--pretty.table(steam.networking)
			lobby_code = lobby_code or nil

			if (lobby_code ~= nil) then

				if (lobby_gamemode ~= nil and game_in_progress) then
					if (lobby_gamemode.on_projectile_fired) then
						lobby_gamemode.on_projectile_fired(lobby_code, shooter_id, projectile_id, rng, position_x, position_y,
							target_x, target_y, send_message, unknown1, multicast_index, unknown3)
					end
				end
			end
		end
	end).catch(function(ex)
		exception_log:print(tostring(ex))
		if(exceptions_in_logger)then
			print(tostring(ex))
		end
	end)
end

function OnProjectileFiredPost(shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message,
							   unknown1, multicast_index, unknown3)
	try(function()
		if steam then
			--pretty.table(steam.networking)
			lobby_code = lobby_code or nil

			if (lobby_code ~= nil) then

				if (lobby_gamemode ~= nil and game_in_progress) then
					if (lobby_gamemode.on_projectile_fired_post) then
						lobby_gamemode.on_projectile_fired_post(lobby_code, shooter_id, projectile_id, rng, position_x,
							position_y, target_x, target_y, send_message, unknown1, multicast_index, unknown3)
					end
				end
			end
		end
	end).catch(function(ex)
		exception_log:print(tostring(ex))
		if(exceptions_in_logger)then
			print(tostring(ex))
		end
	end)
end



function OnWorldPostUpdate()
	try(function()
		if steam then
			--pretty.table(steam.networking)
			lobby_code = lobby_code or nil

			if (lobby_code ~= nil) then

				if (lobby_gamemode ~= nil and game_in_progress) then
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



		if(profile_next and did_frame and not profiler_paused)then
			profile.stop()

			--local profiler_data = profile.csv(150)

			local frame = {}

			local report = profile.query(500)

			for i, row in ipairs(report) do
				local rank = row[1]
				local func = row[2]
				local calls = row[3]
				local time = row[4]
				local avg_time = row[5]
				local code = row[6]

				local untruncated_func = func
				local untruncated_code = code

				-- truncate func after first space
				func = string.match(func, "^[^ ]+")
				code = string.match(code, "^[^ ]+")

				local label = table.concat({code, " - ", func, "##", untruncated_func, untruncated_code}, "")


				-- add to profiler frames
				

				table.insert(frame, {label, time, calls})

			end

			table.insert(profiler_frames, frame)

			profiler_steps = profiler_steps + 1

			-- if profiler frames over 1000 then remove the first one
			if(#profiler_frames > 1000)then
				table.remove(profiler_frames, 1)
			end

			if(profiler_data == nil or GameGetFrameNum() % 60 == 0)then
				profiler_data = {}
				profiler_labels = {}
				local curr_frame = profiler_steps - #profiler_frames
				
				for i, v in ipairs(profiler_frames) do
					for j, data in ipairs(v) do
						local label = data[1]
						local time = data[2]
						local calls = data[3]

						if(profiler_data[label] == nil)then
							profiler_data[label] = {{}, {}, {}}
							table.insert(profiler_labels, label)
						end

						table.insert(profiler_data[label][1], curr_frame + i)
						table.insert(profiler_data[label][2], time)
						table.insert(profiler_data[label][3], calls)
					end
				end

				-- sort labels by time

				local ind = 2

				if(use_calls)then
					ind = 3
				end
				
				table.sort(profiler_labels, function(a, b)
					local a_time = 0
					local b_time = 0
					for i, v in ipairs(profiler_data[a][ind]) do
						a_time = a_time + v
					end
					for i, v in ipairs(profiler_data[b][ind]) do
						b_time = b_time + v
					end
					return a_time > b_time
				end)
			end



			profile.reset()
			
		end

		if(imgui ~= nil and profile_next)then
			if imgui.Begin("Profiler") then
				-- add checkbox for auto scrolling
				-- add button for clearing data

				if imgui.Button("Clear data") then
					profile.clear()
					profiler_data = {}
					profiler_frames = {}
					profiler_steps = 0
				end

				imgui.SameLine()
				
				if(auto_scroll_profiler == nil)then
					auto_scroll_profiler = true
				end

				if(use_calls == nil)then
					use_calls = false
				end

				-- checkbox
				local _
				_, auto_scroll_profiler = imgui.Checkbox("Auto scroll", auto_scroll_profiler)

				imgui.SameLine()
				_, use_calls = imgui.Checkbox("Use calls", use_calls)


				imgui.SameLine()

				if imgui.Button(profiler_paused and "Unpause" or "Pause") then
					profiler_paused = not profiler_paused
				end


				if implot.BeginPlot("Profiler") then
		
					local label_y = "time"

					if(use_calls)then
						label_y = "calls"
					end

					implot.SetupAxes("frame", label_y, auto_scroll_profiler and implot.PlotAxisFlags.Lock or implot.PlotAxisFlags.None, (auto_scroll_profiler and implot.PlotAxisFlags.AutoFit or implot.PlotAxisFlags.None));
					
					

					if(auto_scroll_profiler)then
						implot.SetupAxisLimits(implot.Axis.X1, math.max(profiler_steps - 500, 0), math.max(profiler_steps - 400, 100), implot.PlotCond.Always)
					else
						implot.SetupAxisLimits(implot.Axis.X1, 0, 100)
					end

					implot.SetupLegend(implot.PlotLocation.East, implot.PlotLegendFlags.Outside)

					-- we need to defined them in time order
					local ind = 2

					if(use_calls)then
						ind = 3
					end

					for _, tag in ipairs(profiler_labels) do
						data = profiler_data[tag]
						if(data == nil)then
							data =  {{}, {}, {}}
							profiler_data[tag] = data
						end
						implot.SetNextMarkerStyle(implot.PlotMarker.Circle, 1);
						implot.PlotLine(tag, data[1], data[ind])
					end
					
					implot.EndPlot()
				end

				imgui.End()
			end
		end

	end).catch(function(ex)
		exception_log:print(tostring(ex))
		if(exceptions_in_logger)then
			print(tostring(ex))
		end
	end)
end



function steam.matchmaking.onLobbyEnter(data)
	try(function()
		clear_avatar_cache()
		for k, v in pairs(active_members) do
			active_members[k] = nil
			member_message_frames[k] = nil
			lobby_members = {}
			lobby_members_ids = {}
			steam.networking.closeSession(v)
			mp_log:print("Closed session with " .. steamutils.getTranslatedPersonaName(v))
		end
		input:Clear()
		Starting = nil
		in_game = false
		game_in_progress = false

		local user = steam_utils.getSteamID()

		steamutils.getUserAvatar(user)


		if (data.response ~= 2) then
			lobby_code = data.lobbyID
			mp_log:print("Code set to: " .. tostring(lobby_code) .. "[" .. type(lobby_code) .. "]")
			ModSettingSet("last_lobby_code", tostring(lobby_code))
			lobby_gamemode = FindGamemode(steam.matchmaking.getLobbyData(lobby_code, "gamemode"))

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

						if (lobby_gamemode ~= nil) then
							local lobby_name = steam.matchmaking.getLobbyData(lobby_code, "name")
							steam.friends.setRichPresence( "status", "Noita Online || "..GameTextGetTranslatedOrNot(tostring(lobby_gamemode.name)))
							steam.friends.setRichPresence( "steam_player_group", lobby_name )
							
							local member_count = steam.matchmaking.getNumLobbyMembers(lobby_code)
				
							steam.friends.setRichPresence( "steam_player_group_size", tostring(member_count) )
				
						end

						lobby_gamemode.enter(lobby_code)
					end
				end
			end	
		else
			msg.log("Invalid lobby ID")
		end
	end).catch(function(ex)
		exception_log:print(tostring(ex))
		if(exceptions_in_logger)then
			print(tostring(ex))
		end
	end)
end

lobby_owner = nil

function steam.matchmaking.onLobbyDataUpdate(data)
	print("Lobby data updated")
	try(function()
		if(lobby_code ~= nil)then
			local current_lobby_data = {}
			local any_updated = false
			local lobby_data_count = steam.matchmaking.getLobbyDataCount(lobby_code)
			for i = 1, lobby_data_count do
				local data = steam.matchmaking.getLobbyDataByIndex(lobby_code, i -1 )
				current_lobby_data[data.key] = data.value

				-- if data.key ends with _spectator, then we need to update the spectator list
				if(string.sub(data.key, -10) == "_spectator")then
					steamutils.getLobbyMembers(lobby_code, true, true)
				end
				
				--print("Lobby data: " .. data.key .. " = " .. data.value)
				if(not lobby_data_last_frame[data.key] or lobby_data_last_frame[data.key] ~= data.value)then
					lobby_data_updated_this_frame[data.key] = true
					print("Updated lobby data: " .. data.key .. " to " .. data.value)
					any_updated = true
				end
			end
			lobby_data_last_frame = current_lobby_data

			if(not any_updated)then
				-- try to update lobby owner
				lobby_owner = steam.matchmaking.getLobbyOwner(lobby_code)
			end
		else
			lobby_data_last_frame = {}
			lobby_data_updated_this_frame = {}
		end
	end).catch(function(ex)
		exception_log:print(tostring(ex))
		if(exceptions_in_logger)then
			print(tostring(ex))
		end
	end)
end


ChatMemberStateChangeEnum = {
	k_EChatMemberStateChangeEntered = 1,
	k_EChatMemberStateChangeLeft = 2,
	k_EChatMemberStateChangeDisconnected = 4,
	k_EChatMemberStateChangeKicked = 8,
	k_EChatMemberStateChangeBanned = 10,
}

total_lobby_members = 0

function steam.matchmaking.onLobbyChatUpdate(data)
	try(function()

		if handleBanCheck(data.userChanged) then
			return
		end
		if handleInProgressCheck(data.userChanged) then
			return
		end

		lobby_owner = steam.matchmaking.getLobbyOwner(lobby_code)
		total_lobby_members = steam.matchmaking.getNumLobbyMembers(lobby_code)
		
		if(lobby_code ~= nil)then
			steam_utils.getLobbyMembers(lobby_code, true, true)

			if (lobby_gamemode ~= nil) then
				local lobby_name = steam.matchmaking.getLobbyData(lobby_code, "name")
				steam.friends.setRichPresence( "status", "Noita Online || "..GameTextGetTranslatedOrNot(tostring(lobby_gamemode.name)))
				steam.friends.setRichPresence( "steam_player_group", lobby_name )
				
				local member_count = steam.matchmaking.getNumLobbyMembers(lobby_code)

				steam.friends.setRichPresence( "steam_player_group_size", tostring(member_count) )

			end


			if(data.chatMemberStateChange == ChatMemberStateChangeEnum.k_EChatMemberStateChangeEntered)then

				if (lobby_gamemode == nil) then
					return
				end

				print("A player joined!")
				
				local h = data.userChanged

				steamutils.getUserAvatar(h)

				getLobbyUserData(lobby_code, h, true)

				if (not active_members[tostring(h)]) then
					active_members[tostring(h)] = h
				end
				
				--print("Clearing frames for " .. tostring(h))
				member_message_frames[tostring(h)] = nil
			

				if(lobby_gamemode.player_join)then
					lobby_gamemode.player_join(lobby_code, h)
				end
			else
				local h = data.userChanged

				active_members[tostring(h)] = nil

				--print("Clearing frames for " .. tostring(h))
				member_message_frames[tostring(h)] = nil
				steam.networking.closeSession(h)
				mp_log:print("Closed session with " .. steamutils.getTranslatedPersonaName(h))
				-- run gamemode on_leave
				if (lobby_gamemode and lobby_gamemode.disconnected ~= nil) then
					lobby_gamemode.disconnected(lobby_code, h)
				end
			end
		end
	end).catch(function(ex)
		exception_log:print(tostring(ex))
		if(exceptions_in_logger)then
			print(tostring(ex))
		end
	end)
end

function steam.matchmaking.onGameLobbyJoinRequested(data)
	---pretty.table(data)
	if (steam.extra.isSteamIDValid(data.lobbyID)) then
		gamemode_settings = {}
		steam_utils.Leave(data.lobbyID)
		steam.matchmaking.joinLobby(data.lobbyID, function(e)
			if (e.response == 2) then
				cached_lobby_data = {}
				steam_utils.Leave(e.lobbyID)
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
	try(function()
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

	end).catch(function(ex)
		exception_log:print(tostring(ex))
		if(exceptions_in_logger)then
			print(tostring(ex))
		end
	end)
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

	--fontbuilder.generate("mods/evaisa.mp/files/fonts/noto_sans_jp_regular_20.lua", "noto_sans_jp_regular_20.xml")
	--fontbuilder.generate("mods/evaisa.mp/files/fonts/noto_sans_regular_20.lua", "noto_sans_regular_20.xml")
	--fontbuilder.generate("mods/evaisa.mp/files/fonts/noto_sans_sc_regular_20.lua", "noto_sans_sc_regular_20.xml")

	--print(json.stringify(char_ranges))
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

	--[[if(GameSDK == nil)then
		GameSDK = require("game_sdk")

		discord_sdk = GameSDK.initialize(discord_app_id)
	end]]

	


	mod_data = ModData()

	debug_info:print("Gamemodes: [")

	-- get installed modes
	for k, v in ipairs(gamemodes)do
		debug_info:print("  "..tostring(v.id).."@"..tostring(v.version))
	end

	debug_info:print("]")

	debug_info:print("Installed mods: [")
	-- get installed mods

	for k, v in ipairs(ModGetActiveModIDs())do
		debug_info:print("  "..tostring(v))
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

	-- make popup
	local streaming, streaming_app = streaming.IsStreaming()
	if(ModSettingGet("evaisa.mp.streamer_mode_detection") and streaming and not ModSettingGet("evaisa.mp.streamer_mode"))then
		popup.create("streaming_message", GameTextGetTranslatedOrNot("$mp_streamer_mode_popup"),{ 
			{
				text = string.format(GameTextGetTranslatedOrNot("$mp_streamer_mode_popup_detected"), streaming_app),
				color = {217 / 255, 52 / 255, 52 / 255, 1}
			},
			GameTextGetTranslatedOrNot("$mp_streamer_mode_popup_desc"),
			GameTextGetTranslatedOrNot("$mp_streamer_mode_popup_desc2")
		}, {
			{
				text = GameTextGetTranslatedOrNot("$mp_streamer_mode_popup_enable"),
				callback = function()
					ModSettingSet("evaisa.mp.streamer_mode", true)
				end
			},
			{
				text = GameTextGetTranslatedOrNot("$mp_close_popup"),
				callback = function()
				end
			}
		}, -6000)
		
	end

	fix_falsely_enabled_gamemodes()
	ModSettingRemove("lobby_data_store")
	GameRemoveFlagRun("game_paused")
	rand = rng.new(os.time()+GameGetFrameNum())
	delay.reset()
	is_awaiting_spectate = false
	--ModSettingRemove("lobby_data_store")
	--print(pretty.table(bitser))

	-- replace contents of "mods/evaisa.forcerestart/filechange.txt" with a random number between 0 and 10000000
	--local file = io.open("mods/evaisa.forcerestart/filechange.txt", "w")
	--file:write(math.random(0, 10000000))
	--file:close()

	--mp_log:print(bitser.loads(""))

	Spawned = true
end
