local player = GetUpdatedEntityID()

local x, y = EntityGetTransform(player)

local controls_component = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")

local aiming_vector_x, aiming_vector_y = ComponentGetValue2(controls_component, "mAimingVector")
local aiming_vector_normalized_x, aiming_vector_normalized_y = ComponentGetValue2(controls_component, "mAimingVectorNormalized")
local aiming_vector_non_zero_latest_x, aiming_vector_non_zero_latest_y = ComponentGetValue2(controls_component, "mAimingVectorNonZeroLatest")

