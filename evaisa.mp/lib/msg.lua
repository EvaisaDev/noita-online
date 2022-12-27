local msg = {}

msg.log = function (...)
	local arg = {...}
	local str = ""
	for i, v in ipairs(arg) do
		-- don't add comma to last argument
		if i ~= #arg then
			str = str .. tostring(v) .. ", "
		else
			str = str .. tostring(v)
		end
	end
	print("[evaisa.mp] "..str)
	GamePrint("[evaisa.mp] "..str)
end

return msg