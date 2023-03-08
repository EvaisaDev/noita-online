local Vector = dofile_once("mods/evaisa.arena/lib/vector.lua")

local player = GetUpdatedEntityID()
local x, y = EntityGetTransform(player)
local playerPos = Vector.new(x, y)

local camX, camY = GameGetCameraPos()
local cameraPos = Vector.new(camX, camY)

local cameraSpeed = 0.1

local newCameraPos = cameraPos:lerp(playerPos, cameraSpeed)

--GamePrint("Camera: " .. cameraPos.x .. ", " .. cameraPos.y)
GameSetCameraPos(newCameraPos.x, newCameraPos.y)