local steamutils = dofile_once("mods/evaisa.mp/lib/steamutils.lua")

local playerinfo = {}

function playerinfo:New(user)
    local obj = {
        entity = nil,
        held_item = nil,
        hp_bar = nil,
        health = 4,
        max_health = 4,
        ready = false,
        alive = true,
        loaded = false,
        next_rng = nil,
        target = nil,
        id = user,
        perks = {},
    }

    obj.Clean = function(self, lobby)
        if(self.entity ~= nil and EntityGetIsAlive(self.entity))then
            EntityKill(self.entity)
        end
        if(self.held_item ~= nil and EntityGetIsAlive(self.held_item))then
            EntityKill(self.held_item)
        end
        self.entity = nil
        self.held_item = nil
        if(self.hp_bar)then
            self.hp_bar:destroy()
            self.hp_bar = nil
        end
        self.ready = false
        self.alive = true

        
        --[[if(steamutils.IsOwner(lobby))then
            steam.matchmaking.setLobbyData(lobby, tostring(self.id).."_loaded", "false")
            steam.matchmaking.setLobbyData(lobby, tostring(self.id).."_ready", "false")
        end]]
    end

    setmetatable(obj, self)
    self.__index = self
    return obj
end

return playerinfo