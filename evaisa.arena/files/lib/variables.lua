function EntityClearVariable( entity, variable_tag, value )
    local variable = EntityGetFirstComponent( entity, "VariableStorageComponent", variable_tag );
    if variable ~= nil then
        EntityRemoveComponent( entity, variable );
    end
end

function EntityGetVariableString( entity, variable_tag, default )
    local variable = EntityGetFirstComponent( entity, "VariableStorageComponent", variable_tag );
    if variable ~= nil then
        return ComponentGetValue2( variable, "value_string" );
    end
    return default;
end

function EntitySetVariableString( entity, variable_tag, value )
    local current_variable = EntityGetFirstComponent( entity, "VariableStorageComponent", variable_tag );
    if current_variable == nil then
        EntityAddComponent( entity, "VariableStorageComponent", {
            _tags=variable_tag..",enabled_in_world,enabled_in_hand,enabled_in_inventory",
            value_string=tostring(value)
        } );
    else
        ComponentSetValue2( current_variable, "value_string", value );
    end
end

function EntityHasNamedVariable( entity, name )
    for k,component in pairs( EntityGetComponent( entity, "VariableStorageComponent" ) or {} ) do
        if ComponentGetValue2( component, "name") == name then
            return true;
        end
    end
    return false;
end

function EntityGetVariableNumber( entity, variable_tag, default )
    return tonumber( EntityGetVariableString( entity, variable_tag, default ) );
end

function EntitySetVariableNumber( entity, variable_tag, value )
    return EntitySetVariableString( entity, variable_tag, value );
end

function EntityAdjustVariableNumber( entity, variable_tag, default, callback )
    local new_value = callback( EntityGetVariableNumber( entity, variable_tag, default ) );
    EntitySetVariableNumber( entity, variable_tag, tostring( new_value ) );
    return new_value;
end

function ComponentAdjustValue( component, member, callback )
    local new_value = callback( ComponentGetValue2( component, member ) );
    ComponentSetValue2( component, member, new_value );
    return new_value;
end

function ComponentSetValues( component, member_value_table )
    for member,new_value in pairs(member_value_table) do
        ComponentSetValue2( component, member, new_value );
    end
end

function ComponentAdjustValues( component, member_callback_table )
    for member,callback in pairs( member_callback_table ) do
        ComponentSetValue2( component, member, callback( ComponentGetValue2( component, member ) ) );
    end
end

function ComponentObjectSetValues( component, object, member_value_table )
    for member,new_value in pairs(member_value_table) do
        ComponentObjectSetValue2( component, object, member, new_value );
    end
end

function ComponentObjectAdjustValues( component, object, member_callback_table )
    for member,callback in pairs(member_callback_table) do
        ComponentObjectSetValue2( component, object, member, callback( ComponentObjectGetValue2( component, object, member ) ) );
    end
end

function ComponentSetValues( component, member_value_table )
    for member,new_value in pairs(member_value_table) do
        ComponentSetValue2( component, member, new_value );
    end
end

function ComponentAdjustMetaCustoms( component, member_callback_table )
    for member,callback in pairs(member_callback_table) do
        local current_value = ComponentGetValue2( component, member );
        local new_value = callback( current_value );
        ComponentSetValue2( component, member, new_value );
    end
end