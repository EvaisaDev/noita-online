local countdown = {}
local gui_id = 125918
local new_id = function()
    gui_id = gui_id + 1
    return gui_id
end
function countdown.create( table_images, frames_between_images, finish_callback )
    local gui_countdown = GuiCreate()
    
    local self = {
        frame = 0,
        frames_between_images = frames_between_images,
        image_index = 1,
        table_images = table_images,
        finish_callback = finish_callback,
        update = function(self)
            GuiStartFrame(gui_countdown)

            self.frame = self.frame + 1
            if self.frame > self.frames_between_images then
                self.frame = 0
                self.image_index = self.image_index + 1
                if self.image_index > #self.table_images then
                    self.finish_callback()
                    GuiDestroy(gui_countdown)
                    return true
                end
            end


            local image = self.table_images[self.image_index]
            local width, height = GuiGetImageDimensions(gui_countdown, image, 1)
            local screen_width, screen_height = GuiGetScreenDimensions(gui_countdown)

            local x = (screen_width - width) / 2
            local y = (screen_height - height) / 2
            GuiZSetForNextWidget(gui_countdown, 1000)
            GuiImage(gui_countdown, new_id(), x, y, image, 1, 1, 1, 0)

            return false
        end
    }

    return self
end

return countdown