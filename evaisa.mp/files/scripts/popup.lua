dofile_once("data/scripts/lib/utilities.lua")

pretty = require("pretty_print")
--[[
popup_gui = popup_gui or GuiCreate()

GuiStartFrame(popup_gui)

if(GameGetIsGamepadConnected())then
    GuiOptionsAdd(popup_gui, GUI_OPTION.NonInteractive)
end

GuiOptionsAdd( chat_gui, GUI_OPTION.NoPositionTween )

local screen_width, screen_height = GuiGetScreenDimensions( chat_gui );
]]
active_popups = active_popups or {}

local popups = {}

popups.create = function(id, name, description, options, z_index)
    local popup = {}
    popup.id = id
    popup.name = name
    popup.description = description
    popup.options = options
    popup.gui = GuiCreate()
    popup.current_id = 124
    popup.z_index = z_index or 0
    popup.start = function(self)
        GuiStartFrame(popup.gui)
        self.current_id = 124
    end
    popup.new_id = function(self)
        self.current_id = self.current_id + 1
        return self.current_id
    end

    -- if active popups already contains popup with same id, remove it and GuiDestroy
    for i = #active_popups, 1, -1 do
        local active_popup = active_popups[i]
        if (active_popup.id == popup.id) then
            table.remove(active_popups, i)
            GuiDestroy(active_popup.gui)
        end
    end

    table.insert(active_popups, popup)
end

popups.update = function()
    local to_destroy = {}

    -- iterate in reverse
    for i = #active_popups, 1, -1 do
        local popup = active_popups[i]

        popup:start()

        local screen_width, screen_height = GuiGetScreenDimensions(popup.gui)

        local z_index = popup.z_index - (i + 10)

        --print("z_index: " .. tostring(z_index))
        --print(pretty.table(popup))

        GuiBeginAutoBox(popup.gui)
        GuiLayoutBeginVertical(popup.gui, 0, 0)
        if (popup.name) then
            GuiColorSetForNextWidget(popup.gui, 1, 1, 1, 1)
            local text_width, text_height = GuiGetTextDimensions(popup.gui, popup.name)
            GuiZSetForNextWidget(popup.gui, z_index - 1)
            GuiOptionsAddForNextWidget(popup.gui, GUI_OPTION.Align_HorizontalCenter)
            GuiText(popup.gui, (screen_width / 2), (screen_height / 2) - (text_height / 2), popup.name)
        end
        if (popup.description) then
            if(type(popup.description) == "string")then
                GuiColorSetForNextWidget(popup.gui, 1, 1, 1, 0.8)
                local text_width, text_height = GuiGetTextDimensions(popup.gui, popup.description)
                GuiZSetForNextWidget(popup.gui, z_index - 1)
                GuiOptionsAddForNextWidget(popup.gui, GUI_OPTION.Align_HorizontalCenter)
                GuiText(popup.gui, (screen_width / 2), 0, popup.description)
            elseif(type(popup.description) == "table")then
                for i, line in ipairs(popup.description) do
                    if(type(line) == "string")then
                        GuiColorSetForNextWidget(popup.gui, 1, 1, 1, 0.8)
                        local text_width, text_height = GuiGetTextDimensions(popup.gui, line)
                        GuiZSetForNextWidget(popup.gui, z_index - 1)
                        GuiOptionsAddForNextWidget(popup.gui, GUI_OPTION.Align_HorizontalCenter)
                        GuiText(popup.gui, (screen_width / 2), 0, line)
                    elseif(type(line) == "table")then
                        local text_string = line.text
                        local text_color = line.color

                        if(text_color)then
                            GuiColorSetForNextWidget(popup.gui, text_color[1], text_color[2], text_color[3], text_color[4])
                        else
                            GuiColorSetForNextWidget(popup.gui, 1, 1, 1, 0.8)
                        end

                        local text_width, text_height = GuiGetTextDimensions(popup.gui, text_string)
                        GuiZSetForNextWidget(popup.gui, z_index - 1)
                        GuiOptionsAddForNextWidget(popup.gui, GUI_OPTION.Align_HorizontalCenter)
                        GuiText(popup.gui, (screen_width / 2), 0, text_string)
                    end
                end
            end
        end


        local final_options = {}
        for j, option in ipairs(popup.options) do
            local id = popup:new_id()
            local text_width, text_height = GuiGetTextDimensions(popup.gui, option.text)
            table.insert(final_options, { id = id, option = option, width = text_width })
        end

        GuiLayoutBeginHorizontal(popup.gui, 0, 0, false, 0, 0)
        -- center buttons next to eachother, with a bit of padding
        local total_width = 0
        for j, option in ipairs(final_options) do
            total_width = total_width + option.width
            if (j ~= #final_options) then
                total_width = total_width + 20
            end
        end
        local x = (screen_width / 2) - (total_width / 2)
        for j, option in ipairs(final_options) do
            GuiColorSetForNextWidget(popup.gui, 1, 1, 1, 1)
            GuiZSetForNextWidget(popup.gui, z_index - 1)
            if (GuiButton(popup.gui, option.id, j == 1 and x or 20, 4, option.option.text)) then
                table.remove(active_popups, i)
                table.insert(to_destroy, popup.gui)
                option.option.callback()
            end
        end

        GuiLayoutEnd(popup.gui)

        GuiLayoutEnd(popup.gui)

        GuiZSetForNextWidget(popup.gui, z_index)
        GuiEndAutoBoxNinePiece(popup.gui, 5, 0, 0, true)
    end

    for i, gui in ipairs(to_destroy) do
        GuiDestroy(gui)
    end
end

return popups
