local py_utils = require('prototypes.functions.utils')
require('__stdlib__/stdlib/data/data').Util.create_data_globals()

local function set_underground_recipe(underground, belt, prev_underground, prev_belt)
    local dist = data.raw['underground-belt'][underground].max_distance + 1
    local prev_dist = 0

    if prev_underground then
        prev_dist = data.raw['underground-belt'][prev_underground].max_distance + 1
        local recipe_data = data.raw.recipe[belt].normal or data.raw.recipe[belt]
        local belt_count = py_utils.standardize_products(recipe_data.results, nil, recipe_data.result, recipe_data.result_count)[1].amount
        local fluid = false

        for _, ing in pairs(py_utils.standardize_products(recipe_data.ingredients)) do
            if ing.name ~= prev_belt then
                RECIPE(underground):remove_ingredient(ing.name)
                    :add_ingredient{ type = ing.type, name = ing.name, amount = ing.amount * prev_dist / belt_count}

                if ing.type == 'fluid' then fluid = true end
            end
        end

        if fluid and (RECIPE(underground).category or 'crafting')  == 'crafting' then
            RECIPE(underground):set_fields{ category = 'crafting-with-fluid' }
        end
    end

    RECIPE(underground):remove_ingredient(belt):add_ingredient{ type = 'item', name = belt, amount = dist - prev_dist}
end


-- Set underground belt recipes
set_underground_recipe('underground-belt', 'transport-belt', nil, nil)
set_underground_recipe('fast-underground-belt', 'fast-transport-belt', 'underground-belt', 'transport-belt')
set_underground_recipe('express-underground-belt', 'express-transport-belt', 'fast-underground-belt', 'fast-transport-belt')

local big_recipe_icons_blacklist = {
    ['rc-mk01'] = true,
    ['rc-mk02'] = true,
    ['rc-mk03'] = true,
    ['rc-mk04'] = true,
}

for _, prototype in pairs{'assembling-machine', 'furnace'} do
    for _, entity in pairs(data.raw[prototype]) do
        if not entity.name or big_recipe_icons_blacklist[entity.name] then goto continue end
        local box = entity.selection_box or entity.collision_box
        if not box or not box[1] or not box[2] then goto continue end
        local x, xx, y, yy = box[1][1], box[2][1], box[1][2], box[2][2]
        if not x or not xx or not y or not yy then goto continue end
        local area = (xx - x) * (yy - y)
        if area <= 9 then goto continue end
        entity.scale_entity_info_icon = true
        ::continue::
    end
end

if settings.startup['pypp-big-inventory-gui'].value then
    data.raw['utility-constants']['default'].select_slot_row_count = 17
    data.raw['utility-constants']['default'].select_group_row_count = 100
end

-- make sure very early techs are not effected by the tech cost multiplier
local function prevent_cost_multiplier(name)
    local tech = data.raw.technology[name]
    if not tech then return end
    tech.ignore_tech_cost_multiplier = true
end

prevent_cost_multiplier('wood-processing')
prevent_cost_multiplier('moss-mk01')
prevent_cost_multiplier('automation')
prevent_cost_multiplier('soil-washing')
prevent_cost_multiplier('botany-mk01')
prevent_cost_multiplier('glass')
prevent_cost_multiplier('mining-with-fluid')
prevent_cost_multiplier('steel-processing')
prevent_cost_multiplier('coal-processing-1')

-- Add open/close SFX to machines

for _, type in pairs{'assembling-machine', 'furnace', 'lab', 'rocket-silo', 'beacon', 'mining-drill'} do
    for _, entity in pairs(data.raw[type]) do
        if not entity.open_sound then entity.open_sound = { filename = '__base__/sound/machine-open.ogg', volume = 0.5 } end
        if not entity.close_sound then entity.close_sound = { filename = '__base__/sound/machine-close.ogg', volume = 0.5 } end
    end
end