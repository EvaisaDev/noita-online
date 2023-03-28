dofile("mods/evaisa.mp/files/scripts/gui_utils.lua")


local health_bar = {}

local function get_health_bar_color(health, max_health)
    local health_ratio = health / max_health
    -- generate color between green and red based on health ratio
    local r = 255 * (1 - health_ratio)
    local g = 255 * health_ratio
    local b = 0
    
    return {r = r, g = g, b = b}
end

function health_bar.create(hp, max_hp, width, height)
    if(hp == nil)then
        hp = 100;
    end
    if(max_hp == nil)then
        max_hp = 100;
    end
    local health_gui = GuiCreate()
    GuiOptionsAdd(health_gui, 2)
    GuiOptionsAdd(health_gui, 6)
    local self = {
        hp = hp,
        max_hp = max_hp,
        width = width,
        height = height,
        visible = true,
        color = get_health_bar_color(hp, max_hp),
        last_changed_frame = GameGetFrameNum(),
        setHealth = function(self, hp, max_hp)
            if(hp == nil)then
                hp = 100;
            end
            if(max_hp == nil)then
                max_hp = 100;
            end
            self.hp = hp
            self.max_hp = max_hp
            self.color = get_health_bar_color(hp, max_hp)
            self.last_changed_frame = GameGetFrameNum()
        end,
        destroy = function(self)
            GuiDestroy(health_gui)
        end,
        update = function(self, x, y)
            --[[
            if GameGetFrameNum() - self.last_changed_frame > 120 then
                self.visible = false
            else
                self.visible = true
            end

            
            if not self.visible then
                return
            end
            ]]
            local gui_id = 2135745
            local new_id = function()
                gui_id = gui_id + 1
                return gui_id
            end

            GuiStartFrame(health_gui)
            local health_ratio = self.hp / self.max_hp
            local health_width = self.width * health_ratio
            local rest_width = self.width - health_width
            local screen_x, screen_y = WorldToScreenPos(health_gui, x, y)

            --GamePrint("Bar x: " .. screen_x - (self.width / 2))
            --GamePrint("Bar y: " .. screen_y - (self.height / 2))

            GuiLayoutBeginHorizontal(health_gui, screen_x - (self.width / 2), screen_y - (self.height / 2), true, 0, 0)
            GuiZSetForNextWidget(health_gui, 1100)
            GuiColorSetForNextWidget(health_gui, self.color.r / 255, self.color.g / 255, self.color.b / 255, 1)
            GuiImage(health_gui, new_id(), 0, 0, "mods/evaisa.arena/files/sprites/ui/pixel.png", 1, health_width, height, 0)
            GuiZSetForNextWidget(health_gui, 1100)
            GuiColorSetForNextWidget(health_gui, 0.2, 0.2, 0.2, 1)
            GuiImage(health_gui, new_id(), 0, 0, "mods/evaisa.arena/files/sprites/ui/pixel.png", 1, rest_width, height, 0)
            GuiLayoutEnd(health_gui)
        end
    }

    return self
end

return health_bar