local steamutils = dofile_once("mods/evaisa.mp/lib/steamutils.lua")
local rng = dofile_once("mods/evaisa.arena/lib/rng.lua")
local playerinfo = dofile("mods/evaisa.arena/files/scripts/gamemode/playerinfo.lua")
local data = {}

function data:New()
    local o = {
        players = {},
        tweens = {},
        projectile_seeds = {},
        ready_counter = nil,
        countdown = nil,
        client = {
            ready = false,
            alive = true,
            previous_wand = nil,
            previous_anim = nil,
            previous_perk_string = nil,
            previous_wand_stats = {
                mana = nil, 
                mCastDelayStartFrame = nil, 
                mReloadFramesLeft = nil, 
                mReloadNextFrameUsable = nil, 
                mNextChargeFrame = nil, 
            },
            previous_vel_x = nil,
            previous_vel_y = nil,
            previous_pos_x = nil,
            previous_pos_y = nil,
            --projectile_seeds = {},
            --projectile_homing = {},
            previous_selected_item = nil,
            serialized_player = nil,
            first_spawn_gold = 0,
            spread_index = 1,
            projectiles_fired = 0,
            projectile_rng_stack = {},
            hp = 100,
            max_hp = 100,
            perks = {},
        },
        state = "lobby",
        preparing = false,
        players_loaded = false,
        deaths = 0,
        spawn_point = {x = 0, y = 0},
        zone_size = nil,
        current_arena = nil,
        ready_for_zone = false,
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