local function get_health_bar_color(health, max_health)
    local health_ratio = health / max_health
    -- generate color between green and red based on health ratio
    local r = 255 * (1 - health_ratio)
    local g = 255 * health_ratio
    local b = 0
    
    return {r = r, g = g, b = b}
end

local playerinfo_menu = {}

function playerinfo_menu:New()
    local o = {
        current_offset_percentage = 1,
        width = 120,
        height = 200,
        offset_x = 10,
        offset_y = 50,
        open = false,
        was_open = true,
        was_clicked = false,
        current_frame = 0,
        total_frames = 60,
        scroll_bar_visible = false,
    }

    o.gui = GuiCreate()

    o.Destroy = function(self)
        GuiDestroy(self.gui)
    end

    o.Close = function(self)
        self.open = false
    end

    o.Open = function(self)
        self.open = true
    end

    o.Update = function(self, data, lobby)

        local gui_id = 23532624
        local new_id = function()
            gui_id = gui_id + 1
            return gui_id
        end

        local function elasticEaseOut(t, b, c, d, a, p)
            if t == 0 then return b end
            t = t / d
            if t == 1 then return b + c end
            if not p then p = d * 0.3 end
            local s
            if not a or a < math.abs(c) then
                a = c
                s = p / 3
            else
                s = p / (2 * math.pi) * math.asin(c / a)
            end
            return b + a * math.pow(2, -10 * t) * math.sin((t * d - s) * (2 * math.pi) / p) + c
        end

        if((not self.was_open and self.open) or (self.was_open and not self.open))then
            self.current_frame = 0
        end

        if self.open then
            self.current_offset_percentage = elasticEaseOut(self.current_frame, 0, 1, self.total_frames, nil, nil)
        else
            self.current_offset_percentage = elasticEaseOut(self.current_frame, 1, -1, self.total_frames, nil, nil)
        end

        self.current_frame = self.current_frame + 1

        self.was_open = self.open




        GuiStartFrame(self.gui)

        GuiZSetForNextWidget(self.gui, 1000)

        local current_x = -(self.width - (self.width * self.current_offset_percentage))
        -- add the offset
        current_x = current_x + (self.offset_x * self.current_offset_percentage)
        
        local button_id = new_id()
        --[[
        local player_test_list = {
            {
                health = 100,
                max_health = 100,
                name = "eba",
                perks = {
                    {"WORM_ATTRACTOR", 2},
                    {"FOOD_CLOCK", 1},
                    {"GLASS_CANNON", 5},
                    {"HEARTS_MORE_EXTRA_HP", 2},
                    {"VAMPIRISM", 1}
                }
            },
            {
                health = 80,
                max_health = 100,
                name = "noitabotti",
            },
            {
                health = 60,
                max_health = 100,
                name = "sussus amogus",
            },
            {
                health = 40,
                max_health = 100,
                name = "john",
            },
            {
                health = 20,
                max_health = 100,
                name = "morbius",
            },
            {
                health = 70,
                max_health = 100,
                name = "real player",
            },
            {
                health = 50,
                max_health = 100,
                name = "susi",
            },
            {
                health = 30,
                max_health = 120,
                name = "dave",
            },
            {
                health = 10,
                max_health = 100,
                name = "jim",
            },
            {
                health = 1,
                max_health = 100,
                name = "bob",
            },
            {
                health = 100,
                max_health = 100,
                name = "eba",
            },
            {
                health = 80,
                max_health = 100,
                name = "noitabotti",
            },
            {
                health = 60,
                max_health = 100,
                name = "sussus amogus",
            },
            {
                health = 40,
                max_health = 100,
                name = "john",
            },
            {
                health = 20,
                max_health = 100,
                name = "morbius",
            },
            {
                health = 70,
                max_health = 100,
                name = "real player",
            },
            {
                health = 50,
                max_health = 100,
                name = "susi",
            },
            {
                health = 30,
                max_health = 120,
                name = "dave",
            },
            {
                health = 10,
                max_health = 100,
                name = "jim",
            },
            {
                health = 1,
                max_health = 100,
                name = "bob",
            },
        }

        ]]
        local player_count = 0
        for k, v in pairs(data.players)do
            player_count = player_count + 1
        end

        --local player_count = #player_test_list

        local scrollbar_offset = player_count > 7 and -8 or 0
        local index = 0

        local player_perk_sprites = {}
        local perk_draw_x = 0
        local perk_draw_y = 0
        local player_index = 0

        local scroll_offset = 0

        local draw_perks = false

        local draw_hp_info = false
        local hovered_max_hp = 0
        local hovered_hp = 0

        GuiBeginScrollContainer(self.gui, new_id(), current_x, self.offset_y, self.width + scrollbar_offset, self.height)
        
        GuiLayoutBeginVertical(self.gui, 0, 0, true)
        --for k, v in pairs(player_test_list)do
        for k, v in pairs(data.players)do
            index = index + 1
            local playerid = gameplay_handler.FindUser(lobby, k)
            local username = v.name or steam.friends.getFriendPersonaName(playerid)
            GuiZSetForNextWidget(self.gui, 900)
            GuiText(self.gui, 0, 0, username)
            if(index == 1)then
                local _, _, _, _, scroll_y, _, _ = GuiGetPreviousWidgetInfo(self.gui)
                scroll_offset = scroll_y - self.offset_y - 2
            end
            local health_ratio = v.health / v.max_health
            local health_bar_width = 90
            local health_width = health_bar_width * health_ratio
            local rest_width = health_bar_width - health_width

            --local hp_text = tostring(v.health).."/"..tostring(v.max_health)

            -- generate a percentage out of health_width and rest_width
            local health_percentage = health_width / health_bar_width
            local rest_percentage = rest_width / health_bar_width
            
            local health_bar_color = get_health_bar_color(v.health, v.max_health)

            GuiLayoutBeginHorizontal(self.gui, 0, 0, true, 0, 0)
            GuiZSetForNextWidget(self.gui, 900)
            GuiColorSetForNextWidget(self.gui, health_bar_color.r / 255, health_bar_color.g / 255, health_bar_color.b / 255, 1)
            GuiImage(self.gui, new_id(), 0, 0, "mods/evaisa.arena/files/sprites/ui/bar90px.png", 1, health_percentage, 1, 0)
            local _, _, hp_hovered1, _, _, _, _ = GuiGetPreviousWidgetInfo(self.gui)

            if(hp_hovered1)then
                player_index = index
                hovered_max_hp = v.max_health
                hovered_hp = v.health
                draw_hp_info = true
            end

            
            GuiZSetForNextWidget(self.gui, 900)
            GuiColorSetForNextWidget(self.gui, 0.2, 0.2, 0.2, 1)
            GuiImage(self.gui, new_id(), 0, 0, "mods/evaisa.arena/files/sprites/ui/bar90px.png", 1, rest_percentage, 1, 0)
            local _, _, hp_hovered2, _, _, _, _ = GuiGetPreviousWidgetInfo(self.gui)

            if(hp_hovered2)then
                player_index = index
                hovered_max_hp = v.max_health
                hovered_hp = v.health
                draw_hp_info = true
            end

            GuiZSetForNextWidget(self.gui, 900)
            GuiImageButton(self.gui, new_id(), 0, -7, "", "data/ui_gfx/perk_icons/perks_hover_for_more.png")
            local clicked, right_clicked, hovered, draw_x, draw_y, _, _ = GuiGetPreviousWidgetInfo(self.gui)
            if(hovered)then
                player_index = index
                if(v.perks)then
                    for k, v in ipairs(v.perks)do
                        local perk = v[1]
                        local count = v[2]
                
                        local perk_sprite = perk_sprites[perk]
                        
                        if(perk_sprite)then
                            for i = 1, count do
                                table.insert(player_perk_sprites, perk_sprite)
                            end
                        end
                    end
                end
                draw_perks = true
            end
            perk_draw_x = draw_x
            perk_draw_y = draw_y
            GuiLayoutEnd(self.gui)
            if(index ~= player_count)then
                GuiText(self.gui, 0, -15, " ")
            end
            
        end

        GuiLayoutEnd(self.gui)

        GuiEndScrollContainer(self.gui)
        
        local draw_pos = self.offset_y + 5 + (23 * (player_index - 1))

        draw_pos = draw_pos + scroll_offset

        draw_pos = draw_pos + 10

        if(draw_perks)then

            GuiBeginAutoBox(self.gui)
            if(#player_perk_sprites > 0)then
                local width = 7
                local pdg_x = 16 -- sprite width + padding between each icon
                local pdg_y = 16 -- sprite height + padding between each icon
                -- optionally add offset
                for i = 0, #player_perk_sprites do
                    local pos_x = i % width
                    local pos_y = math.floor(i / width)
                    GuiZSetForNextWidget(self.gui, 800)
                    GuiImage(self.gui, new_id(), perk_draw_x + (pos_x * pdg_x), (draw_pos + (pos_y * pdg_y)), player_perk_sprites[i+1], 1, 1, 1)
                end
            else
                GuiZSetForNextWidget(self.gui, 800)
                GuiText(self.gui, perk_draw_x, draw_pos, "No perks")
            end
            GuiZSetForNextWidget(self.gui, 850)

            GuiEndAutoBoxNinePiece(self.gui, 1)
        end

        if(draw_hp_info)then
            GuiBeginAutoBox(self.gui)
            GuiZSetForNextWidget(self.gui, 800)
            GuiText(self.gui, perk_draw_x - 35, draw_pos + 3, tostring(math.floor(hovered_hp * 25)).."/"..tostring(math.floor(hovered_max_hp * 25)))
            GuiZSetForNextWidget(self.gui, 850)
            GuiEndAutoBoxNinePiece(self.gui, 1)
        end

        GuiZSetForNextWidget(self.gui, 1000)
        local tab = GuiImage(self.gui, button_id, current_x + self.width + 6, self.offset_y + 10, "mods/evaisa.arena/files/sprites/ui/player_info_tab.png", 1, 1, 1)
        local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui)
        if clicked and not self.was_clicked then
            self.open = not self.open
            self.was_clicked = true 
        elseif(not clicked)then
            self.was_clicked = false
        end
    end

    setmetatable(o, self)
    self.__index = self
    return o
end

return playerinfo_menu