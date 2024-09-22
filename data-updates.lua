require 'prototypes.next-upgrades'

local function set_underground_recipe(underground, belt, prev_underground, prev_belt)
    local dist = data.raw['underground-belt'][underground].max_distance + 1
    local prev_dist = 0

    if prev_underground then
        prev_dist = data.raw['underground-belt'][prev_underground].max_distance + 1
        local recipe = data.raw.recipe[belt]:standardize()
        local belt_count = recipe.ingredients[1].amount
        local fluid = false

        for _, ing in pairs(recipe.ingredients) do
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
        local scale = math.floor(math.sqrt(area) / 3 + 0.5)
        entity.alert_icon_scale = scale
        entity.icon_draw_specification = {
            scale = scale
        }
        ::continue::
    end
end

if settings.startup['pypp-big-inventory-gui'].value then
    data.raw['utility-constants']['default'].select_slot_row_count = 17
    data.raw['utility-constants']['default'].select_group_row_count = 100
end

if settings.startup['pypp-compactified-recipe-tooltips'].value then
    for _, type in pairs{'assembling-machine', 'furnace', 'rocket-silo'} do
        for _, entity in pairs(data.raw[type]) do
            if
                entity.name and
                (entity.name:find('%-[23456789]$') or entity.name:find('%-[mM][kK]0[23456789]$'))
                and not entity.name:find('-powerplant-', 1, true)
                and not entity.name:find('quantum-computer', 1, true)
            then
                entity.flags = entity.flags or {}
                table.insert(entity.flags, 'not-in-made-in')
            end
        end
    end
end

if data.raw['character']['ulric-man'] then
    table.insert(data.raw['character']['ulric-man'].flags, 'not-in-made-in')
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