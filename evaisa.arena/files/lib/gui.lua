local sprite_index = 1;
last_sprite_index = 0;
sprite_cache = sprite_cache or {}
--if container_entity == nil then container_entity = EntityLoad( "data/gokilib/container.xml" ); end
local render_queue = {};
function draw_sprite( filepath, x, y, offset_x, offset_y, scale_x, scale_y, rotation, alpha, emissive, z_index, animation )
    if offset_x == nil then offset_x = 0; end
    if offset_y == nil then offset_y = 0; end
    if scale_x == nil then scale_x = 1.0; end
    if scale_y == nil then scale_y = 1.0; end
    if rotation == nil then rotation = 0; end
    if alpha == nil then alpha = 1.0; end
    if z_index == nil then z_index = 0; end
    if emissive == nil then emissive = true; end
    if animation == nil then animation = "default"; end

    local render_entry = {
        filepath = filepath,
        x = x,
        y = y,
        offset_x = offset_x,
        offset_y = offset_y,
        scale_x = scale_x,
        scale_y = scale_y,
        rotation = rotation,
        alpha = alpha,
        emissive = emissive,
        z_index = z_index,
        rect_animation = animation,
        render_index = sprite_index,
        visible = true,
    };
    table.insert( render_queue, render_entry );
    sprite_index = sprite_index + 1;
    
    return render_entry;
end

function draw_text( font, text, x, y, scale_x, scale_y, alpha, emissive, z_index, horizontal_alignment, vertical_alignment )
    if scale_x == nil then scale_x = 2/3; end
    if scale_y == nil then scale_y = 2/3; end
    if alpha == nil then alpha = 1; end
    if emissive == nil then emissive = true; end
    if horizontal_alignment == nil then horizontal_alignment = 0; end
    if vertical_alignment == nil then vertical_alignment = 0; end
    local cx = x;
    local cy = y;
    local sprites = {};
    for i = 1, #text do
        local c = text:sub(i,i):upper();
        local spacing_before = 0;
        local spacing_after = font.character_spacing;
        local spacing = font.character_specific_spacing[c];
        if spacing ~= nil then
            spacing_before = spacing[1];
            spacing_after = spacing[2];
        end
        cx = cx + (spacing_before) * scale_x;
        local s = draw_sprite( font.sprite_filepath, cx, cy, 0, 0, scale_x, scale_y, 0, alpha, emissive, z_index, c );
        table.insert( sprites, s );
        cx = cx + (font.character_width + spacing_after) * scale_x;
    end
    if horizontal_alignment ~= 0 or vertical_alignment ~= 0 then   
        local line_width = ( cx - x );
        local line_height = font.character_height * scale_y;
        for _,sprite in pairs( sprites or {} ) do
            sprite.x = sprite.x - line_width * horizontal_alignment;
            sprite.y = sprite.y - line_height * vertical_alignment;
        end
    end
end

function render( x, y, skip_sorting )
    local now = GameGetFrameNum();
    
    while #sprite_cache < sprite_index do
        local sprite_entity = EntityCreateNew();
        EntityAddComponent2( sprite_entity, "InheritTransformComponent", { only_position = true } );
        local sprite = EntityAddComponent2( sprite_entity, "SpriteComponent", {
            image_file = "mods/spell_lab/files/gui/empty.png",
            has_special_scale = true,
        } );
        EntityAddTag( sprite_entity, "hide_on_pause" );
        --EntityAddChild( container_entity, sprite_entity );
        table.insert( sprite_cache, { entity = sprite_entity, sprite = sprite, data_cache = {}, last_used_frame = now } );
    end

    if skip_sorting ~= true then
        table.sort( render_queue, function( a, b )
            if a.z_index ~= b.z_index then
                return a.z_index > b.z_index;
            elseif a.filepath ~= b.filepath then
                return a.filepath < b.filepath;
            elseif a.render_index ~= b.render_index then
                return a.render_index > b.render_index;
            else--if a.animation ~= b.animation then
                return a.rect_animation < b.rect_animation;
            end
        end );
    end

    --[[ Unrolled ~1.9 ms
    ]]
    for i,render_entry in ipairs( render_queue ) do
        local sprite_data =         sprite_cache[ i ];
        local sprite_entity =       sprite_data.entity;
        local sprite =              sprite_data.sprite;
        local data_cache =          sprite_data.data_cache;

        local z_index =             render_entry.z_index;
        local offset_x =            (render_entry.offset_x * render_entry.scale_x - render_entry.x + x) / render_entry.scale_x;
        local offset_y =            (render_entry.offset_y * render_entry.scale_y - render_entry.y + y) / render_entry.scale_y;
        local special_scale_x =     render_entry.scale_x;
        local special_scale_y =     render_entry.scale_y;
        local emissive =            render_entry.emissive;
        local alpha =               render_entry.alpha;
        local rect_animation =      render_entry.rect_animation;
        local visible =             render_entry.visible;

        if data_cache.z_index ~=            z_index then ComponentSetValue2( sprite, "z_index", z_index ); data_cache.z_index = z_index; end
        if data_cache.offset_x ~=           offset_x then ComponentSetValue2( sprite, "offset_x", offset_x ); data_cache.offset_x = offset_x; end
        if data_cache.offset_y ~=           offset_y then ComponentSetValue2( sprite, "offset_y", offset_y ); data_cache.offset_y = offset_y; end
        if data_cache.special_scale_x ~=    special_scale_x then ComponentSetValue2( sprite, "special_scale_x", special_scale_x ); data_cache.special_scale_x = special_scale_x; end
        if data_cache.special_scale_y ~=    special_scale_y then ComponentSetValue2( sprite, "special_scale_y", special_scale_y ); data_cache.special_scale_y = special_scale_y; end
        if data_cache.emissive ~=           emissive then ComponentSetValue2( sprite, "emissive", emissive ); data_cache.emissive = emissive; end
        if data_cache.alpha ~=              alpha then ComponentSetValue2( sprite, "alpha", alpha ); data_cache.alpha = alpha; end
        if data_cache.rect_animation ~=     rect_animation then ComponentSetValue2( sprite, "rect_animation", rect_animation ); data_cache.rect_animation = rect_animation; end
        if data_cache.visible ~=            visible then ComponentSetValue2( sprite, "visible", visible ); data_cache.visible = visible; end

        if data_cache.current_image_file ~= render_entry.filepath then
            data_cache.current_image_file = render_entry.filepath;
            ComponentSetValue2( sprite, "image_file", render_entry.filepath );
            EntityRefreshSprite( sprite_entity, sprite );
        end
        sprite_data.last_used_frame = now;
        --print( render_entry.z_index .. " -> "..sprite_entity .. " @ "..render_entry.filepath .." / "..render_entry.animation );
    end

    render_queue = {};
    hide_unused_sprites()
end

function move_container( x, y )
    EntitySetTransform( container_entity, x, y );
end

function hide_unused_sprites()
    local now = GameGetFrameNum();
    for i,sprite_data in pairs(sprite_cache) do
        if now - sprite_data.last_used_frame > 60 then
            EntityKill( sprite_data.entity );
            table.remove( sprite_cache, i );
        end
    end
    for i=sprite_index,last_sprite_index do
        if sprite_cache[i] and EntityGetIsAlive( sprite_cache[i].entity ) then
            ComponentSetValue2( sprite_cache[i].sprite, "visible", false );
            sprite_cache[i].data_cache.visible = false;
        end
    end
    last_sprite_index = sprite_index;
    sprite_index = 1;
end

-- UI

local UI_ELEMENT_TYPES = {
    Button = 1,
    Text = 2,
}
local drag_x, drag_y = 0;
local drag_distance = 0;
local mouse_down = false;

local ui_elements = {};
local ui_element_index = 0;
function ui_button( x, y, width, height, render_callback, click_callback )
    ui_elements[ui_element_index] = {
        type = UI_ELEMENT_TYPES.Button,
        x = x,
        y = y,
        width = width,
        height = height,
        render_callback = render_callback,
        click_callback = click_callback
    };
    ui_element_index = ui_element_index + 1;
end

function block_held_wand_firing()
    local now = GameGetFrameNum();
    for _,entity in pairs( EntityGetWithTag( "player_unit" ) or {} ) do
        local held_wand = get_entity_held_or_random_wand( entity, false );
        if held_wand ~= 0 then
            local ability = EntityGetFirstComponentIncludingDisabled( held_wand, "AbilityComponent" );
            if ability then
                ComponentSetValue2( ability, "mReloadFramesLeft", 2 );
                ComponentSetValue2( ability, "mNextFrameUsable", now + 2 );
                ComponentSetValue2( ability, "mReloadNextFrameUsable", now + 2 );
            end
        end
    end
end

function handle_input( x, y )
    local now = GameGetFrameNum();
    local mouse_x, mouse_y = DEBUG_GetMouseWorld();
    local left_click = false;
    local right_click = false;
    local entity = EntityGetWithTag( "player_unit" )[1];
    local controls = EntityGetFirstComponent( entity, "ControlsComponent" );
    if controls ~= nil then
        local use_button_frame = ComponentGetValue2( controls, "mButtonFrameFire" );
        if now == use_button_frame then
            left_click = true;
        end
        use_button_frame = ComponentGetValue2( controls, "mButtonFrameThrow" );
        if now == use_button_frame then
            right_click = true;
        end
    end
    local clicked_anything = false;
    local hovered_anything = false;
    for _,ui_element in pairs( ui_elements ) do
        local ux = x + ui_element.x;
        local uy = y + ui_element.y;

        if ui_element.type == UI_ELEMENT_TYPES.Button then
            local hover = false;
            if mouse_x >= ux and mouse_x <= ux + ui_element.width then
                if mouse_y >= uy and mouse_y <= uy + ui_element.height then
                    hover = true;
                    if ui_element.click_callback then
                        hovered_anything = true;
                    end
                end
            end
            ui_element.render_callback( ux, uy, hover );
            if ui_element.click_callback and hover and ( left_click or right_click ) then
                ui_element.click_callback( left_click, right_click );
                clicked_anything = true;
            end
        end
    end
    if hovered_anything then
        block_held_wand_firing();
    end
    ui_elements = {};
end