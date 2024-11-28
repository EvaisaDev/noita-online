--- base64.lua
--
-- A simple Base64 encoder/decoder that uses a URL safe variant of the standard.
-- This implementation encodes character 62 as '-' (instead of '+') and character 63 as '_' (instead of '/').
-- In addition, padding is not used.
-- A full description of the specification can be found here: http://tools.ietf.org/html/rfc4648
--
-- To encode, use base64.encode(input), where input is a string of arbitrary bytes.  The output is a Base64 encoded string.
-- To decode, use base64.decode(input), where input is a Base64 encoded string.  The output is a string of arbitrary bytes.
--
-- For all input, input == base64.decode(base64.encode(input)).
--
-- This library has a dependency on LuaBit v0.4, which can be found here: http://luaforge.net/projects/bit/
--
-- Copyright (C) 2012 by Paul Moore
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

require "bit"

base64 = {}

--- octet -> char encoding.
local ENCODABET = {
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
	'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
	'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd',
	'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
	'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x',
	'y', 'z'
	
}

--- char -> octet encoding.
-- Offset by 44 (from index 1).
local DECODABET = {
	62,  0,  0, 52, 53, 54, 55, 56, 57, 58,
	59, 60, 61,  0,  0,  0,  0,  0,  0,  0,
	 0,  1,  2,  3,  4,  5,  6,  7,  8,  9,
	10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
	20, 21, 22, 23, 24, 25,  0,  0,  0,  0,
	63,  0, 26, 27, 28, 29, 30, 31, 32, 33,
	34, 35, 36, 37, 38, 39
}

--- Encodes a string into a Base64 string.
-- The input can be any string of arbitrary bytes.
--
-- @param input The input string.
-- @return The Base64 representation of the input string.
function base64.encode (input)
	
	local bytes = { input:byte(i, #input) }

	local out = {}
	
	-- Go through each triplet of 3 bytes, which produce 4 octets.
	local i = 1
	while i <= #bytes - 2 do
		local buffer = 0
		
		-- Fill the buffer with the bytes, producing a 24-bit integer.
		local b = bit.lshift(bytes[i], 16)
		b = bit.band(b, 0xff0000)
		buffer = bit.bor(buffer, b)
		
		b = bit.lshift(bytes[i + 1], 8)
		b = bit.band(b, 0xff00)
		buffer = bit.bor(buffer, b)
		
		b = bit.band(bytes[i + 2], 0xff)
		buffer = bit.bor(buffer, b)
		
		-- Read out the 4 octets into the output buffer.
		b = bit.arshift(buffer, 18)
		b = bit.band(b, 0x3f)
		out[#out + 1] = ENCODABET[b + 1]
		
		b = bit.arshift(buffer, 12)
		b = bit.band(b, 0x3f)
		out[#out + 1] = ENCODABET[b + 1]
		
		b = bit.arshift(buffer, 6)
		b = bit.band(b, 0x3f)
		out[#out + 1] = ENCODABET[b + 1]
		
		b = bit.band(buffer, 0x3f)
		out[#out + 1] = ENCODABET[b + 1]
				
		i = i + 3
	end
	
	-- Special case 1: One byte extra, will produce 2 octets.
	if #bytes % 3 == 1 then
		local buffer = bit.lshift(bytes[i], 16)
		buffer = bit.band(buffer, 0xff0000)
		
		local b = bit.arshift(buffer, 18)
		b = bit.band(b, 0x3f)
		out[#out + 1] = ENCODABET[b + 1]
		
		b = bit.arshift(buffer, 12)
		b = bit.band(b, 0x3f)
		out[#out + 1] = ENCODABET[b + 1]
		
	-- Special case 2: Two bytes extra, will produce 3 octets.
	elseif #bytes % 3 == 2 then
		local buffer = 0
		
		local b = bit.lshift(bytes[i], 16)
		b = bit.band(b, 0xff0000)
		buffer = bit.bor(buffer, b)
		
		b = bit.lshift(bytes[i + 1], 8)
		b = bit.band(b, 0xff00)
		buffer = bit.bor(buffer, b)

		b = bit.arshift(buffer, 18)
		b = bit.band(b, 0x3f)
		out[#out + 1] = ENCODABET[b + 1]
		
		b = bit.arshift(buffer, 12)
		b = bit.band(b, 0x3f)
		out[#out + 1] = ENCODABET[b + 1]
		
		b = bit.arshift(buffer, 6)
		b = bit.band(b, 0x3f)
		out[#out + 1] = ENCODABET[b + 1]
	end
	
	return table.concat(out)
	
end

--- Decodes a Base64 string into an output string of arbitrary bytes.
-- Currently does not check the input for valid Base64, so be careful.
--
-- @param input The Base64 input to decode.
-- @return The decoded Base64 string, as a string of bytes.
function base64.decode (input)
	
	local out = {}
	
	-- Go through each group of 4 octets to obtain 3 bytes.
	local i = 1
	while i <= #input - 3 do
		local buffer = 0
		
		-- Read the 4 octets into the buffer, producing a 24-bit integer.
		local b = input:byte(i)
		b = DECODABET[b - 44]
		b = bit.lshift(b, 18)
		buffer = bit.bor(buffer, b)
		i = i + 1
		
		b = input:byte(i)
		b = DECODABET[b - 44]
		b = bit.lshift(b, 12)
		buffer = bit.bor(buffer, b)
		i = i + 1
		
		b = input:byte(i)
		b = DECODABET[b - 44]
		b = bit.lshift(b, 6)
		buffer = bit.bor(buffer, b)
		i = i + 1
		
		b = input:byte(i)
		b = DECODABET[b - 44]
		buffer = bit.bor(buffer, b)
		i = i + 1
		
		-- Append the 3 re-constructed bytes into the output buffer.
		b = bit.arshift(buffer, 16)
		b = bit.band(b, 0xff)
		out[#out + 1] = b
		
		b = bit.arshift(buffer, 8)
		b = bit.band(b, 0xff)
		out[#out + 1] = b
		
		b = bit.band(buffer, 0xff)
		out[#out + 1] = b
	end

	-- Special case 1: Only 2 octets remain, producing 1 byte.
	if #input % 4 == 2 then
		local buffer = 0

		local b = input:byte(i)
		b = DECODABET[b - 44]
		b = bit.lshift(b, 18)
		buffer = bit.bor(buffer, b)
		i = i + 1
		
		b = input:byte(i)
		b = DECODABET[b - 44]
		b = bit.lshift(b, 12)
		buffer = bit.bor(buffer, b)
		i = i + 1
		
		b = bit.arshift(buffer, 16)
		b = bit.band(b, 0xff)
		out[#out + 1] = b
		
	-- Special case 2: Only 3 octets remain, producing 2 bytes.
	elseif #input % 4 == 3 then
		local buffer = 0
		
		local b = input:byte(i)
		b = DECODABET[b - 44]
		b = bit.lshift(b, 18)
		buffer = bit.bor(buffer, b)
		i = i + 1
		
		b = input:byte(i)
		b = DECODABET[b - 44]
		b = bit.lshift(b, 12)
		buffer = bit.bor(buffer, b)
		i = i + 1
		
		b = input:byte(i)
		b = DECODABET[b - 44]
		b = bit.lshift(b, 6)
		buffer = bit.bor(buffer, b)
		i = i + 1

		b = bit.arshift(buffer, 16)
		b = bit.band(b, 0xff)
		out[#out + 1] = b
		
		b = bit.arshift(buffer, 8)
		b = bit.band(b, 0xff)
		out[#out + 1] = b
	end

	return string.char(unpack(out))
	
end

return base64