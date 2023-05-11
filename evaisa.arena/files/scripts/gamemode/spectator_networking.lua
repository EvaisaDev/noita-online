-- why is this all here

local steamutils = dofile_once("mods/evaisa.mp/lib/steamutils.lua")
local player = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/player.lua")
local playerinfo = dofile("mods/evaisa.arena/files/scripts/gamemode/playerinfo.lua")
local healthbar = dofile("mods/evaisa.arena/files/scripts/utilities/health_bar.lua")
local tween = dofile("mods/evaisa.arena/lib/tween.lua")
local Vector = dofile("mods/evaisa.arena/lib/vector.lua")
local json = dofile("mods/evaisa.arena/lib/json.lua")
local EntityHelper = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/entity.lua")
local smallfolk = dofile("mods/evaisa.arena/lib/smallfolk.lua")
dofile_once( "data/scripts/perks/perk_list.lua" )
dofile_once("mods/evaisa.arena/content/data.lua")
local player_helper = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/player.lua")

-- whatever ill just leave it

spectator_networking = {
    receive = {
        ready = function(lobby, message, user, data)
            print("Received ready message from " .. tostring(user) .. " with message " .. tostring(message[1]))

            local username = steamutils.getTranslatedPersonaName(user)

            if (message[1]) then
                data.players[tostring(user)].ready = true

                if (not message[2]) then
                    GamePrint(tostring(username) .. " is ready.")
                end

                if (steamutils.IsOwner(lobby)) then
                    arena_log:print(tostring(user) .. "_ready: " .. tostring(message[1]))
                    steam.matchmaking.setLobbyData(lobby, tostring(user) .. "_ready", "true")
                end
            else
                data.players[tostring(user)].ready = false

                if (not message[2]) then
                    GamePrint(tostring(username) .. " is no longer ready.")
                end

                if (steamutils.IsOwner(lobby)) then
                    steam.matchmaking.setLobbyData(lobby, tostring(user) .. "_ready", "false")
                end
            end
        end,
        arena_loaded = function(lobby, message, user, data)
            local username = steamutils.getTranslatedPersonaName(user)

            data.players[tostring(user)].loaded = true

            GamePrint(username .. " has loaded the arena.")
            arena_log:print(username .. " has loaded the arena.")

            if (steamutils.IsOwner(lobby)) then
                steam.matchmaking.setLobbyData(lobby, tostring(user) .. "_loaded", "true")
            end
        end,
        enter_arena = function(lobby, message, user, data)
        end,
        start_countdown = function(lobby, message, user, data)
        end,
        unlock = function(lobby, message, user, data)
        end,
        character_position = function(lobby, message, user, data)
        end,
        handshake = function(lobby, message, user, data)
            steamutils.sendToPlayer("handshake_confirmed", {message[1], message[2]}, user, true)
        end,
        handshake_confirmed = function(lobby, message, user, data)
        end,
        wand_update = function(lobby, message, user, data)
        end,
        request_wand_update = function(lobby, message, user, data)
        end,
        input_update = function(lobby, message, user, data)
        end,
        animation_update = function(lobby, message, user, data)
        end,
        switch_item = function(lobby, message, user, data)
        end,
        sync_wand_stats = function(lobby, message, user, data)
        end,
        health_update = function(lobby, message, user, data)
            local health = message[1]
            local maxHealth = message[2]

            if (health ~= nil and maxHealth ~= nil) then
                if (data.players[tostring(user)].entity ~= nil) then
                    local last_health = maxHealth
                    if (data.players[tostring(user)].health) then
                        last_health = data.players[tostring(user)].health
                    end
                    if (health < last_health) then
                        local damage = last_health - health
                        EntityInflictDamage(data.players[tostring(user)].entity, damage, "DAMAGE_DROWNING", "damage_fake",
                            "NONE", 0, 0, nil)
                    end

                    local DamageModelComp = EntityGetFirstComponentIncludingDisabled(data.players[tostring(user)].entity,
                        "DamageModelComponent")

                    if (DamageModelComp ~= nil) then
                        ComponentSetValue2(DamageModelComp, "max_hp", maxHealth)
                        ComponentSetValue2(DamageModelComp, "hp", health)
                    end


                    if (data.players[tostring(user)].hp_bar) then
                        data.players[tostring(user)].hp_bar:setHealth(health, maxHealth)
                    else
                        local hp_bar = healthbar.create(health, maxHealth, 18, 2)
                        data.players[tostring(user)].hp_bar = hp_bar
                    end
                end

                data.players[tostring(user)].health = health
                data.players[tostring(user)].max_health = maxHealth
            end
        end,
        perk_update = function(lobby, message, user, data)
            arena_log:print("Received perk update!!")
            arena_log:print(json.stringify(message[1]))
            data.players[tostring(user)].perks = message[1]
        end,
        fire_wand = function(lobby, message, user, data)
        end,
        death = function(lobby, message, user, data)
            if (data.state == "arena") then
                local username = steamutils.getTranslatedPersonaName(user)

                local killer = message[1]
                -- iterate data.tweens backwards and remove tweens belonging to the dead player
                for i = #data.tweens, 1, -1 do
                    local tween = data.tweens[i]
                    if (tween.id == tostring(user)) then
                        table.remove(data.tweens, i)
                    end
                end

                --print(json.stringify(killer))

                data.players[tostring(user)]:Clean(lobby)
                data.players[tostring(user)].alive = false
                data.deaths = data.deaths + 1

                if (killer == nil) then
                    GamePrint(tostring(username) .. " died.")
                else
                    local killer_id = gameplay_handler.FindUser(lobby, killer)
                    if (killer_id ~= nil) then
                        GamePrint(tostring(username) ..
                            " was killed by " .. steamutils.getTranslatedPersonaName(killer_id))
                    else
                        GamePrint(tostring(username) .. " died.")
                    end
                end

                spectator_handler.WinnerCheck(lobby, data)
            end
        end,
        zone_update = function(lobby, message, user, data)
        end,
        request_perk_update = function(lobby, message, user, data)
        end,
    },
    send = {
    },
}

return networking