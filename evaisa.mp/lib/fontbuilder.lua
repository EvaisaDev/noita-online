local fontbuilder = {}

fontbuilder.generate = function(font_lua_file, output_file)

	local nxml = dofile("mods/evaisa.mp/lib/nxml.lua")

    -- get folder path from font_lua_file
    local folder_path = font_lua_file:match("(.*/)")
    -- load font lua file
    loadfile(font_lua_file)()
    
    local texture = file
    local line_height = height
    local char_space = 1
    local word_space = 0

    -- create nxml 
    local xml = nxml.parse("<FontData></FontData>")
    
    -- create texture node
    local texture = nxml.parse("<Texture>"..texture.."</Texture>")
    local line_height = nxml.parse("<LineHeight>"..line_height.."</LineHeight>")
    local char_space = nxml.parse("<CharSpace>"..char_space.."</CharSpace>")
    local word_space = nxml.parse("<WordSpace>"..word_space.."</WordSpace>")

    xml:add_child(texture)
    xml:add_child(line_height)
    xml:add_child(char_space)
    xml:add_child(word_space)
    
    for i = 1, #chars do

        local char = nxml.parse("<Char id=\""..utf8.byte(chars[i].char).."\" rect_h=\""..chars[i].h.."\" rect_w=\""..chars[i].w.."\" rect_x=\""..chars[i].x.."\" rect_y=\""..chars[i].y.."\" ></Char>")
    
        xml:add_child(char)
    end


    -- write to file
    --local file = io.open(output_file, "w")
    --file:write(tostring(xml))
end

return fontbuilder