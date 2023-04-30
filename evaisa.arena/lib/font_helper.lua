local nxml = dofile("mods/evaisa.arena/lib/nxml.lua")

local font_helper = {
    NewFont = function(font)

        local self = {
            character_scales = {},
            GetTextDimensions = function(self, text, scale_x, scale_y)
    
                local width = 0
                local height = 0
            
            
                for i = 1, #text do
                    local character = text:sub(i, i)
                    local character_scale = self.character_scales[character] or self.character_scales["?"]
                    if(character_scale ~= nil)then
                        if(i == #text)then
                            width = width + character_scale.rect_w
                        else
                            width = width + character_scale.spacing
                        end

                        height = math.max(height, character_scale.rect_h)
                    end
                end
            
                return width * scale_x, height * scale_y
            end
        }
    
        local font_data_text = get_content(font)
    
        local font_parsed = nxml.parse(font_data_text)
    
        for elem in font_parsed:each_child() do
            if(elem.name == "QuadChar")then
                if(elem.attr.id ~= nil)then
                    local character = string.char(tonumber(elem.attr.id))
                    local character_width = tonumber(elem.attr.rect_w)
                    local character_height = tonumber(elem.attr.rect_h)
                    local character_spacing = tonumber(elem.attr.width)
                    
                    self.character_scales[character] = {
                        rect_w = character_width,
                        rect_h = character_height,
                        spacing = character_spacing,
                    }
                end
            end
        end
    
        return self
    end
}

return font_helper