-- Adds helper functions for data stage. Shared across all pymods

require "metas.metas"
require "autorecipes"
require "pipe-connections"

---Returns a 1x1 empty image.
---@return table
py.empty_image = function()
    return {
        filename = "__pypostprocessing__/empty.png",
        size = 1,
        priority = "high",
        line_length = 1
    }
end

---Adds a localised string to the prototype's description.
---@param type string
---@param prototype data.AnyPrototype
---@param localised_string LocalisedString
py.add_to_description = function(type, prototype, localised_string)
    if prototype.localised_description and prototype.localised_description ~= "" then
        prototype.localised_description = {"", prototype.localised_description, "\n", localised_string}
        return
    end

    local place_result = prototype.place_result or prototype.place_as_equipment_result
    if type == "item" and place_result then
        for _, machine in pairs(data.raw) do
            machine = machine[place_result]
            if machine and machine.localised_description then
                prototype.localised_description = {
                    "?",
                    {"", machine.localised_description, "\n", localised_string},
                    localised_string
                }
                return
            end
        end

        local entity_type = prototype.place_result and "entity" or "equipment"
        prototype.localised_description = {
            "?",
            {"", {entity_type .. "-description." .. place_result}, "\n", localised_string},
            {"", {type .. "-description." .. prototype.name},      "\n", localised_string},
            localised_string
        }
    else
        prototype.localised_description = {
            "?",
            {"", {type .. "-description." .. prototype.name}, "\n", localised_string},
            localised_string
        }
    end
end

---adds a glow layer to any item prototype.
---@param prototype data.ItemPrototype
py.make_item_glowing = function(prototype)
    if not prototype then
        error("No prototype provided")
    end
    if prototype.pictures then
        for _, picture in pairs(prototype.pictures) do
            picture.draw_as_glow = true
        end
        return
    end
    if prototype.icon and not prototype.icons then
        prototype.icons = {{icon = prototype.icon, icon_size = prototype.icon_size}}
        prototype.icon = nil
    end
    if not prototype.icons then
        error("No icon found for " .. prototype.name)
    end
    local pictures = {}
    for _, picture in pairs(table.deepcopy(prototype.icons)) do
        picture.draw_as_glow = true
        local icon_size = picture.icon_size or prototype.icon_size
        picture.filename = picture.icon
        picture.shift = {0, 0}
        picture.width = icon_size
        picture.height = icon_size
        picture.scale = 16 / icon_size
        picture.icon = nil
        picture.icon_size = nil
        pictures[#pictures + 1] = picture
    end
    prototype.pictures = pictures
end

---Creates a new prototype by cloning 'old' and overwriting it with properties from 'new'. Provide 'nil' as a string in order to delete items inside 'old'
---@param old data.AnyPrototype
---@param new table
---@return data.AnyPrototype
py.merge = function(old, new)
    old = table.deepcopy(old)
    for k, v in pairs(new) do
        if v == "nil" then
            old[k] = nil
        else
            old[k] = v
        end
    end
    return old
end

---The purpose of the farm_speed functions is to remove the farm building itself
---from the building speed. For example, for xyhiphoe mk1 which has only one animal
---per farm, we want the speed to be equal to 1 xyhiphoe not 2 (farm + module)
---Returns the correct farm speed for a mk1 farm based on number of modules and desired speed using mk1 modules
---@param num_slots integer
---@param desired_speed number
---@return number
function py.farm_speed(num_slots, desired_speed)
    -- mk1 modules are 100% bonus speed. The farm itself then counts as much as one module
    return desired_speed / (num_slots + 1)
end

---Returns the correct farm speed for a mk2+ farm based on the number of modules and the mk1 speed
---@param num_slots integer
---@param base_entity_name string
---@return number
function py.farm_speed_derived(num_slots, base_entity_name)
    local e = data.raw["assembling-machine"][base_entity_name]
    local mk1_slots = e.module_slots
    local desired_mk1_speed = e.crafting_speed * (mk1_slots + 1)
    local speed_improvement_ratio = num_slots / mk1_slots
    return (desired_mk1_speed * speed_improvement_ratio) / (num_slots + 1 / speed_improvement_ratio)
end

---Takes two prototype names (both must use the style of IconSpecification with icon = string_path), returns an IconSpecification with the icons as composites
---@param base_prototype string
---@param child_prototype string
---@param shadow_alpha number?
function py.composite_molten_icon(base_prototype, child_prototype, shadow_alpha)
    shadow_alpha = shadow_alpha or 0.6
    base_prototype = data.raw.fluid[base_prototype] or data.raw.item[base_prototype]
    child_prototype = data.raw.fluid[child_prototype] or data.raw.item[child_prototype]
    return {
        {
            icon = base_prototype.icon,
            icon_size = base_prototype.icon_size
        },
        {
            icon = child_prototype.icon,
            icon_size = child_prototype.icon_size,
            shift = {10, 10},
            scale = 0.65,
            tint = {r = 0, g = 0, b = 0, a = shadow_alpha}
        },
        {
            icon = child_prototype.icon,
            icon_size = child_prototype.icon_size,
            shift = {10, 10},
            scale = 0.5,
            tint = {r = 1, g = 1, b = 1, a = 1}
        },
    }
end

---Standardizes a product or ingredient prototype to a common format.
---@param p data.IngredientPrototype | data.ProductPrototype | string
---@return data.IngredientPrototype | data.ProductPrototype
py.standardize_product = function(p)
    if type(p) == "string" then p = {p, 1} end
    local name = p.name or p[1]
    if not p.type and name then
        if data.raw.fluid[name] then
            p.type = "fluid"
        else
            p.type = "item"
        end
    end

    p.name = name
    if not (p.amount_min and p.amount_max) then p.amount = p.amount or p[2] or 1 end
    p[1] = nil
    p[2] = nil

    return p
end


---Returns an iterator through all data.raw categories of a given supertype.
---@param parent_type string
---@return function<string, table>
function py.iter_prototype_categories(parent_type)
    local types = defines.prototypes[parent_type]
    local child_type_name, value

    return function()
        if not types then
            return nil, nil
        end
        repeat
            -- Move to our next type
            value, child_type_name, _ = nil, next(types, child_type_name)
            -- Returns the next item in our current table, if valid
            if child_type_name and data.raw[child_type_name] then
                value = data.raw[child_type_name]
            end
            -- cur_type will be nil here if we've reached the last prototype in the last table
        until value or not child_type_name

        return child_type_name, value
    end
end

---Returns an iterator through all prototypes of a given supertype.
---@param parent_type string
---@return function
function py.iter_prototypes(parent_type)
    local types = defines.prototypes[parent_type]
    local cur_type, index, value

    return function()
        repeat
            -- Returns the next item in our current table, if valid
            if cur_type and data.raw[cur_type] then
                index, value = next(data.raw[cur_type], index)
            end

            -- We reached the end of the last table
            if not cur_type or not index then
                index, value, cur_type, _ = nil, nil, next(types, cur_type)
            end
            -- cur_type will be nil here if we've reached the last prototype in the last table
        until index or not cur_type

        return index, value
    end
end

---replace an item/fluid in every recipes ingredients/results
---best used to merge items that are duplicated in mods that should be the same
---@param old string
---@param new string
---@param blackrecipe (string | table)?
py.global_item_replacer = function(old, new, blackrecipe)
    if not data.raw.item[old] and not data.raw.fluid[old] then error("Could not find item or fluid " .. old) end
    if not data.raw.item[new] and not data.raw.fluid[new] then error("Could not find item or fluid " .. new) end

    if type(blackrecipe) == "string" then blackrecipe = {blackrecipe} end
    blackrecipe = table.invert(blackrecipe or {})

    for _, recipe in pairs(data.raw.recipe) do
        if not recipe.ignored_by_recipe_replacement and not blackrecipe[recipe.name] then
            recipe:replace_ingredient(old, new)
            recipe:replace_result(old, new)
        end
    end
end

---adds a small icon to the top right corner of a recipe
---@param recipe data.RecipePrototype
---@param corner table
py.add_corner_icon_to_recipe = function(recipe, corner)
    local icon, icon_size, icons
    local result
    if recipe.main_product then
        result = ITEM(recipe.main_product)
    elseif recipe.results and table_size(recipe.results) >= 1 then
        result = recipe.results[1]
        if result.type == "fluid" then
            result = FLUID(result.name)
        else
            result = ITEM(result.name)
        end
    end

    -- Icon size finder
    if recipe.icon_size ~= nil then
        icon_size = recipe.icon_size
    else
        icon_size = 64 -- Set default to 64
    end

    -- Icon finder
    if recipe.icon ~= nil then -- Found an icon
        icon = recipe.icon
    end

    if icon == nil and result and result.icon then -- (i.e. not found above)
        -- Find it from result icon
        icon = table.deepcopy(result.icon)

        -- Confirm icon_size
        if result.icon_size then icon_size = result.icon_size end
    end

    if recipe.icons then -- If it's already an icons
        icons = recipe.icons
        icons[#icons + 1] = corner
    elseif result and result.icons then
        icons = table.deepcopy(result.icons)
        icons[#icons + 1] = corner
    else -- No icons table, use icon found above
        if icon == nil then
            error("No icons found for recipe " .. serpent.block(result) .. serpent.block(recipe))
        end

        icons = {
            {icon = icon, icon_size = icon_size},
            corner
        }
    end

    -- Ensure icon sizes are installed in each icon level
    for i, icon in pairs(icons) do
        if not icon.icon_size then
            if i == 1 then -- Allow first one to inherit, set all others to 64
                icon.icon_size = icon_size or 64
            else
                icon.icon_size = 64
            end
        end
    end

    return icons
end

---Retruns a version of graphics_set with the following properties:
---The machine will follow a binary finite state machine (bfsm) to determine the current active animation.
---Example (sinter machine): https://github.com/pyanodon/pybugreports/issues/588
---@param states data.VisualState[]
---@param raw_working_visualisations data.WorkingVisualisation[]
---@param shadow data.Animation?
py.finite_state_machine_working_visualisations = function(params)
    local states = params.states

    local state_count = table_size(states)
    if state_count < 2 or state_count > 32 then
        error("Finite state machine must have between 2 and 32 states")
    end

    if states[1].name ~= "idle" then
        error("First state must be 'idle'")
    end

    if table_size(states[1].frame_sequence) ~= 1 then
        error("First state must have only one frame")
    end

    local working_visualisations = {}
    local graphics_set = {states = params.states, working_visualisations = working_visualisations, animation = params.shadow}

    local function fit_frame_sequence_to_frame_count(layer)
        local frame_count = layer.frame_count * (layer.repeat_count or 1)
        local new_frame_sequence = {}
        for _, frame in pairs(layer.frame_sequence) do
            new_frame_sequence[#new_frame_sequence + 1] = frame % layer.frame_count + 1
        end
        layer.frame_sequence = new_frame_sequence
        layer.repeat_count = nil
        layer.animation_speed = nil
        if layer.run_mode == "backward" then
            layer.run_mode = nil
            local frame_sequence_backwards = {}
            for _, frame in pairs(new_frame_sequence) do
                frame_sequence_backwards[#frame_sequence_backwards + 1] = frame_count - frame + 1
            end
            layer.frame_sequence = frame_sequence_backwards
        end
    end

    for _, visualization in pairs(params.working_visualisations) do
        for _, state in pairs(states) do
            local visualization = table.deepcopy(visualization)
            if visualization.animation.layers then
                for _, layer in pairs(visualization.animation.layers) do
                    layer.frame_sequence = table.deepcopy(state.frame_sequence)
                    fit_frame_sequence_to_frame_count(layer)
                end
            else
                visualization.animation.frame_sequence = table.deepcopy(state.frame_sequence)
                fit_frame_sequence_to_frame_count(visualization.animation)
            end
            visualization.draw_in_states = {state.name}
            visualization.draw_when_state_filter_matches = true
            visualization.always_draw = true
            working_visualisations[#working_visualisations + 1] = visualization
        end
    end

    for _, state in pairs(states) do
        state.duration = math.ceil(table_size(state.frame_sequence) * 2 / (state.speed or 1))
        state.speed = nil
        state.frame_sequence = nil
    end

    states[1].duration = 1
    
    return graphics_set
end

---@diagnostic disable-next-line: duplicate-set-field
py.on_event = function() end
