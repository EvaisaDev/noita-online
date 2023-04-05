dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/gun/procedural/gun_action_utils.lua")

local entity_id = GetUpdatedEntityID()

local x,y = EntityGetTransform( entity_id )
local radius = 64

local targets = EntityGetInRadiusWithTag( x, y, radius, "mortal" )
-- iterate targets backwards and remove self
for i=#targets,1,-1 do
    if targets[i] == entity_id then
        table.remove( targets, i )
    end
end

local comp = EntityGetFirstComponent( entity_id, "LuaComponent", "fungal_disease" )

if ( #targets > 0 ) and ( comp == nil ) then
	EntitySetComponentsWithTagEnabled( entity_id, "fungal_disease", true )
elseif ( #targets == 0 ) and ( comp ~= nil ) then
	EntitySetComponentsWithTagEnabled( entity_id, "fungal_disease", false )
end