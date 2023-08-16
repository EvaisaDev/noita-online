local player = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/player.lua")

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
        player_index = 0,
    }

    o.gui = GuiCreate()

    local player_id = steam.user.getSteamID()
    local self_name = steamutils.getTranslatedPersonaName(player_id)

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

        
        if(data.using_controller)then
            GuiOptionsAdd(self.gui, GUI_OPTION.NonInteractive)
        end

        GuiOptionsAdd(self.gui, GUI_OPTION.NoPositionTween)

        GuiZSetForNextWidget(self.gui, 1000)

        local current_x = -(self.width - (self.width * self.current_offset_percentage))
        -- add the offset
        current_x = current_x + (self.offset_x * self.current_offset_percentage)
        
        local button_id = new_id()

        local player_count = 0
        for k, v in pairs(data.players)do
            player_count = player_count + 1
        end

        --local player_count = #player_test_list
        local debug_repeat = 0

        if(debug_repeat > 0)then
            player_count = debug_repeat
        end

        local spectator = data.spectator_mode

        local scrollbar_offset = player_count > 2 and -8 or 0
        local index = spectator and 0 or 1

        local player_perk_sprites = {}
        local perk_draw_x = 0
        local perk_draw_y = 0

        local scroll_offset = 0

        local draw_perks = false

        local draw_hp_info = false
        local hovered_max_hp = 0
        local hovered_hp = 0

        local text_height_self = 0
        local text_height_other = 0

        if(not self.open)then
            scrollbar_offset = 0
        end

        GuiBeginScrollContainer(self.gui, new_id(), current_x, self.offset_y, self.width + scrollbar_offset, self.height)
        
        if(self.open)then
            GuiLayoutBeginVertical(self.gui, 0, 0, true)

            local DrawTextElement = function(formatting_string, value)
                GuiZSetForNextWidget(self.gui, 900)
                GuiColorSetForNextWidget(self.gui, 1, 1, 1, 0.8)
                GuiText(self.gui, 0, value and -2 or 0, string.format(GameTextGetTranslatedOrNot(formatting_string), tostring(value or "")))
                local _, _, _, _, _, elem_w, elem_h = GuiGetPreviousWidgetInfo(self.gui)
                return elem_h
            end

            ------------- DRAW OUR OWN CARD (if not spectator) ---------------

            if(not spectator)then

                local hp = data.client.hp or 100
                local max_hp = data.client.max_hp or 100


                if(hp < 0)then
                    hp = 0
                end
                if(max_hp < 0)then
                    max_hp = 100
                end
                if(hp > max_hp)then
                    hp = max_hp
                end

                local wins = ArenaGameplay.GetWins(lobby, player_id, data)
                local winstreak = ArenaGameplay.GetWinstreak(lobby, player_id, data)
                            


                local self_ready = GameHasFlagRun("ready_check")
                if(self_ready)then
                    GuiZSetForNextWidget(self.gui, 900)
                    GuiLayoutBeginHorizontal(self.gui, 0, 0, true)

                    GuiImage(self.gui, new_id(), 0, 2, "mods/evaisa.arena/files/sprites/ui/check.png", 1, 1, 1, 0)
                end
                GuiZSetForNextWidget(self.gui, 900)
                local color = game_funcs.ID2Color(player_id)
                if(color == nil)then
                    color = {r = 255, g = 255, b = 255}
                end
                local r, g, b = color.r, color.g, color.b
                local a = 1
                GuiColorSetForNextWidget(self.gui, r / 255, g / 255, b / 255, a)

                GuiText(self.gui, 0, 0, self_name.." ("..GameTextGetTranslatedOrNot("$arena_playerinfo_you")..")")

                local _, _, _, _, scroll_y, _, name_height = GuiGetPreviousWidgetInfo(self.gui)
                text_height_self = text_height_self + name_height
                scroll_offset = scroll_y - self.offset_y - 2

                if(self_ready)then
                    GuiLayoutEnd(self.gui)
                end

                --[[
                GuiZSetForNextWidget(self.gui, 900)
                GuiColorSetForNextWidget(self.gui, 1, 1, 1, 0.8)
                GuiText(self.gui, 0, self_ready and -2 or 0, string.format(GameTextGetTranslatedOrNot("$arena_playerinfo_wins"), tostring(wins)))

                GuiZSetForNextWidget(self.gui, 900)
                GuiColorSetForNextWidget(self.gui, 1, 1, 1, 0.8)
                GuiText(self.gui, 0, 0, string.format(GameTextGetTranslatedOrNot("$arena_playerinfo_winstreak"), tostring(winstreak)))
                ]]

                text_height_self = text_height_self + DrawTextElement("$arena_playerinfo_wins", wins)
                text_height_self = text_height_self + DrawTextElement("$arena_playerinfo_winstreak", winstreak)

                local health_ratio = hp / max_hp
                local health_bar_width = 90
                local health_width = health_bar_width * health_ratio
                local rest_width = health_bar_width - health_width

                local health_percentage = health_width / health_bar_width
                local rest_percentage = rest_width / health_bar_width

                local health_bar_color = get_health_bar_color(hp, max_hp)

                GuiLayoutBeginHorizontal(self.gui, 0, 0, true, 0, 0)
                GuiZSetForNextWidget(self.gui, 900)
                GuiColorSetForNextWidget(self.gui, health_bar_color.r / 255, health_bar_color.g / 255, health_bar_color.b / 255, 1)
                GuiImage(self.gui, new_id(), 0, 0, "mods/evaisa.arena/files/sprites/ui/bar90px.png", 1, health_percentage, 1, 0)
                local _, _, hp_hovered1, _, _, _, _ = GuiGetPreviousWidgetInfo(self.gui)

                if(hp_hovered1)then
                    self.player_index = index
                    hovered_max_hp = max_hp
                    hovered_hp = hp
                    draw_hp_info = true
                end


                GuiZSetForNextWidget(self.gui, 900)
                GuiColorSetForNextWidget(self.gui, 0.2, 0.2, 0.2, 1)
                GuiImage(self.gui, new_id(), 0, 0, "mods/evaisa.arena/files/sprites/ui/bar90px.png", 1, rest_percentage, 1, 0)
                local _, _, hp_hovered2, _, _, _, _ = GuiGetPreviousWidgetInfo(self.gui)

                if(hp_hovered2)then
                    self.player_index = index
                    hovered_max_hp = max_hp
                    hovered_hp = hp
                    draw_hp_info = true
                end

                GuiZSetForNextWidget(self.gui, 900)
                GuiImageButton(self.gui, new_id(), 0, -7, "", "data/ui_gfx/perk_icons/perks_hover_for_more.png")
                local clicked, right_clicked, hovered, draw_x, draw_y, _, _ = GuiGetPreviousWidgetInfo(self.gui)
                if(hovered)then
                    self.player_index = index
                    if(data.client.perks)then
                        for k, v in ipairs(data.client.perks)do
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
            end
            -----------------------------------------------


            --for k, v in pairs(player_test_list)do
            for k, v in pairs(data.players)do
                local draw_player_data = function()

                    index = index + 1
                    local playerid = k
                    if(playerid ~= nil)then
                        if(v.health == nil)then
                            v.health = 0
                        end
                        if(v.health < 0)then
                            v.health = 0
                        end
                        if(v.max_health == nil)then
                            v.max_health = 100
                        end
                        if(v.max_health < 0)then
                            v.max_health = 100
                        end
                        if(v.health > v.max_health)then
                            v.health = v.max_health
                        end
                        if(v.ready)then
                            GuiLayoutBeginHorizontal(self.gui, 0, 0, true)
                        
                            GuiImage(self.gui, new_id(), 0, 2, "mods/evaisa.arena/files/sprites/ui/check.png", 1, 1, 1, 0)
                        end

                        if(v.name == nil)then
                            v.name = steamutils.getTranslatedPersonaName(gameplay_handler.FindUser(lobby, playerid))
                        end

                        local username = v.name
                        GuiZSetForNextWidget(self.gui, 900)
                        local color = game_funcs.ID2Color(playerid)
                        if(color == nil)then
                            color = {r = 255, g = 255, b = 255}
                        end
                        local r, g, b = color.r, color.g, color.b
                        local a = 1
                        GuiColorSetForNextWidget(self.gui, r / 255, g / 255, b / 255, a)
                        GuiText(self.gui, 0, 0, username)
                        local _, _, _, _, _, _, text_height = GuiGetPreviousWidgetInfo(self.gui)

                        if(v.ready)then
                            GuiLayoutEnd(self.gui)
                        end

                        --[[
                        GuiZSetForNextWidget(self.gui, 900)
                        GuiColorSetForNextWidget(self.gui, 1, 1, 1, 0.8)
                        GuiText(self.gui, 0, v.ready and -2 or 0, string.format(GameTextGetTranslatedOrNot("$arena_playerinfo_ping"), tostring(v.ping)))
                        
                        GuiZSetForNextWidget(self.gui, 900)
                        GuiColorSetForNextWidget(self.gui, 1, 1, 1, 0.8)
                        GuiText(self.gui, 0, 0, string.format(GameTextGetTranslatedOrNot("$arena_playerinfo_delay"), tostring(v.delay_frames)))

                        local wins = ArenaGameplay.GetWins(lobby, playerid)
                        
                        GuiZSetForNextWidget(self.gui, 900)
                        GuiColorSetForNextWidget(self.gui, 1, 1, 1, 0.8)
                        GuiText(self.gui, 0, 0, string.format(GameTextGetTranslatedOrNot("$arena_playerinfo_wins"), tostring(wins)))
                        
                        local winstreak = ArenaGameplay.GetWinstreak(lobby, playerid)

                        GuiZSetForNextWidget(self.gui, 900)
                        GuiColorSetForNextWidget(self.gui, 1, 1, 1, 0.8)
                        GuiText(self.gui, 0, 0, string.format(GameTextGetTranslatedOrNot("$arena_playerinfo_winstreak"), tostring(winstreak)))

                        ]]
                        local ping_height = DrawTextElement("$arena_playerinfo_ping", v.ping)
                        local delay_height = DrawTextElement("$arena_playerinfo_delay", v.delay_frames)
                        local wins_height = DrawTextElement("$arena_playerinfo_wins", ArenaGameplay.GetWins(lobby, playerid, data))
                        local winstreak_height = DrawTextElement("$arena_playerinfo_winstreak", ArenaGameplay.GetWinstreak(lobby, playerid, data))
                        
                        --print("index is "..tostring(index) .. " player_index is "..tostring(self.player_index))

                        if(index == self.player_index)then
                            --print("index is stuff")
                            text_height_other = text_height_other + text_height
                            text_height_other = text_height_other + ping_height
                            text_height_other = text_height_other + delay_height
                            text_height_other = text_height_other + wins_height
                            text_height_other = text_height_other + winstreak_height
                            text_height_other = text_height_other + 4
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
                            self.player_index = index
                            hovered_max_hp = v.max_health
                            hovered_hp = v.health
                            draw_hp_info = true
                        end
        
                        
                        GuiZSetForNextWidget(self.gui, 900)
                        GuiColorSetForNextWidget(self.gui, 0.2, 0.2, 0.2, 1)
                        GuiImage(self.gui, new_id(), 0, 0, "mods/evaisa.arena/files/sprites/ui/bar90px.png", 1, rest_percentage, 1, 0)
                        local _, _, hp_hovered2, _, _, _, _ = GuiGetPreviousWidgetInfo(self.gui)
        
                        if(hp_hovered2)then
                            self.player_index = index
                            hovered_max_hp = v.max_health
                            hovered_hp = v.health
                            draw_hp_info = true
                        end
        
                        GuiZSetForNextWidget(self.gui, 900)
                        GuiImageButton(self.gui, new_id(), 0, -7, "", "data/ui_gfx/perk_icons/perks_hover_for_more.png")
                        local clicked, right_clicked, hovered, draw_x, draw_y, _, _ = GuiGetPreviousWidgetInfo(self.gui)
                        if(hovered)then
                            self.player_index = index
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
                end

                if(debug_repeat > 0)then
                    for i = 1, debug_repeat do
                        draw_player_data()
                    end
                else
                    draw_player_data()
                end
            end


            GuiLayoutEnd(self.gui)
        end

        GuiEndScrollContainer(self.gui)

        --print(tostring(text_height_self))
        
        local draw_pos = 0
        if((not spectator) and self.player_index == 1)then
            draw_pos = self.offset_y + text_height_self
        else
            local additional_offset = text_height_self
            local magic_number = text_height_other
            local player_index_offset = 1
            if(spectator)then
                player_index_offset = 0
            end

            draw_pos = self.offset_y + additional_offset + (magic_number * (self.player_index - player_index_offset))
            draw_pos = draw_pos + 4
        end

        draw_pos = draw_pos + scroll_offset

        --draw_pos = draw_pos + 11

        if(draw_perks)then
            perk_draw_x = perk_draw_x + 11
            GuiBeginAutoBox(self.gui)
            if(#player_perk_sprites > 0)then
                local width = 7
                local pdg_x = 16 -- sprite width + padding between each icon
                local pdg_y = 16 -- sprite height + padding between each icon
                -- optionally add offset
                for i = 0, #player_perk_sprites - 1 do
                    local pos_x = i % width
                    local pos_y = math.floor(i / width)
                    GuiZSetForNextWidget(self.gui, 800)
                    GuiImage(self.gui, new_id(), perk_draw_x + (pos_x * pdg_x), 1 + (draw_pos + (pos_y * pdg_y)), player_perk_sprites[i+1], 1, 1, 1)
                end
            else
                GuiZSetForNextWidget(self.gui, 800)
                GuiText(self.gui, perk_draw_x, draw_pos + 1, GameTextGetTranslatedOrNot("$arena_playerinfo_no_perks"))
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