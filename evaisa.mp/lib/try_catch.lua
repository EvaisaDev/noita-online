local functionType = "function"

--- 
-- @param tryBlock The block of code to execute as the try block.
--
-- @return A table that can be used to chain try/catch/finally blocks. (Call .catch or .finally of the return value)
--
local function try (tryBlock)
    local status, err = true, nil

    if type(tryBlock) == functionType then
        if(disable_error_catching)then
            -- run without pcall, and add result to status err thing
            status, err = true, tryBlock()
        end
        status, err = xpcall(tryBlock, debug.traceback)
    end

    local finally = function (finallyBlock, catchBlockDeclared)
        if type(finallyBlock) == functionType then
            finallyBlock()
        end
        
        if not catchBlockDeclared and not status then
            error(err)
        end
    end

    local catch = function (catchBlock)
        local catchBlockDeclared = type(catchBlock) == functionType;

        if not status and catchBlockDeclared then
            local ex = err or "unknown error occurred"
            catchBlock(ex)
        end

        return {
            finally = function(finallyBlock)
                finally(finallyBlock, catchBlockDeclared)
            end
        }
    end

    return
    {
        catch = catch,
        finally = function(finallyBlock)
            finally(finallyBlock, false)
        end
    }
end

return try