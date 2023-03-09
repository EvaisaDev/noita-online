function interacting( entity_who_interacted, entity_interacted, interactable_name )
    local readyComp = EntityGetFirstComponentIncludingDisabled(entity_interacted, "InteractableComponent", "ready")
    
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