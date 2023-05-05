local text_input = {}

text_input.create = function(gui, x, y, width, default_text, character_limit, allowed_characters, banned_characters, z_index)
    local input_instance = {}
    input_instance.gui = gui
    input_instance.x = x
    input_instance.y = y
    input_instance.width = width
    input_instance.default_text = default_text
    input_instance.character_limit = character_limit or 0
    input_instance.allowed_characters = {}
    input_instance.banned_characters = {}
    input_instance.z_index = z_index or 0
    input_instance.text = default_text or ""
    input_instance.cursor_pos = 0
    input_instance.cursor_timer = 0
    input_instance.cursor_visible = true
    input_instance.focus = false
    input_instance.id = 159023

    allowed_characters = allowed_characters or nil

    mp_log:print("Creating text input with allowed characters: " .. tostring(allowed_characters))

    -- add allowed characters

    if(allowed_characters ~= nil)then
        for char_index = 1, utf8.len(allowed_characters) do
            local character = utf8.sub(allowed_characters, char_index, char_index)
            input_instance.allowed_characters[character] = true
        end
    end

    -- add banned characters

    if(banned_characters ~= nil)then
        for char_index = 1, utf8.len(banned_characters) do
            local character = utf8.sub(banned_characters, char_index, char_index)
            input_instance.banned_characters[character] = true
        end
    end

    input_instance.new_id = function(self)
        self.id = self.id + 1
        return self.id
    end

    input_instance.start_frame = function(self)
        GuiStartFrame(self.gui)
        self.id = 0
    end

    input_instance.transform = function(self, x, y, width)
        self.width = width
        self.x = x
        self.y = y
    end

    input_instance.update = function(self)
        -- calculate cursor visibility
        self.cursor_timer = self.cursor_timer + 1
        if (self.cursor_timer > 30) then
            self.cursor_timer = 0
            self.cursor_visible = not self.cursor_visible
        end

        --print(json.stringify(input:GetChars()))
        
        if(input:GetInput("space"))then

            -- make sure we are not over the character limit
            if(self.character_limit > 0 and utf8.len(self.text) >= self.character_limit)then
                return
            end

            self.text = utf8.sub(self.text, 1, self.cursor_pos) .. " " .. utf8.sub(self.text, self.cursor_pos + 1)
            self.cursor_pos = self.cursor_pos + 1
            if(self.cursor_pos > utf8.len(self.text))then
                self.cursor_pos = utf8.len(self.text)
            end
        elseif(input:GetInput("backspace"))then
            self.text = utf8.sub(self.text, 1, self.cursor_pos - 1) .. utf8.sub(self.text, self.cursor_pos + 1)
            self.cursor_pos = math.max(0, self.cursor_pos - 1)
        elseif(input:GetInput("delete"))then
            self.text = utf8.sub(self.text, 1, self.cursor_pos) .. utf8.sub(self.text, self.cursor_pos + 2)
        elseif(input:GetInput("left"))then
            self.cursor_pos = math.max(0, self.cursor_pos - 1)
        elseif(input:GetInput("right"))then
            self.cursor_pos = math.min(self.cursor_pos + 1, utf8.len(self.text))
        else
            local chars = input:GetChars() or {}

            for k, v in ipairs(chars)do

                -- make sure we are not over the character limit
                if(self.character_limit > 0 and utf8.len(self.text) >= self.character_limit)then
                    return
                end

                --print("Char: " .. tostring(v))
                if (#(self.allowed_characters) == 0 or self.allowed_characters[v]) then
                    self.text = utf8.sub(self.text, 1, self.cursor_pos) .. v .. utf8.sub(self.text, self.cursor_pos + 1)
                    self.cursor_pos = self.cursor_pos + 1
                end
            end
        end

    end

    input_instance.draw = function(self)
        self:start_frame()

        local scroll_container_id = 35238523 + GameGetFrameNum() % 2
        GuiBeginScrollContainer(self.gui, scroll_container_id, self.x + 2, self.y + 2, self.width - 4, 8, false, 0, 0)

        -- split text at cursor position
        local text_before_cursor = utf8.sub(self.text, 1, self.cursor_pos)
        local text_after_cursor = utf8.sub(self.text, self.cursor_pos + 1)
        local text_width, text_height = GuiGetTextDimensions(self.gui, self.text)

        -- Check if the text_width is more significant than the container width, then get the cursor width
        local cursor_width = 0
        if text_width > self.width then
            local text_before_cursor = utf8.sub(self.text, 1, self.cursor_pos)
            cursor_width = GuiGetTextDimensions(self.gui, text_before_cursor)
        end

        -- calculate text offset
        local text_offset_x = math.max(0, cursor_width - (self.width - 6))

        GuiLayoutBeginHorizontal(self.gui, -text_offset_x, -1, true)

        -- draw text before cursor
        GuiText(self.gui, 0, 0, text_before_cursor)

        -- draw cursor
        GuiImage(self.gui, self:new_id(), -2, 1, "mods/evaisa.mp/files/gfx/ui/input_cursor.png", self.cursor_visible and 1 or 0, 1, 1)

        -- draw text after cursor
        GuiText(self.gui, -2, 0, text_after_cursor)

        GuiLayoutEnd(self.gui)

        GuiEndScrollContainer(self.gui)
    end

    return input_instance
end

return text_input
