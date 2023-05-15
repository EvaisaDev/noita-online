local ready_counter = {}

function ready_counter.create( text, callback, finish_callback )
    local gui_ready_counter = GuiCreate()
    GuiOptionsAdd(gui_ready_counter, 2)
    GuiOptionsAdd(gui_ready_counter, 6)

    local self = {
        text = text,
        callback = callback,
        offset_x = 9,
        offset_y = 28,
        destroyed = false,
        update = function(self)
            if(self.destroyed)then
                return nil
            end

            GuiStartFrame(gui_ready_counter)

            local players_ready, players = self.callback()

            if players_ready == players then
                return true
            end

            local width, height = GuiGetTextDimensions(gui_ready_counter, self.text .. " " .. tostring(players_ready) .. " / " .. tostring(players), 1)
            local screen_width, screen_height = GuiGetScreenDimensions(gui_ready_counter)

            local x = screen_width - self.offset_x - width
            local y = screen_height - self.offset_y - height

            if(ModSettingGet("evaisa.arena.ready_count_left"))then
                x = self.offset_x
                y = screen_height - self.offset_x - height
            end

            GuiBeginAutoBox(gui_ready_counter)
            GuiZSetForNextWidget(gui_ready_counter, 1000)
            GuiText(gui_ready_counter, x, y, self.text .. " " .. tostring(players_ready) .. " / " .. tostring(players))
            GuiZSetForNextWidget(gui_ready_counter, 1001)
            GuiEndAutoBoxNinePiece(gui_ready_counter, 4)

            return false
        end,
        appy_offset = function(self, x, y)
            self.offset_x = x
            self.offset_y = y
        end,
        cleanup = function(self)
            self.destroyed = true
            GuiDestroy(gui_ready_counter)
        end
    }

    return self
end

return ready_counter