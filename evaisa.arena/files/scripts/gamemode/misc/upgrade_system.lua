dofile_once("data/scripts/lib/utilities.lua")
dofile("mods/evaisa.arena/files/scripts/gamemode/misc/upgrades.lua")
local player = dofile("mods/evaisa.arena/files/scripts/gamemode/helpers/player.lua")
--[[
    EXAMPLE:
    upgrades = {
        {
            id = "MAX_MANA",
            ui_name = "Max Mana Upgrade",
            ui_description = "Upgrade the max mana of all your wands",
            card_symbol = "mods/evaisa.arena/files/sprites/ui/upgrades/symbols/max_mana.png",
            weight = 1.0,
            func = function()
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
            card_render_size = 2,
            card_hover_multiplier = 1.1,
            started_moving_left = false,
            started_moving_right = false,
        }

        self.clean = function(self)
            GuiDestroy(self.gui)
        end

        self.pick = function(self)
            local v = self.upgrades[self.selected_index]
            self:clean()
            callback(v)
            GamePrintImportant(v.ui_name, v.ui_description)
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


            local card_image = "mods/evaisa.arena/files/sprites/ui/upgrades/card.png"

            local x, y = GuiGetScreenDimensions(self.gui)
            local card_width, card_height = GuiGetImageDimensions(self.gui, card_image, self.card_render_size)

           

            for k, v in ipairs(self.upgrades) do
            
                local multiplier = (self.selected_index == k and self.card_hover_multiplier or 1)
                local draw_size = self.card_render_size * multiplier
                
                -- Calculate total width of all cards with spacing
                local total_cards_width = (#self.upgrades * (card_width * multiplier)) + ((#self.upgrades - 1) * 10)
            
                -- Calculate the x position offset to center the entire row of cards
                local card_x_offset = x / 2 - total_cards_width / 2
            
                -- Update the card_x value with the offset
                local card_x = card_x_offset + (k - 1) * ((card_width * multiplier) + 10)
                local card_y = y / 2 - (card_height * multiplier) / 2

                -- Draw card
                GuiZSetForNextWidget(self.gui, -400)
                GuiImage(self.gui, new_id(), card_x, card_y, card_image, 1, draw_size, draw_size)
                -- Draw symbol
                local symbol_width, symbol_height = GuiGetImageDimensions(self.gui, v.card_symbol, draw_size)
                --GuiOptionsAddForNextWidget(self.gui, GUI_OPTION.NonInteractive)
                GuiZSetForNextWidget(self.gui, -500)
                GuiImage(self.gui, new_id(), card_x + (card_width * multiplier) / 2 - symbol_width / 2, card_y + (card_height * multiplier) / 2 - symbol_height / 2, v.card_symbol, 1, draw_size, draw_size)
                
                if(self.selected_index == k)then
                    -- add text under the cards
                    GuiZSetForNextWidget(self.gui, -600)
                    local name_width, name_height = GuiGetTextDimensions(self.gui, v.ui_name)
                    local description_width, description_height = GuiGetTextDimensions(self.gui, v.ui_description)
                    -- text in center of screen under the cards
                    GuiText(self.gui, x / 2 - name_width / 2, card_y + (card_height * multiplier) + 10, v.ui_name)
                    GuiText(self.gui, x / 2 - description_width / 2, card_y + (card_height * multiplier) + 10 + name_height, v.ui_description)
                end

                local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui)
                if(hovered)then
                    self.selected_index = k
                end
                --[[
                if(clicked)then
                    self.selected_index = k
                    self:pick()
                end
                ]]
                
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

            if(keys_pressed.e or keys_pressed.left_click or gamepad_a)then
                if(self.selected_index ~= nil)then
                    self:pick()
                end
            end
            
        end

        return self

    end,
}
return upgrade_system