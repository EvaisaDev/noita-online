dofile("data/scripts/lib/utilities.lua")
--ffi = require("ffi")
--
--ffi.cdef([[
--typedef struct Entity Entity;
--
--typedef Entity* __thiscall EntityGet_f(int EntityManager, int entity_nr);
--typedef void __fastcall SetActiveHeldEntity_f(Entity* entity, Entity* item_entity, bool unknown, bool make_noise);
--]])
--
--local EntityManager = ffi.cast("int*", 0x00ff55dc)[0]
----
--local EntityGet_cfunc = ffi.cast("EntityGet_f*", 0x00527660)
--local SetActiveHeldEntity_cfunc = ffi.cast("SetActiveHeldEntity_f*", 0x009ec390)

local parallax_images = {
	
}


--function EntityGet(entity_nr)
--    return EntityGet_cfunc(EntityManager, entity_nr)
--end
local ffi = require("ffi")

game_funcs = {
	GetUnixTimestamp = function()
		return steam.utils.getUnixTimeStamp()
	end,
	GetUnixTimeElapsed = function(time1, time2)
		return steam.utils.getUnixTimeElapsed(time1, time2)
	end,
	UintToString = function(uint)
		return steam.utils.uintToString(uint)
	end,
	StringToUint = function(str)
		return steam.utils.stringToUint(str)
	end,
	--[[LoadRegion = function(start_x, start_y, width, height)
		local region = ffi.new("world_region", {start_x, start_y, width, height})
		--GamePrint("Loading region: "..tostring(start_x)..","..tostring(start_y)..","..tostring(width)..","..tostring(height))
		LoadRegion_cfunc(region)
	end,]]
	SetPlayerEntity = function(entity_id)
		--[[local entity = EntityGet(entity_id)
		local vector = ffi.cast("void****", 0x00ff5604)[0][22]
		vector[0] = entity]]
		np.SetPlayerEntity(entity_id)
	end,
	ExposeImage = function(filename, width, height)
		local id, w, h = ModImageMakeEditable( filename, width or 0, height or 0 )
		return {
			id = id,
			width = w,
			height = h
		}
	end,
	ReplaceImage = function (file1, file2)
		local id, w, h = ModImageIdFromFilename( file1 )
		if id == 0 then
			return false
		end
		local id2, w2, h2 = ModImageIdFromFilename( file2, w, h )
		if id2 == 0 then
			return false
		end

		for i = 0, w - 1 do
			for j = 0, h - 1 do
				local color = ModImageGetPixel( id2, i, j )
				ModImageSetPixel( id, i, j, color )
			end
		end
	end,
	RefreshParallax = function(target, new)


		-- refresh the parallax background
		local load_outdoors = ffi.cast("void (__fastcall*)(void*)", 0x0087c970)
		local ptr = ffi.cast("void**", ffi.cast("char**", 0x0120925c)[0] + 0x4c)[0]
		load_outdoors(ptr)
	end,
	SetActiveHeldEntity = function(entity_id, item_id, unknown, make_noise)
		--SetActiveHeldEntity_cfunc(EntityGet(entity_id), EntityGet(item_id), unknown, make_noise)
		np.SetActiveHeldEntity(entity_id, item_id, unknown, make_noise)
	end,
	ID2Color = function(str)
		str = tostring(str)
		-- get the bytes of each character counted together
		local sum = 0
		for i = 1, str:len() do
			sum = sum + str:byte(i)
		end
		-- seed random number generator with it
		local random = rng.new(sum)
		-- return a random color

		--print("sum: "..tostring(sum))

		if (sum == 897) then
			return { r = 235, g = 174, b = 186 }
		end

		return { r = random.range(130, 255), g = random.range(130, 255), b = random.range(130, 255) }
	end,
	RenderOffScreenMarkers = function(players)
		marker_gui = marker_gui or GuiCreate()
		GuiStartFrame(marker_gui)

		GuiOptionsAdd(marker_gui, GUI_OPTION.NonInteractive)
		local id = 2041242
		local function new_id()
			id = id + 1
			return id
		end

		local screen_width, screen_height = GuiGetScreenDimensions(marker_gui)
		local screen_center_x, screen_center_y = screen_width / 2, screen_height / 2
		local camera_x, camera_y = GameGetCameraPos()
		local bounds_x, bounds_y, bounds_w, bounds_h = GameGetCameraBounds()
		-- loop through each player
		for id, player in pairs(players) do
			if (player and EntityGetIsAlive(player)) then
				local x, y = EntityGetTransform(player)
				-- direction from camera to player
				local dx, dy = x - camera_x, y - camera_y


				-- check if player is outside camera bounds
				if (x < bounds_x or y < bounds_y or x > bounds_x + bounds_w or y > bounds_y + bounds_h) then
					-- normalize that shit
					local length = math.sqrt(dx * dx + dy * dy)
					dx, dy = dx / length, dy / length

					-- draw a marker on the edge of the screen in the direction of the player
					-- march from screen center in direction until we are off screen
					local marker_x, marker_y = screen_center_x, screen_center_y
					while (marker_x > 0 and marker_x < screen_width and marker_y > 0 and marker_y < screen_height) do
						marker_x = marker_x + dx
						marker_y = marker_y + dy
					end


					-- subtract 10 so that we are away from the edge a bit
					marker_x = marker_x - 10 * dx
					marker_y = marker_y - 10 * dy


					local markers = {
						up = "mods/evaisa.mp/files/gfx/ui/marker/top.png",
						down = "mods/evaisa.mp/files/gfx/ui/marker/bottom.png",
						left = "mods/evaisa.mp/files/gfx/ui/marker/left.png",
						right = "mods/evaisa.mp/files/gfx/ui/marker/right.png",
						topleft = "mods/evaisa.mp/files/gfx/ui/marker/topleft.png",
						topright = "mods/evaisa.mp/files/gfx/ui/marker/topright.png",
						bottomleft = "mods/evaisa.mp/files/gfx/ui/marker/bottomleft.png",
						bottomright = "mods/evaisa.mp/files/gfx/ui/marker/bottomright.png",
					}

					-- figure out which marker to draw based on the direction

					local marker_image = markers.up
					if (marker_x < screen_center_x - (screen_center_x / 2) and marker_y < screen_center_y - (screen_center_y / 2)) then
						marker_image = markers.topleft
					elseif (marker_x > screen_center_x + (screen_center_x / 2) and marker_y < screen_center_y - (screen_center_y / 2)) then
						marker_image = markers.topright
					elseif (marker_x < screen_center_x - (screen_center_x / 2) and marker_y > screen_center_y + (screen_center_y / 2)) then
						marker_image = markers.bottomleft
					elseif (marker_x > screen_center_x + (screen_center_x / 2) and marker_y > screen_center_y + (screen_center_y / 2)) then
						marker_image = markers.bottomright
					elseif (marker_x < screen_center_x - (screen_center_x / 2)) then
						marker_image = markers.left
					elseif (marker_x > screen_center_x + (screen_center_x / 2)) then
						marker_image = markers.right
					elseif (marker_y < screen_center_y - (screen_center_y / 2)) then
						marker_image = markers.up
					elseif (marker_y > screen_center_y + (screen_center_y / 2)) then
						marker_image = markers.down
					end



					--marker_x, marker_y = marker_x / 2, marker_y / 2

					marker_x = marker_x - 2.5
					marker_y = marker_y - 2.5

					-- somehow convert id to a color


					local color = game_funcs.ID2Color(id)
					if (color == nil) then
						color = { r = 255, g = 255, b = 255 }
					end
					local r, g, b = color.r, color.g, color.b
					local a = 1
					GuiColorSetForNextWidget(marker_gui, r / 255, g / 255, b / 255, a)

					GuiImage(marker_gui, new_id(), marker_x, marker_y, marker_image, 1, 1, 1)
					--GuiText(gui, marker_x / 2, marker_y / 2, "o")
				end
			end
		end
	end,
	RenderAboveHeadMarkers = function(players, offset_x, offset_y)
		marker_gui2 = marker_gui2 or GuiCreate()
		GuiStartFrame(marker_gui2)
		GuiOptionsAdd(marker_gui2, GUI_OPTION.NonInteractive)

		local id = 2041242
		local function new_id()
			id = id + 1
			return id
		end

		-- loop through each player
		for id, player in pairs(players) do
			if (player and EntityGetIsAlive(player)) then
				local x, y = EntityGetTransform(player)
				local screen_x, screen_y = WorldToScreenPos(marker_gui2, x, y)

				-- draw a marker above their head
				-- "mods/evaisa.mp/files/gfx/ui/marker/bottom.png"
				local marker_image = "mods/evaisa.mp/files/gfx/ui/marker/bottom.png"
				local marker_x = screen_x - 2.5 - offset_x
				local marker_y = screen_y - offset_y

				-- somehow convert id to a color
				local color = game_funcs.ID2Color(id)

				if (color == nil) then
					color = { r = 255, g = 255, b = 255 }
				end

				local r, g, b = color.r, color.g, color.b
				local a = 1

				GuiColorSetForNextWidget(marker_gui2, r / 255, g / 255, b / 255, a)
				GuiImage(marker_gui2, new_id(), marker_x, marker_y, marker_image, 1, 1, 1)
			end
		end
	end,
}

return game_funcs
