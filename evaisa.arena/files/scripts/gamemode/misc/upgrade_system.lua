dofile_once("data/scripts/lib/utilities.lua")
dofile("mods/evaisa.arena/files/scripts/gamemode/misc/upgrades.lua")
local player = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/player.lua")
--[[
    EXAMPLE:
    upgrades = {
        {
            id = "MAX_MANA_ALL",
            ui_name = "$arena_upgrades_max_mana_all_name",
            ui_description = "$arena_upgrades_max_mana_all_description",
            card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/max_mana.png",
            card_background = "mods/evaisa.arena/files/sprites/ui/upgrades/card_blank.png",
            card_border = "mods/evaisa.arena/files/sprites/ui/upgrades/border_default.png",
            card_border_tint = {0.52, 0.31, 0.52},
            card_symbol_tint = {0.52, 0.31, 0.52},
            weight = 0.2,
            func = function( entity_who_picked )
            end,
        },
    }
]]
local upgrade_system = {
    create = function(option_count, callback)


        local function GetUpgrades(count)
            local pool = {}
            local out = {}
            local used = {}
            for _, upgrade in ipairs(upgrades)do
                if(upgrade.weight ~= nil)then
                    table.insert(pool, upgrade)
                    print("added upgrade to pool: " .. upgrade.id)
                end
            end

           -- pick random based on weight, recycle pool if empty, pick count
            for i = 1, count do
                if(#pool == 0)then
                    pool = used
                    used = {}
                end
                local total_weight = 0
                for _, upgrade in ipairs(pool)do
                    total_weight = total_weight + upgrade.weight
                end
                local random = Random(0, total_weight)
                local current_weight = 0
                for k, upgrade in ipairs(pool)do
                    current_weight = current_weight + upgrade.weight
                    if(random <= current_weight)then
                        table.insert(out, upgrade)
                        table.remove(pool, k)
                        table.insert(used, upgrade)
                        break
                    end
                end
            end
           

            return out
        end
        
        local self = {
            gui = GuiCreate(),
            upgrades = GetUpgrades(option_count),
            option_count = option_count,
            selected_index = nil,
            skip_selected = false,
            card_render_size = 2,
            card_hover_multiplier = 1.1,
            started_moving_left = false,
            started_moving_right = false,
        }

        self.clean = function(self)
            GuiDestroy(self.gui)
        end

        self.pick = function(self)

            if(self.skip_selected == true)then
                self:clean()
                callback()
                return
            end

            local v = self.upgrades[self.selected_index]
            self:clean()
            callback(v)
            GamePrintImportant(GameTextGetTranslatedOrNot(v.ui_name), GameTextGetTranslatedOrNot(v.ui_description))
            local players = EntityGetWithTag("player_unit")
            if(players ~= nil and players[1] ~= nil)then
                local player_entity = players[1]
                local x,y = EntityGetTransform( player_entity )
                EntityLoad( "data/entities/particles/image_emitters/perk_effect.xml", x, y )
                v.func(player_entity)
            end
        end

        self.draw = function(self)

            GuiStartFrame(self.gui)

            if(GameGetIsGamepadConnected())then
                GuiOptionsAdd(self.gui, GUI_OPTION.NonInteractive)
            else
                GuiOptionsRemove(self.gui, GUI_OPTION.NonInteractive)
            end

            local current_id = 21590325
            local new_id = function()
                current_id = current_id + 1
                return current_id
            end

            local x, y = GuiGetScreenDimensions(self.gui)

            local skip_enabled = true
            local added_index = 0
            if(skip_enabled)then
                added_index = 1
            end

            for k, v in ipairs(self.upgrades) do

                local card_image = "mods/evaisa.arena/files/sprites/ui/upgrades/card_blank.png"

                if(v.card_background ~= nil)then
                    card_image = v.card_background
                end

                local card_border = "mods/evaisa.arena/files/sprites/ui/upgrades/border_default.png"

                if(v.card_border ~= nil)then
                    card_border = v.card_border
                end

                local card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/default.png"

                if(v.card_symbol ~= nil)then
                    card_symbol = v.card_symbol
                end

                local card_symbol_tint = {121 / 255, 71 / 255, 56 / 255}

                if(v.card_symbol_tint ~= nil)then
                    card_symbol_tint = v.card_symbol_tint
                end

                local card_border_tint = {121 / 255, 71 / 255, 56 / 255}

                if(v.card_border_tint ~= nil)then
                    card_border_tint = v.card_border_tint
                end
            
                local card_width, card_height = GuiGetImageDimensions(self.gui, card_image, self.card_render_size)

                local multiplier = (self.selected_index == k and self.card_hover_multiplier or 1)
                local draw_size = self.card_render_size * multiplier
                
                -- Calculate total width of all cards with spacing
                local total_cards_width = ((#self.upgrades + added_index) * (card_width * multiplier)) + ((#self.upgrades - added_index) * 10)
            
                -- Calculate the x position offset to center the entire row of cards
                local card_x_offset = x / 2 - total_cards_width / 2
            
                -- Update the card_x value with the offset
                local card_x = card_x_offset + (k - 1) * ((card_width * multiplier) + 10)
                local card_y = y / 2 - (card_height * multiplier) / 2

                -- Draw card
                GuiZSetForNextWidget(self.gui, -400)
                GuiImage(self.gui, new_id(), card_x, card_y, card_image, 1, draw_size, draw_size)

                local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui)

                -- Draw border
    
                local border_width, border_height = GuiGetImageDimensions(self.gui, card_border, draw_size)
                --GuiOptionsAddForNextWidget(self.gui, GUI_OPTION.NonInteractive)
                GuiZSetForNextWidget(self.gui, -450)
                if(card_border_tint)then
                    local r, g, b = unpack(card_border_tint)
                    GuiColorSetForNextWidget(self.gui, r, g, b, 1)
                end
                --GuiImage(self.gui, new_id(), card_x, card_y, v.card_border, 1, draw_size, draw_size)
                -- adjust for border size
                GuiImage(self.gui, new_id(), card_x + (card_width * multiplier) / 2 - border_width / 2, card_y + (card_height * multiplier) / 2 - border_height / 2, card_border, 1, draw_size, draw_size)
                local clicked2, right_clicked2, hovered2 = GuiGetPreviousWidgetInfo(self.gui)
                -- Draw symbol
                local symbol_width, symbol_height = GuiGetImageDimensions(self.gui, card_symbol, draw_size)
                --GuiOptionsAddForNextWidget(self.gui, GUI_OPTION.NonInteractive)
                GuiZSetForNextWidget(self.gui, -500)
                if(card_symbol_tint)then
                    local r, g, b = unpack(card_symbol_tint)
                    GuiColorSetForNextWidget(self.gui, r, g, b, 1)
                end
                GuiImage(self.gui, new_id(), card_x + (card_width * multiplier) / 2 - symbol_width / 2, card_y + (card_height * multiplier) / 2 - symbol_height / 2, card_symbol, 1, draw_size, draw_size)
                local clicked3, right_clicked3, hovered3 = GuiGetPreviousWidgetInfo(self.gui)

                if(self.selected_index == k)then
                    -- add text under the cards
                    GuiZSetForNextWidget(self.gui, -600)
                    local name_width, name_height = GuiGetTextDimensions(self.gui, GameTextGetTranslatedOrNot(v.ui_name))
                    local description_width, description_height = GuiGetTextDimensions(self.gui, GameTextGetTranslatedOrNot(v.ui_description))
                    -- text in center of screen under the cards
                    GuiText(self.gui, x / 2 - name_width / 2, card_y + (card_height * multiplier) + 10, GameTextGetTranslatedOrNot(v.ui_name))
                    GuiText(self.gui, x / 2 - description_width / 2, card_y + (card_height * multiplier) + 10 + name_height, GameTextGetTranslatedOrNot(v.ui_description))
                end

                if(hovered)then
                    self.selected_index = k
                    self.skip_selected = false
                end
                
                if(clicked or clicked2 or clicked3)then
                    if(self.selected_index ~= nil or self.skip_selected == true)then
                        self:pick()
                    end
                end
                
                
            end

            if(skip_enabled)then
                local skip_card_image = "mods/evaisa.arena/files/sprites/ui/upgrades/skip_card.png"

                local skip_card_width, skip_card_height = GuiGetImageDimensions(self.gui, skip_card_image, self.card_render_size)

                local skip_multiplier = (self.skip_selected and self.card_hover_multiplier or 1)
                local skip_draw_size = self.card_render_size * skip_multiplier

                local total_cards_width = ((#self.upgrades + added_index) * (skip_card_width * skip_multiplier)) + ((#self.upgrades - added_index) * 10)
                -- Calculate the x position offset to center the entire row of cards
                local card_x_offset = x / 2 - total_cards_width / 2
            
                -- Update the card_x value with the offset
                local card_x = card_x_offset + ((#self.upgrades + 1) - 1) * ((skip_card_width * skip_multiplier) + 10)
                local card_y = y / 2 - (skip_card_height * skip_multiplier) / 2

                -- Draw card
                GuiZSetForNextWidget(self.gui, -400)
                GuiImage(self.gui, new_id(), card_x, card_y, skip_card_image, 1, skip_draw_size, skip_draw_size)
                local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui)
                
                if(self.skip_selected)then
                    GuiZSetForNextWidget(self.gui, -600)
                    local name_width, name_height = GuiGetTextDimensions(self.gui, GameTextGetTranslatedOrNot("$arena_upgrades_skip_name"))
                    local description_width, description_height = GuiGetTextDimensions(self.gui, GameTextGetTranslatedOrNot("$arena_upgrades_skip_description"))
                    -- text in center of screen under the cards
                    GuiText(self.gui, x / 2 - name_width / 2, card_y + (skip_card_height * skip_multiplier) + 10, GameTextGetTranslatedOrNot("$arena_upgrades_skip_name"))
                    GuiText(self.gui, x / 2 - description_width / 2, card_y + (skip_card_height * skip_multiplier) + 10 + name_height, GameTextGetTranslatedOrNot("$arena_upgrades_skip_description"))
                end


                if(hovered)then
                    self.skip_selected = true
                    self.selected_index = nil
                end
            end

            local keys_pressed = {
                e = input:WasKeyPressed("e"),
                left_click = input:WasMousePressed("left"),
            }

            local stick_x, stick_y = input:GetGamepadAxis("left_stick")
            local r_stick_x, r_stick_y = input:GetGamepadAxis("right_stick")
            local left_bumper = input:WasGamepadButtonPressed("left_shoulder")
            local right_bumper = input:WasGamepadButtonPressed("right_shoulder")
            local gamepad_a = input:WasGamepadButtonPressed("a")

            local stick_x_left = stick_x < -0.5 and (not self.started_moving_left or GameGetFrameNum() % 30 == 0)
            local stick_x_right = stick_x > 0.5 and (not self.started_moving_right or GameGetFrameNum() % 30 == 0)
            local r_stick_x_left = r_stick_x < -0.5 and (not self.started_moving_left or GameGetFrameNum() % 30 == 0)
            local r_stick_x_right = r_stick_x > 0.5 and (not self.started_moving_right or GameGetFrameNum() % 30 == 0)

            local select_left = left_bumper or stick_x_left or r_stick_x_left
            local select_right = right_bumper or stick_x_right or r_stick_x_right
            
            if(select_left)then
                if(self.selected_index == nil)then
                    self.selected_index = 1
                else
                    self.selected_index = self.selected_index - 1
                    if(self.selected_index < 1)then
                        self.selected_index = #self.upgrades
                    end
                end
            end

            if(select_right)then
                if(self.selected_index == nil)then
                    self.selected_index = 1
                else
                    self.selected_index = self.selected_index + 1
                    if(self.selected_index > #self.upgrades)then
                        self.selected_index = 1
                    end
                end
            end

            if(stick_x < -0.5 or r_stick_x < -0.5)then
                self.started_moving_left = true
            else
                self.started_moving_left = false
            end

            if(stick_x > 0.5 or r_stick_x > 0.5)then
                self.started_moving_right = true
            else
                self.started_moving_right = false
            end

            if(--[[keys_pressed.e or keys_pressed.left_click or ]]gamepad_a)then
                if(self.selected_index ~= nil or self.skip_selected == true)then
                    self:pick()
                end
            end
            
        end

        return self

    end,
}
return upgrade_system