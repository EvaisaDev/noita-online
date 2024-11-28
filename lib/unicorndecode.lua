local unicorndecode = {
    _VERSION = 'unicorndecode 1.0.1',
    _DESCRIPTION = 'Unidecode for Lua',
    _URL         = 'https://github.com/FourierTransformer/unicorndecode',
    _LICENSE     = [[
        The MIT License (MIT)
        Copyright (c) 2016-2019 Shakil Thakur
        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:
        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.
        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
    ]]
}

-- get the lua version (this is later used for compat)
local luaver = tonumber(_VERSION:sub(5))

-- load up the unicode magic python/perl tables!
local unicodeMagics = require('unidecode_data')

-- create a fallback mechanism... (just returns '[?]')
local backupTable = setmetatable({}, {__index = function() return '[?]' end})
setmetatable(unicodeMagics, {__index = function() return backupTable end})

-- luajit has a bit module builtin and returns luaver 5.1
-- for lua 5.1, luabitop would need to be installed
local bor, blshift, brshift
if luaver == 5.1 then
    bit = require("bit")
    bor, blshift, brshift = bit.bor, bit.lshift, bit.rshift
elseif luaver == 5.2 then
    bor, blshift, brshift = bit32.bor, bit32.lshift, bit32.rshift    
end

-- load up utf8.codes. In lua 5.3+ this is baked in, otherwise the lua function provides
-- similar functionality
local utf8codes
if luaver > 5.2 then
    utf8codes = utf8.codes
else
    -- declare the function!
    utf8codes = function(inputString)

        -- determines how many additional bytes are needed to parse the unicode char
        -- NOTE: assumes the UTF-8 input is clean - which may get dangerous.
        local function additionalBytes(val)
            -- these don't really exist yet...
            -- and are definitely not in the data tables...
            -- if val >= 252 then
            --     return 5, 252
            -- elseif val >= 248 then
            --     return 4, 248
            -- elseif val >= 240 then
            if val >= 240 then
                return 3, 240    
            elseif val >= 224 then
                return 2, 224
            elseif val >= 192 then
                return 1, 192
            else
                return 0, 0
            end
        end

        -- PERF!
        local sbyte = string.byte
        local i, startI = 1, 1
        local val

        return function()
            -- the beginning is returned...
            startI = i

            -- get the byte value of the current char
            val = sbyte(inputString, i)
            if not val then return nil end

            -- figure out how many additional bytes are needed
            extraBytes, byteVal = additionalBytes(val)

            -- if there are additional bytes this is UTF-8!
            -- remove the preceding 1's in binary
            val = val - byteVal
            -- print("val", val)

            -- add each additional byte to get the unicode value
            --[[ ex: for the two byte unicode value (in binary):
                110xxxxx 10yyyyyy
                has the unicdoe value: xxxxxyyyyyy
            ]]
            for j = 1, extraBytes do
                extraByteVal = sbyte(inputString, i+j)
                -- print("extraByteVal", extraByteVal)
                extraByteVal = extraByteVal - 128 --remove the header byte
                val = bor(blshift(val, 6), extraByteVal) --combines it
            end


            i = i + 1 + extraBytes

            return startI, val
        end
    end
end

local function trim(s)
  return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
end

function unicorndecode.decode(inputString)
    -- SO MANY VARS!
    local val, extraBytes, byteVal, extraByteVal
    local inputLength = #inputString
    -- print("inputLength", inputLength)

    -- STRING BUILDER!
    local output = {}
    local count = 0

    -- iterate over the string
    for p, c in utf8codes(inputString) do
        -- print(p, c)
        -- add the equivalent ascii char to the output
        count = count + 1
        output[count] = unicodeMagics[math.floor(c/256)][(c % 256)+1]
    end

    -- concat the string together!
    local final = table.concat(output)
    return trim(final), inputLength ~= (count) -- this is more of a byte count than anything
end

return unicorndecode
