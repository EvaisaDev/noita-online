-- Create an empty table to store data
local data_store = {}
-- Set the folder path where data will be stored
local data_folder_name = os.getenv('APPDATA'):gsub("\\Roaming", "").."\\LocalLow\\Nolla_Games_Noita\\save00\\evaisa.mp_data"

-- create folder if doesn't exist
if not os.rename(data_folder_name, data_folder_name) then
    os.execute("mkdir \"" .. data_folder_name .. "\"")
end

-- Function to set the value for the given key
function data_store.Set(key, value)
    -- Create the file path by joining the folder path and key
    local file_path = data_folder_name .. "\\" .. key
    -- Open or create the file for writing
    local file = io.open(file_path, "w")
    -- Check if the file is successfully opened
    if file then
       -- print("Writing to file: " .. file_path)
        -- Write the value to the file
        file:write(value)
        -- Close the file
        file:close()
    else
        -- Print an error message if the file cannot be opened
        print("Error: Could not open the file for writing.")
    end
end

-- Function to get the value for the given key
function data_store.Get(key)
    -- Create the file path by joining the folder path and key
    local file_path = data_folder_name .. "\\" .. key
    -- Open the file for reading
    local file, err = io.open(file_path, "r")
    -- Check if the file is successfully opened
    if file then
        -- Read the content of the file
        local content = file:read("*all")
        -- Close the file
        file:close()
        -- Return the content of the file
        return content
    else
        -- Print an error message if the file cannot be opened
        print("Error: Could not open the file ["..file_path.."] for reading.")
        print(tostring(err))
        -- Return nil to indicate an error
        return nil
    end
end

-- Function to remove the value for the given key
function data_store.Remove(key)
    -- Create the file path by joining the folder path and key
    local file_path = data_folder_name .. "\\" .. key
    -- Remove the file
    os.remove(file_path)
end

-- Return the data_store table to make its functions accessible
return data_store