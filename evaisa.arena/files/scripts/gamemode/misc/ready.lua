entity = GetUpdatedEntityID()
readyComp = EntityGetFirstComponentIncludingDisabled(entity, "InteractableComponent", "ready")


if(GameHasFlagRun("ready_check"))then
    ComponentSetValue2(readyComp, "ui_text", "Press $0 to unready")
else
    ComponentSetValue2(readyComp, "ui_text", "Press $0 to ready up")
end

function interacting( entity_who_interacted, entity_interacted, interactable_name )
    readyComp = EntityGetFirstComponentIncludingDisabled(entity, "InteractableComponent", "ready")
    
    if(GameHasFlagRun("ready_check"))then
        GameAddFlagRun("player_unready")
        GameRemoveFlagRun("ready_check")
        GameRemoveFlagRun("player_ready")
        ComponentSetValue2(readyComp, "ui_text", "Press $0 to ready up")
    else
        GameAddFlagRun("player_ready")
        GameAddFlagRun("ready_check")
        GameRemoveFlagRun("player_unready")
        ComponentSetValue2(readyComp, "ui_text", "Press $0 to unready")
    end
end