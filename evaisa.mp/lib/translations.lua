function register_localizations(translation_file, clear_count)

	clear_count = clear_count or 0

    local loc_content = ModTextFileGetContent("data/translations/common.csv") -- Gets the original translations of the game

    local append_content = ModTextFileGetContent(translation_file) -- Gets my own translations file

    -- Split the append_content into lines
    local lines = {}
    for line in append_content:gmatch("[^\n]+") do
        table.insert(lines, line)
    end

    -- Remove the first clear_count lines
    for i = 1, clear_count do
        table.remove(lines, 1)
    end

    -- Reconstruct append_content after removing clear_count lines
    local new_append_content = table.concat(lines, "\n")

    -- Concatenate loc_content and new_append_content
    local new_content = loc_content .. "\n" .. new_append_content

    -- Set the new content to the file
    ModTextFileSetContent("data/translations/common.csv", new_content)
end