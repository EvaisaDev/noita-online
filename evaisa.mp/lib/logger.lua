-- logger.lua
local default_folder_path = "logger"

local function create_logger(output_path, filename, overwrite)
    -- ensure/create the directory for the logger files
    --[[if not os.rename(output_path, output_path) then
        os.execute("mkdir \"" .. output_path .. "\" 2>nul")
    end]]

    local file_path = output_path .. "/" .. filename

    if overwrite == nil or overwrite then
        local clear_file = io.open(file_path, "w")
        clear_file:close()
    end

    local new_logger = {log_file = io.open(file_path, "a")}

    function new_logger.print(_, ...)
        if not new_logger.log_file then
            error("Attempt to print to a closed log file.")
            -- reopen file
            new_logger.log_file = io.open(file_path, "a")
            return
        end

        local debug_info = debug.getinfo(2, "Sl")

        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i])
        end
        local message = table.concat(args, ", ")

        -- Get the current timestamp
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")

        -- Include timestamp in the log message
        local log_message = string.format("%s [%s:%d]: %s\n", timestamp, debug_info.source, debug_info.currentline, message)

        new_logger.log_file:write(log_message)
        new_logger.log_file:flush()
    end

    function new_logger.close()
        if new_logger.log_file then
            new_logger.log_file:close()
            new_logger.log_file = nil
        end
    end

    return new_logger
end

local logger = {
    init = function(filename, overwrite)
        return create_logger(default_folder_path, filename, overwrite)
    end
}

-- Metatable for logger table
local logger_mt = {
    __call = function(_, folder_path)
        if folder_path then
            default_folder_path = folder_path
        end
        return logger
    end
}

setmetatable(logger, logger_mt)

return logger