function interacting( entity_who_interacted, entity_interacted, interactable_name )
    local readyComp = EntityGetFirstComponentIncludingDisabled(entity_interacted, "InteractableComponent", "ready")
    
    if(GameHasFlagRun("player_ready"))then
        GameAddFlagRun("player_unready")
        GameRemoveFlagRun("player_ready")
        ComponentSetValue2(readyComp, "ui_text", "Press $0 to ready up")
    else
        GameAddFlagRun("player_ready")
        GameRemoveFlagRun("player_unready")
        ComponentSetValue2(readyComp, "ui_text", "Press $0 to unready")
    end
end