local ready_counter = {}
local gui_id = 325123
local new_id = function()
    gui_id = gui_id + 1
    return gui_id
end

function ready_counter.create( text, callback, finish_callback )
    local gui_ready_counter = GuiCreate()
    
    local self = {
        text = text,
        callback = callback,
        finish_callback = finish_callback,
        update = function(self)
            GuiStartFrame(gui_ready_counter)

            local players_ready, players = self.callback()

            if players_ready == players then
                self.finish_callback()
                GuiDestroy(gui_ready_counter)
                return true
            end

            local width, height = GuiGetTextDimensions(gui_ready_counter, self.text, 1)
            local screen_width, screen_height = GuiGetScreenDimensions(gui_ready_counter)

            local x = 15
            local y = height + 80
            GuiBeginAutoBox(gui_ready_counter)
            GuiZSetForNextWidget(gui_ready_counter, 1000)
            GuiText(gui_ready_counter, x, y, self.text .. " " .. tostring(players_ready) .. " / " .. tostring(players))
            GuiZSetForNextWidget(gui_ready_counter, 1001)
            GuiEndAutoBoxNinePiece(gui_ready_counter, 4)

            return false
        end
    }

    return self
end

return ready_counter