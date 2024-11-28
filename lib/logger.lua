-- logger.lua
local default_folder_path = "logger"

local function create_logger(output_path, filename, overwrite, no_prefix, allow_repeats)
    -- ensure/create the directory for the logger files
    if not os.rename(output_path, output_path) then
        os.execute("mkdir \"" .. output_path .. "\" 2>nul")
    end

    local file_path = nil

    local new_logger = {
        log_file = nil,
        last_print = nil,
        last_was_duplicate = false,
        enabled = true
    }

    function new_logger.print(_, ...)
        if not new_logger.enabled then
            return
        end

        if(new_logger.last_print == nil)then
            file_path = output_path .. "/" .. filename

            if overwrite == nil or overwrite then
                local clear_file = io.open(file_path, "w")
                clear_file:close()
            end
        end

        if(not file_path)then
            error("Logger not initialized.")
            return
        end

        if not new_logger.log_file then
            -- reopen file
            new_logger.log_file = io.open(file_path, "a")
            return
        end

        local debug_info = debug.getinfo(2, "Sl")

        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i])
        end
        local message = args[1]
        if(#args > 1)then
            for i = 2, #args do
                message = message .. " " .. args[i]
            end
        end


        -- Include timestamp in the log message
        local log_message = ""

        local log_without_prefix = ""

        if(no_prefix)then
            log_message = string.format("%s\n", message)
            log_without_prefix = log_message
        else
            -- Get the current timestamp
            local timestamp = os.date("%Y-%m-%d %H:%M:%S")

            log_without_prefix = string.format("%s\n", message)
            
            log_message = string.format("%s [%s:%d]: %s\n", timestamp, debug_info.source, debug_info.currentline, message)
        end

        -- if the message is the same as the last one, don't print it again
        if(not allow_repeats)then
            if new_logger.last_print == log_without_prefix then
                if(not new_logger.last_was_duplicate)then
                    new_logger.log_file:write("\n[Multiple repeating prints detected, hiding..]\n")
                    new_logger.log_file:flush()
                end
                new_logger.last_was_duplicate = true
            else
                new_logger.last_was_duplicate = false
            end
        else
            print("Allowing repeats")
            new_logger.last_was_duplicate = false
        end

        new_logger.last_print = log_without_prefix

        if(not new_logger.last_was_duplicate or allow_repeats)then
            new_logger.log_file:write(log_message)
            new_logger.log_file:flush()
        end
    end

    function new_logger.enabled(_, enabled)
        new_logger.enabled = enabled
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
    init = function(filename, overwrite, no_prefix, folder_overwrite, allow_repeats)
        return create_logger(folder_overwrite or default_folder_path, filename, overwrite, no_prefix, allow_repeats)
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