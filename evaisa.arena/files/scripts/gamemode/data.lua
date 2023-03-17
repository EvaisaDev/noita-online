local steamutils = dofile_once("mods/evaisa.mp/lib/steamutils.lua")
local rng = dofile_once("mods/evaisa.arena/lib/rng.lua")
local playerinfo = dofile("mods/evaisa.arena/files/scripts/gamemode/playerinfo.lua")
local data = {}

function data:New()
    local o = {
        players = {},
        tweens = {},
        ready_counter = nil,
        countdown = nil,
        client = {
            ready = false,
            alive = true,
            previous_wand = nil,
            previous_anim = nil,
            projectile_seeds = {},
            projectile_homing = {},
        },
        state = "lobby",
        preparing = false,
        players_loaded = false,
        deaths = 0,
        spawn_point = {x = 0, y = 0},
        random = rng.new((os.time() + GameGetFrameNum() + os.clock()) / 2),
        DefinePlayer = function(self, lobby, user)
            self.players[tostring(user)] = playerinfo:New(user)
            local ready = steam.matchmaking.getLobbyData(lobby, tostring(user).."_ready")
            if(ready ~= nil and ready ~= "")then
                self.players[tostring(user)].ready = ready == "true"
            end
        end,
        DefinePlayers = function(self, lobby)
            local members = steamutils.getLobbyMembers(lobby)
            for k, member in pairs(members)do
                if(member.id ~= steam.user.getSteamID())then
                    self:DefinePlayer(lobby, member.id)
                end
            end
        end,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

return data