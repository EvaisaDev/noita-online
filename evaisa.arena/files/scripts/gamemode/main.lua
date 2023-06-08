arena_log = logger.init("noita-arena.log")
perk_log = logger.init("noita-arena-perk.log")
mp_helpers = dofile("mods/evaisa.mp/files/scripts/helpers.lua")
local steamutils = dofile_once("mods/evaisa.mp/lib/steamutils.lua")
game_funcs = dofile("mods/evaisa.mp/files/scripts/game_functions.lua")
EZWand = dofile("mods/evaisa.arena/files/scripts/utilities/EZWand.lua")

delay = dofile("mods/evaisa.arena/files/scripts/utilities/delay.lua")
wait = dofile("mods/evaisa.arena/files/scripts/utilities/wait.lua")

local data_holder = dofile("mods/evaisa.arena/files/scripts/gamemode/data.lua")
local data = nil

last_player_entity = nil

local player = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/player.lua")
local entity = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/entity.lua")

font_helper = dofile("mods/evaisa.arena/lib/font_helper.lua")
message_handler = dofile("mods/evaisa.arena/files/scripts/gamemode/message_handler_stub.lua")
networking = dofile("mods/evaisa.arena/files/scripts/gamemode/networking.lua")
--spectator_networking = dofile("mods/evaisa.arena/files/scripts/gamemode/spectator_networking.lua")

upgrade_system = dofile("mods/evaisa.arena/files/scripts/gamemode/misc/upgrade_system.lua")
gameplay_handler = dofile("mods/evaisa.arena/files/scripts/gamemode/gameplay.lua")
spectator_handler = dofile("mods/evaisa.arena/files/scripts/gamemode/spectator.lua")

local playerinfo_menu = dofile("mods/evaisa.arena/files/scripts/utilities/playerinfo_menu.lua")

dofile_once("data/scripts/perks/perk_list.lua")

perk_sprites = {}
for k, perk in pairs(perk_list) do
    perk_sprites[perk.id] = perk.ui_icon
end

playermenu = nil

playerRunQueue = {}

function RunWhenPlayerExists(func)
    table.insert(playerRunQueue, func)
end

lobby_member_names = {}


np.SetGameModeDeterministic(true)

ArenaMode = {
    id = "arena",
    name = "$arena_gamemode_name",
    version = 0.5397,
    version_flavor_text = "$arena_dev",
    spectator_unfinished_warning = true,
    disable_spectator_system = true,
    enable_presets = true,
    default_presets = {
        ["Wand Locked"] = {
            ["zone_speed"] = 30,
            ["shop_start_level"] = 0,
            ["shop_random_ratio"] = 50,
            ["shop_type"] = "spell_only",
            ["shop_jump"] = 1,
            ["zone_step_interval"] = 30,
            ["upgrades_catchup"] = "losers",
            ["damage_cap"] = "0.25",
            ["shop_scaling"] = 2,
            ["zone_shrink"] = "static",
            ["shop_wand_chance"] = 40,
            ["max_shop_level"] = 5,
            ["shop_price_multiplier"] = 0,
            ["perk_catchup"] = "losers",
            ["upgrades_system"] = true,
        }
    }, 
    settings = {
        {
            id = "win_condition",
            name = "$arena_settings_win_condition_name",
            description = "$arena_settings_win_condition_description",
            type = "enum",
            options = { { "unlimited", "$arena_settings_win_condition_enum_unlimited" }, { "first_to", "$arena_settings_win_condition_enum_first_to" }, { "best_of", "$arena_settings_win_condition_enum_best_of" }, { "winstreak", "$arena_settings_win_condition_enum_winstreak" }},
            default = "unlimited"
        },
        {
			id = "win_condition_value",
            require = function(setting_self)
                return GlobalsGetValue("setting_next_win_condition", "unlimited") ~= "unlimited"
            end,
			name = "$arena_settings_win_condition_value_name",
			description = "$arena_settings_win_condition_value_description",
			type = "slider",
			min = 1,
			max = 20,
			default = 5;
			display_multiplier = 1,
			formatting_string = " $0",
			width = 100
		},
        {
            id = "win_condition_end_match",
            require = function(setting_self)
                return GlobalsGetValue("setting_next_win_condition", "unlimited") ~= "unlimited"
            end,
            name = "$arena_settings_win_condition_end_match_name",
            description = "$arena_settings_win_condition_end_match_description",
            type = "bool",
            default = true
        },
        {
            id = "perk_catchup",
            name = "$arena_settings_perk_reward_system_name",
            description = "$arena_settings_perk_reward_system_description",
            type = "enum",
            options = { { "everyone", "$arena_settings_reward_enum_everyone" }, { "winner", "$arena_settings_reward_enum_winner" }, { "losers", "$arena_settings_reward_enum_losers" }, { "first_death", "$arena_settings_reward_enum_first_death" }},
            default = "losers"
        },
		{
			id = "shop_type",
			name = "$arena_settings_shop_type_name",
			description = "$arena_settings_shop_type_description",
			type = "enum",
			options = { { "alternating", "$arena_settings_shop_type_alternating" }, { "random", "$arena_settings_shop_type_random" }, { "mixed", "$arena_settings_shop_type_mixed" },
				{ "spell_only", "$arena_settings_shop_type_spell_only" }, { "wand_only", "$arena_settings_shop_type_wand_only" } },
			default = "random"
		},
		{
			id = "shop_wand_chance",
            require = function(setting_self)
                return GlobalsGetValue("setting_next_shop_type", "random") == "mixed"
            end,
			name = "$arena_settings_shop_wand_chance_name",
			description = "$arena_settings_shop_wand_chance_description",
			type = "slider",
			min = 20,
			max = 80,
			default = 40;
			display_multiplier = 1,
			formatting_string = " $0%",
			width = 100
		},
        {
            id = "shop_start_level",
			name = "$arena_settings_shop_start_level_name",
			description = "$arena_settings_shop_start_level_description",
			type = "slider",
			min = 0,
			max = 10,
			default = 0;
			display_multiplier = 1,
			formatting_string = " $0",
			width = 100
        },
        {
			id = "shop_random_ratio",
			require = function(setting_self)
                return GlobalsGetValue("setting_next_shop_type", "random") == "random"
            end,
			name = "$arena_settings_shop_random_ratio_name",
			description = "$arena_settings_shop_random_ratio_description",
			type = "slider",
			min = 10,
			max = 90,
			default = 50;
			display_multiplier = 1,
			formatting_string = " $0%",
			width = 100
		},
        {
            id = "shop_scaling",
			name = "$arena_settings_shop_scaling_name",
			description = "$arena_settings_shop_scaling_description",
			type = "slider",
			min = 1,
			max = 10,
			default = 2;
			display_multiplier = 1,
			formatting_string = " $0",
			width = 100
        },
        {
            id = "shop_jump",
			name = "$arena_settings_shop_jump_name",
			description = "$arena_settings_shop_jump_description",
			type = "slider",
			min = 0,
			max = 10,
			default = 1;
			display_multiplier = 1,
			formatting_string = " $0",
			width = 100
        },
        {
            id = "max_shop_level",
			name = "$arena_settings_max_shop_level_name",
			description = "$arena_settings_max_shop_level_description",
			type = "slider",
			min = 1,
			max = 10,
			default = 5;
			display_multiplier = 1,
			formatting_string = " $0",
			width = 100
        },
        {
            id = "shop_price_multiplier",
			name = "$arena_settings_shop_price_multiplier_name",
			description = "$arena_settings_shop_price_multiplier_description",
			type = "slider",
			min = 0,
			max = 30,
			default = 10;
			display_multiplier = 0.1,
            display_fractions = 1,
            modifier = function(value) 
                return math.floor(value)
            end,
			formatting_string = " $0",
			width = 100
        },
        --[[
        {
            id = "no_shop_cost",
            name = "$arena_settings_no_cost_name",
            description = "$arena_settings_no_cost_description",
            type = "bool",
            default = false
        },
        ]]
        {
            id = "damage_cap",
            name = "$arena_settings_damage_cap_name",
            description = "$arena_settings_damage_cap_description",
            type = "enum",
            options = { { "0.25", "$arena_settings_damage_cap_25" }, { "0.5", "$arena_settings_damage_cap_50" }, { "0.75", "$arena_settings_damage_cap_75" },
                { "disabled", "$arena_settings_damage_cap_disabled" } },
            default = "0.25"
        },
        {
            id = "zone_shrink",
            name = "$arena_settings_zone_shrink_name",
            description = "$arena_settings_zone_shrink_description",
            type = "enum",
            options = { { "disabled", "$arena_settings_zone_shrink_disabled" }, { "static", "$arena_settings_zone_shrink_static" }, { "shrinking_Linear", "$arena_settings_zone_shrink_linear" },
                { "shrinking_step", "$arena_settings_zone_shrink_stepped" } },
            default = "static"
        },
        {
            id = "zone_speed",
            name = "$arena_settings_zone_speed_name",
            description = "$arena_settings_zone_speed_description",
            type = "slider",    
            min = 1,
            max = 100,
            default = 30,
            display_multiplier = 1,
            formatting_string = " $0",
            width = 100
        },
        {
            id = "zone_step_interval",
            name = "$arena_settings_zone_step_interval_name",
            description = "$arena_settings_zone_step_interval_description",
            type = "slider",
            min = 1,
            max = 90,
            default = 30,
            display_multiplier = 1,
            formatting_string = " $0s",
            width = 100
        },
        {
            id = "upgrades_system",
            name = "$arena_settings_upgrades_system_name",
            description = "$arena_settings_upgrades_system_description",
            type = "bool",
            default = false
        },
        {
            id = "upgrades_catchup",
            require = function(setting_self)
                return GlobalsGetValue("setting_next_upgrades_system", "false") == "true"
            end,
            name = "$arena_settings_upgrades_reward_system_name",
            description = "$arena_settings_upgrades_reward_system_description",
            type = "enum",
            options = {{ "everyone", "$arena_settings_reward_enum_everyone" }, { "winner", "$arena_settings_reward_enum_winner" }, { "losers", "$arena_settings_reward_enum_losers" }, { "first_death", "$arena_settings_reward_enum_first_death" }},
            default = "losers"
        },
        {
            id = "wand_removal",
            name = "$arena_settings_wand_removal_name",
            description = "$arena_settings_wand_removal_description",
            type = "enum",
            options = { { "disabled", "$arena_settings_wand_removal_enum_none" }, { "random", "$arena_settings_wand_removal_enum_random" }, { "all", "$arena_settings_wand_removal_enum_all" } },
            default = "disabled"
        },
        {
            id = "wand_removal_who",
            require = function(setting_self)
                return GlobalsGetValue("setting_next_wand_removal", "disabled") ~= "disabled"
            end,
            name = "$arena_settings_wand_removal_who_name",
            description = "$arena_settings_wand_removal_who_description",
            type = "enum",
            options = {{ "everyone", "$arena_settings_reward_enum_everyone" }, { "winner", "$arena_settings_reward_enum_winner" }, { "losers", "$arena_settings_reward_enum_losers" }, { "first_death", "$arena_settings_reward_enum_first_death" }},
            default = "everyone"
        },
    },
    commands = {
        ready = function(command_name, arguments)
            if(GameHasFlagRun("lock_ready_state"))then
                return
            end
            
            if(GameHasFlagRun("ready_check"))then
                ChatPrint(GameTextGetTranslatedOrNot("$arena_self_unready"))
                GameAddFlagRun("player_unready")
                GameRemoveFlagRun("ready_check")
                GameRemoveFlagRun("player_ready")
            else
                ChatPrint(GameTextGetTranslatedOrNot("$arena_self_ready"))
                GameAddFlagRun("player_ready")
                GameAddFlagRun("ready_check")
                GameRemoveFlagRun("player_unready")
            end


        end
    },
    default_data = {
        total_gold = "0",
        holyMountainCount = "0",
        ready_players = "null",
    },
    refresh = function(lobby)
        print("refreshing arena settings")

        local win_condition = steam.matchmaking.getLobbyData(lobby, "setting_win_condition")
        if (win_condition == nil)then
            win_condition = "unlimited"
        end
        GlobalsSetValue("win_condition", tostring(win_condition))

        local win_condition_value = steam.matchmaking.getLobbyData(lobby, "setting_win_condition_value")
        if (win_condition_value == nil)then
            win_condition_value = 5
        end
        GlobalsSetValue("win_condition_value", tostring(math.floor(win_condition_value)))

        local win_condition_end_match = steam.matchmaking.getLobbyData(lobby, "setting_win_condition_end_match")
        if (win_condition_end_match == nil)then
            win_condition_end_match = "true"
        end
        if(win_condition_end_match == "true")then
            GameAddFlagRun("win_condition_end_match")
        else
            GameRemoveFlagRun("win_condition_end_match")
        end

        local perk_catchup = steam.matchmaking.getLobbyData(lobby, "setting_perk_catchup")
        if (perk_catchup == nil) then
            perk_catchup = "losers"
        end
        GlobalsSetValue("perk_catchup", tostring(perk_catchup))

		local shop_type = steam.matchmaking.getLobbyData(lobby, "setting_shop_type")
		if (shop_type == nil) then
			shop_type = "random"
		end
        print("shop_type: " .. shop_type)
		GlobalsSetValue("shop_type", tostring(shop_type))

		local shop_wand_chance = steam.matchmaking.getLobbyData(lobby, "setting_shop_wand_chance")
		if (shop_wand_chance == nil) then
			shop_wand_chance = 20
		end
		GlobalsSetValue("shop_wand_chance", tostring(shop_wand_chance))

        local shop_random_ratio = steam.matchmaking.getLobbyData(lobby, "setting_shop_random_ratio")
        if (shop_random_ratio == nil) then
            shop_random_ratio = 50
        end
        GlobalsSetValue("shop_random_ratio", tostring(shop_random_ratio))

        local shop_start_level = tonumber(steam.matchmaking.getLobbyData(lobby, "setting_shop_start_level"))
        if (shop_start_level == nil) then
            shop_start_level = 0
        end
        GlobalsSetValue("shop_start_level", tostring(shop_start_level))

        local shop_scaling = tonumber(steam.matchmaking.getLobbyData(lobby, "setting_shop_scaling"))
        if (shop_scaling == nil) then
            shop_scaling = 2
        end
        GlobalsSetValue("shop_scaling", tostring(shop_scaling))

        local shop_jump = tonumber(steam.matchmaking.getLobbyData(lobby, "setting_shop_jump"))
        if (shop_jump == nil) then
            shop_jump = 1
        end
        GlobalsSetValue("shop_jump", tostring(shop_jump))

        local max_shop_level = tonumber(steam.matchmaking.getLobbyData(lobby, "setting_max_shop_level"))
        if (max_shop_level == nil) then
            max_shop_level = 5
        end
        GlobalsSetValue("max_shop_level", tostring(max_shop_level))

        shop_price_multiplier = tonumber(steam.matchmaking.getLobbyData(lobby, "setting_shop_price_multiplier"))
        if (shop_price_multiplier == nil) then
            shop_price_multiplier = 10
        end
        GlobalsSetValue("shop_price_multiplier", tostring(shop_price_multiplier * 0.1))
        if(shop_price_multiplier < 1)then
            GlobalsSetValue("no_shop_cost", "true")
        else
            GlobalsSetValue("no_shop_cost", "false")
        end

        --[[local no_shop_cost = steam.matchmaking.getLobbyData(lobby, "setting_no_shop_cost")	
        if (no_shop_cost == nil) then
            no_shop_cost = false
        end
        print("no_shop_cost: " .. tostring(no_shop_cost))
        GlobalsSetValue("no_shop_cost", tostring(no_shop_cost))]]
        

        local damage_cap = tonumber(steam.matchmaking.getLobbyData(lobby, "setting_damage_cap"))
        if (damage_cap == nil) then
            damage_cap = 0.25
        end
        GlobalsSetValue("damage_cap", tostring(damage_cap))

        local zone_shrink = steam.matchmaking.getLobbyData(lobby, "setting_zone_shrink")
        if (zone_shrink == nil) then
            zone_shrink = "static"
        end
        GlobalsSetValue("zone_shrink", tostring(zone_shrink))

        local zone_speed = tonumber(steam.matchmaking.getLobbyData(lobby, "setting_zone_speed"))
        if (zone_speed == nil) then
            zone_speed = 30
        end
        GlobalsSetValue("zone_speed", tostring(zone_speed))

        local zone_step_interval = tonumber(steam.matchmaking.getLobbyData(lobby, "setting_zone_step_interval"))
        if (zone_step_interval == nil) then
            zone_step_interval = 30
        end
        GlobalsSetValue("zone_step_interval", tostring(zone_step_interval))

        local upgrades_system = steam.matchmaking.getLobbyData(lobby, "setting_upgrades_system")
        if (upgrades_system == nil) then
            upgrades_system = false
        end
        GlobalsSetValue("upgrades_system", tostring(upgrades_system))

        local upgrades_catchup = steam.matchmaking.getLobbyData(lobby, "setting_upgrades_catchup")
        if (upgrades_catchup == nil) then
            upgrades_catchup = "losers"
        end
        GlobalsSetValue("upgrades_catchup", tostring(upgrades_catchup))

        local wand_removal = steam.matchmaking.getLobbyData(lobby, "setting_wand_removal")
        if (wand_removal == nil) then
            wand_removal = "disabled"
        end
        GlobalsSetValue("wand_removal", tostring(wand_removal))

        local wand_removal_who = steam.matchmaking.getLobbyData(lobby, "setting_wand_removal_who")
        if (wand_removal_who == nil) then
            wand_removal_who = "everyone"
        end
        GlobalsSetValue("wand_removal_who", tostring(wand_removal_who))

        arena_log:print("Lobby data refreshed")
    end,
    enter = function(lobby)
        GlobalsSetValue("holyMountainCount", "0")
        GameAddFlagRun("player_unloaded")

        local player = player.Get()
        if (player ~= nil) then
            EntityKill(player)
        end
        
        print("Game mode deterministic? "..tostring(GameIsModeFullyDeterministic()))

        --print("WE GOOD???")

        --debug_log:print(GameTextGetTranslatedOrNot("$arena_predictive_netcode_name"))

        arena_log:print("Enter called!!!")

        GlobalsSetValue("TEMPLE_PERK_REROLL_COUNT", "0")

        local upgrade_translation_keys = ""
        local upgrade_translation_values = ""
        for k, v in ipairs(upgrades)do
            local id = v.id
            local ui_name = v.ui_name
            local ui_description = v.ui_description

            upgrade_translation_keys = upgrade_translation_keys .. "arena_upgrades_" .. string.lower(id) .. "_name\n"
            upgrade_translation_keys = upgrade_translation_keys .. "arena_upgrades_" .. string.lower(id) .. "_description\n"

            upgrade_translation_values = upgrade_translation_values .. ui_name .. "\n"
            upgrade_translation_values = upgrade_translation_values .. ui_description .. "\n"
        end

        -- write to files
        local upgrade_translation_keys_file = io.open("noita_online_logs/arena_upgrades_keys.txt", "w")
        upgrade_translation_keys_file:write(upgrade_translation_keys)
        upgrade_translation_keys_file:close()

        local upgrade_translation_values_file = io.open("noita_online_logs/arena_upgrades_values.txt", "w")
        upgrade_translation_values_file:write(upgrade_translation_values)
        upgrade_translation_values_file:close()


        --[[
        local game_in_progress = steam.matchmaking.getLobbyData(lobby, "in_progress") == "true"
        if(game_in_progress)then
            ArenaMode.start(lobby, true)
        end
        ]]
        --message_handler.send.Handshake(lobby)
    end,
    stop = function(lobby)
        arena_log:print("Stop called!!!")
        delay.reset()
        wait.reset()
        if (data ~= nil) then
            ArenaGameplay.GracefulReset(lobby, data)
        end

        ArenaMode.refresh(lobby)
        
        gameplay_handler.ResetEverything(lobby)

        data = nil

        steamutils.RemoveLocalLobbyData(lobby, "player_data")
        steamutils.RemoveLocalLobbyData(lobby, "reroll_count")

        BiomeMapLoad_KeepPlayer("mods/evaisa.arena/files/scripts/world/map_arena.lua")
    end,
    start = function(lobby, was_in_progress)
        arena_log:print("Start called!!!")

        delay.reset()
        wait.reset()
        if (data ~= nil) then
            ArenaGameplay.GracefulReset(lobby, data)
        end

        
        ArenaMode.refresh(lobby)

        data = data_holder:New()
        data.state = "lobby"
        data.spectator_mode = steamutils.IsSpectator(lobby)
        data:DefinePlayers(lobby)


        gameplay_handler.ResetEverything(lobby)

        if (not was_in_progress) then
            GlobalsSetValue("TEMPLE_PERK_REROLL_COUNT", "0")
            steamutils.RemoveLocalLobbyData(lobby, "player_data")
            steamutils.RemoveLocalLobbyData(lobby, "reroll_count")
        else
            local unique_game_id_server = steam.matchmaking.getLobbyData(lobby, "unique_game_id") or "0"
            local unique_game_id_client = steamutils.GetLocalLobbyData(lobby, "unique_game_id") or "1523523"
    
            if (unique_game_id_server ~= unique_game_id_client) then
                arena_log:print("Unique game id mismatch, removing player data")
                GlobalsSetValue("TEMPLE_PERK_REROLL_COUNT", "0")
                steamutils.RemoveLocalLobbyData(lobby, "player_data")
                steamutils.RemoveLocalLobbyData(lobby, "reroll_count")
            else
                gameplay_handler.GetGameData(lobby, data)
            end
        end



        GameAddFlagRun("player_unloaded")

        local seed = tonumber(steam.matchmaking.getLobbyData(lobby, "seed") or 1)

        SetWorldSeed(seed)

        local player_entity = player.Get()



        local local_seed = data.random.range(100, 10000000)

        GlobalsSetValue("local_seed", tostring(local_seed))

        local unique_seed = data.random.range(100, 10000000)
        GlobalsSetValue("unique_seed", tostring(unique_seed))

        if (steamutils.IsOwner(lobby)) then
            local unique_game_id = data.random.range(100, 10000000)
            steam.matchmaking.setLobbyData(lobby, "unique_game_id", tostring(unique_game_id))
        end

        if (player_entity == nil) then
            gameplay_handler.LoadPlayer(lobby, data)
        end

        gameplay_handler.LoadLobby(lobby, data, true, true)

        if (playermenu ~= nil) then
            playermenu:Destroy()
        end

        playermenu = playerinfo_menu:New()



        --message_handler.send.Handshake(lobby)
    end,
    spectate = function(lobby, was_in_progress)
        arena_log:print("Spectate called!!!")

        delay.reset()
        wait.reset()
        if (data ~= nil) then
            ArenaGameplay.GracefulReset(lobby, data)
        end
        
        if (not was_in_progress) then
            steamutils.RemoveLocalLobbyData(lobby, "player_data")
            steamutils.RemoveLocalLobbyData(lobby, "reroll_count")
        end

        gameplay_handler.ResetEverything(lobby)

        local unique_game_id_server = steam.matchmaking.getLobbyData(lobby, "unique_game_id") or "0"
        local unique_game_id_client = steamutils.GetLocalLobbyData(lobby, "unique_game_id") or "1523523"

        if (unique_game_id_server ~= unique_game_id_client) then
            arena_log:print("Unique game id mismatch, removing player data")
            steamutils.RemoveLocalLobbyData(lobby, "player_data")
            steamutils.RemoveLocalLobbyData(lobby, "reroll_count")
        end

        GameAddFlagRun("player_unloaded")

        local seed = tonumber(steam.matchmaking.getLobbyData(lobby, "seed") or 1)

        SetWorldSeed(seed)

        ArenaMode.refresh(lobby)

        data = data_holder:New()
        data.state = "lobby"
        data.spectator_mode = steamutils.IsSpectator(lobby)
        data:DefinePlayers(lobby)

        local local_seed = data.random.range(100, 10000000)

        GlobalsSetValue("local_seed", tostring(local_seed))

        local unique_seed = data.random.range(100, 10000000)
        GlobalsSetValue("unique_seed", tostring(unique_seed))

        if (steamutils.IsOwner(lobby)) then
            local unique_game_id = data.random.range(100, 10000000)
            steam.matchmaking.setLobbyData(lobby, "unique_game_id", tostring(unique_game_id))
        end

        gameplay_handler.GetGameData(lobby, data)
        spectator_handler.LoadLobby(lobby, data, true, true)

        if (playermenu ~= nil) then
            playermenu:Destroy()
        end

        playermenu = playerinfo_menu:New()

    end,
    update = function(lobby)
        if (data == nil) then
            return
        end

        delay.update()
        wait.update()

        if (data == nil) then
            return
        end

        data.spectator_mode = steamutils.IsSpectator(lobby)

        data.using_controller = GameGetIsGamepadConnected()

        if (GameGetFrameNum() % 60 == 0) then
            if (data ~= nil) then
                local unique_game_id = steam.matchmaking.getLobbyData(lobby, "unique_game_id") or "0"
                steamutils.SetLocalLobbyData(lobby, "unique_game_id", tostring(unique_game_id))
            end

            local members = steamutils.getLobbyMembers(lobby)
            for k, member in pairs(members) do
                if (member.id ~= steam.user.getSteamID()) then
                    local name = steamutils.getTranslatedPersonaName(member.id)
                    if (name ~= nil) then
                        lobby_member_names[tostring(member.id)] = name
                    end
                end
            end


            networking.send.handshake(lobby)


            -- fix daynight cycle
            local world_state = GameGetWorldStateEntity()
            local world_state_component = EntityGetFirstComponentIncludingDisabled(world_state, "WorldStateComponent")
            ComponentSetValue2(world_state_component, "time", 0.2)
            ComponentSetValue2(world_state_component, "time_dt", 0)
            ComponentSetValue2(world_state_component, "fog", 0)
            ComponentSetValue2(world_state_component, "intro_weather", true)

            local unique_seed = data.random.range(100, 10000000)
            GlobalsSetValue("unique_seed", tostring(unique_seed))
        end

        local update_seed = steam.matchmaking.getLobbyData(lobby, "update_seed")
        if (update_seed == nil) then
            update_seed = "0"
        end

        GlobalsSetValue("update_seed", update_seed)

        if (data ~= nil) then
            if(not data.spectator_mode)then
                gameplay_handler.Update(lobby, data)
            else
                spectator_handler.Update(lobby, data)
            end

            if (not IsPaused()) then
                if (playermenu ~= nil) then
                    playermenu:Update(data, lobby)
                end
            end
        end


        if(input:WasKeyPressed("f10"))then
            local world_state = GameGetWorldStateEntity()

            EntityKill(world_state)
        elseif(input:WasKeyPressed("f6"))then
            local player_entity = EntityGetWithTag("player_unit")[1]
            local x, y = EntityGetTransform(player_entity)
            EntityInflictDamage(player_entity, 1000, "DAMAGE_SLICE", "player", "BLOOD_EXPLOSION", 0, 0, player_entity, x, y, 0)
        end

        --print("Did something go wrong?")
    end,
    late_update = function(lobby)
        if (data == nil) then
            return
        end

        if(not data.spectator_mode)then
            gameplay_handler.LateUpdate(lobby, data)
        else
            spectator_handler.LateUpdate(lobby, data)
        end
    end,
    leave = function(lobby)
        GameAddFlagRun("player_unloaded")
        gameplay_handler.ResetEverything(lobby)
    end,
    --[[
    message = function(lobby, message, user)
        message_handler.handle(lobby, message, user, data)
    end,
    ]]
    received = function(lobby, event, message, user)
        if (data == nil) then
            return
        end

        if (not data.players[tostring(user)]) then
            data:DefinePlayer(lobby, user)
        end

        if (data ~= nil) then
            --if (not data.spectator_mode) then
                if (networking.receive[event]) then
                    --[[if(event == "death")then
                        print("Received death event [regular]")
                    end]]
                    networking.receive[event](lobby, message, user, data)
                   -- print("Received event [regular networking]: " .. event)
                end
           --[[ else
                if (spectator_networking.receive[event]) then
                    if(event == "death")then
                        print("Received death event [spectator]")
                    end
                    spectator_networking.receive[event](lobby, message, user, data)
                  --  print("Received event [spectator networking]: " .. event)
                end
            end]]
        end
    end,
    on_projectile_fired = function(lobby, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y,
                                   send_message, unknown1, multicast_index, unknown3)
        --[[print(tostring(send_message))
        print(tostring(unknown1))
        print(tostring(unknown2))
        print(tostring(unknown3))]]

        --print("Projectile fired")

        if (EntityHasTag(shooter_id, "client")) then
            EntityAddTag(shooter_id, "player_unit")
        end

        if (data ~= nil) then
            gameplay_handler.OnProjectileFired(lobby, data, shooter_id, projectile_id, rng, position_x, position_y,
                target_x, target_y, send_message, unknown1, multicast_index, unknown3)
        end
    end,
    on_projectile_fired_post = function(lobby, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y,
                                        send_message, unknown1, multicast_index, unknown3)
        if (EntityHasTag(shooter_id, "client")) then
            EntityRemoveTag(shooter_id, "player_unit")
        end

        if (data ~= nil) then
            gameplay_handler.OnProjectileFiredPost(lobby, data, shooter_id, projectile_id, rng, position_x, position_y,
                target_x, target_y, send_message, unknown1, multicast_index, unknown3)
        end
    end
}

table.insert(gamemodes, ArenaMode)
