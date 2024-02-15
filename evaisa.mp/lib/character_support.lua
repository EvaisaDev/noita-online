char_ranges = {
    ["data/fonts/generated/notosans_zhcn_48.bin"] = {
        {32, 254},
        {8220, 8221},
        {8734, 8734},
        {12289, 12290},
        {12298, 12299},
        {13312, 19902},
        {19968, 40958},
        {65281, 65281},
        {65288, 65289},
        {65292, 65292},
        {65306, 65306},
        {65311, 65311},
        {177984, 178206},
    },
    ["data/fonts/generated/notosans_jp_48.bin"] = {
        {32, 254},
        {8230, 8230},
        {8734, 8734},
        {12289, 12290},
        {12293, 12293},
        {12300, 12301},
        {12352, 12446},
        {12448, 12542},
        {19968, 40894},
        {65281, 65281},
        {65288, 65289},
        {65306, 65306},
        {65311, 65311},
    },
    ["data/fonts/generated/notosans_ko_48.bin"] = {
        {32, 254},
        {4352, 4606},
        {8734, 8734},
        {12592, 12686},
        {43360, 43390},
        {44032, 55202},
        {55216, 55294},
    },
    ["data/fonts/font_pixel.xml"] = {
        
    }
}

language_fonts = {
    ["简体中文"] = "data/fonts/generated/notosans_zhcn_48.bin",
    ["日本語"] = "data/fonts/generated/notosans_jp_48.bin",
    ["한국어"] = "data/fonts/generated/notosans_ko_48.bin",
}

get_font_characters = function(font)
    local font_data_text = get_content(font)
    
    local font_parsed = nxml.parse(font_data_text)

    local chars = {}

    for elem in font_parsed:each_child() do
        if elem.name == "QuadChar" and elem.attr.id ~= nil then
            local char = tonumber(elem.attr.id)
            table.insert(chars, char)
        end
    end

    table.sort(chars)

    return chars
end

-- only supports xml fonts
register_font = function(font)
    local chars = get_font_characters(font)

    char_ranges[font] = {}

    local range_start = chars[1]
    local range_end = chars[1]

    for i = 2, #chars do
        local char = chars[i]
        if(char == range_end + 1)then
            range_end = char
        else
            table.insert(char_ranges[font], {range_start, range_end})
            range_start = char
            range_end = char
        end
    end

    table.insert(char_ranges[font], {range_start, range_end})
end

register_font("data/fonts/font_pixel.xml")
register_font("data/fonts/font_pixel_big.xml")

get_current_font = function(huge)
    local current_font = "data/fonts/font_pixel.xml"

    if(huge)then
        current_font = "data/fonts/font_pixel_huge.xml"
    end

    local lang = GameTextGetTranslatedOrNot("$current_language")

    if(language_fonts[lang])then
        current_font = language_fonts[lang]
    end

    return current_font
end

char_supported = function(font, char)
    local char_code = utf8.codepoint(char)
    for i = 1, #char_ranges[font] do
        local range = char_ranges[font][i]
        if(char_code >= range[1] and char_code <= range[2])then
            return true
        end
    end
    return false
end

string_supported = function(font, str)
    for i=1, utf8.len(str) do
        local char = utf8.sub(str, i, i)
        if not char_supported(font, char) then
            return false
        end
    end
    return true
end

check_string = function(str)
    local font = get_current_font()
    return string_supported(font, str)
end