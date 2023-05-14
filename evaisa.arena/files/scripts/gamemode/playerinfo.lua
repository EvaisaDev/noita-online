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
        alive = false,
        loaded = false,
        projectile_rng_stack = {},
        target = nil,
        can_fire = false,
        --[[last_position_x = nil,
        last_position_y = nil,]]
        previous_positions = {},
        last_inventory_string = nil,
        ping = 0,
        delay_frames = 0,
        id = user,
        perks = {},
        controls = {
            kick = false,
            fire = false,
            fire2 = false,
            leftClick = false,
            rightClick = false,
        }
    }
    obj.Death = function(self)
        if(self.entity ~= nil and EntityGetIsAlive(self.entity))then

            GameDestroyInventoryItems( self.entity )

            local damage_model_comp = EntityGetFirstComponentIncludingDisabled(self.entity, "DamageModelComponent")
            if(damage_model_comp ~= nil)then
                ComponentSetValue2(damage_model_comp, "hp", 0)
                ComponentSetValue2(damage_model_comp, "ui_report_damage", false)
            end
            EntityInflictDamage(self.entity, 69420, "DAMAGE_MATERIAL", "", "NORMAL", 0, 0)
        end
        

        self.entity = nil
        self.held_item = nil
        if(self.hp_bar)then
            self.hp_bar:destroy()
            self.hp_bar = nil
        end
        self.ready = false
        self.alive = false
        --[[self.last_position_x = nil
        self.last_position_y = nil]]
        self.previous_positions = {}
        self.last_inventory_string = nil
    end
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
        self.alive = false
        --[[self.last_position_x = nil
        self.last_position_y = nil]]
        self.previous_positions = {}
        self.last_inventory_string = nil
        
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