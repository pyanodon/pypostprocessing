-- Compatibility changes which need to modify data.raw should go here.
-- Compatibility changes affecting auto-tech config should go in the bottom of config.lua

local py_utils = require 'prototypes.functions.utils'
local table = require '__stdlib__.stdlib.utils.table'

if mods['pyrawores'] then
    for _, recipe in pairs(data.raw.recipe) do
        if recipe.enabled == nil or recipe.enabled == true then
            RECIPE(recipe):replace_ingredient('coal', 'raw-coal')
        end
    end
end


if mods['DeadlockLargerLamp'] then
    -- Originally these include electronic-circuits and are unlocked at optics, causing a deadlock in pymods
    RECIPE('deadlock-large-lamp'):remove_ingredient('electronic-circuit'):add_ingredient({ type = 'item', name = 'copper-plate', amount = 4 }):add_ingredient({ type = 'item', name = 'glass', amount = 6 })
    RECIPE('deadlock-floor-lamp'):remove_ingredient('electronic-circuit'):add_ingredient({ type = 'item', name = 'copper-plate', amount = 4 }):add_ingredient({ type = 'item', name = 'glass', amount = 6 })
end

if mods['deadlock-beltboxes-loaders'] then
    for item_name, item in py_utils.iter_prototypes('item') do
        local stack = data.raw.item['deadlock-stack-' .. item_name]
        if stack then
            stack.ignore_for_dependencies = true
            data.raw.recipe['deadlock-stacks-stack-' .. item_name].ignore_for_dependencies = true
            data.raw.recipe['deadlock-stacks-unstack-' .. item_name].ignore_for_dependencies = true
            data.raw.recipe['deadlock-stacks-unstack-' .. item_name].unlock_results = false

            if ITEM(item).burnt_result == 'ash' then
                if not data.raw.item['deadlock-stack-ash'] then error('\n\n\n\n\nPlease install Deadlock\'s Stacking for Pyanodon\n\n\n\n\n') end
                stack.burnt_result = 'deadlock-stack-ash'
            end

            if ITEM(item):has_flag('hidden') then
                ITEM('deadlock-stack-' .. item_name):add_flag('hidden')
                data.raw.recipe['deadlock-stacks-stack-' .. item_name].hidden = true
                data.raw.recipe['deadlock-stacks-unstack-' .. item_name].hidden = true
            end
        end
    end
end

if mods['DeadlockCrating'] then
    for item_name, item in py_utils.iter_prototypes('item') do
        if data.raw.item['deadlock-crate-' .. item_name] ~= nil then
            data.raw.item['deadlock-crate-' .. item_name].ignore_for_dependencies = true
            data.raw.recipe['deadlock-packrecipe-' .. item_name].ignore_for_dependencies = true
            data.raw.recipe['deadlock-unpackrecipe-' .. item_name].ignore_for_dependencies = true
            data.raw.recipe['deadlock-unpackrecipe-' .. item_name].unlock_results = false

            if ITEM(item):has_flag('hidden') then
                ITEM('deadlock-crate-' .. item_name):add_flag('hidden')
                data.raw.recipe['deadlock-packrecipe-' .. item_name].hidden = true
                data.raw.recipe['deadlock-unpackrecipe-' .. item_name].hidden = true
            end
        end
    end
end

if mods['deadlock_stacked_recipes'] then
    for recipe_name, recipe in pairs(data.raw.recipe) do
        if data.raw.recipe['StackedRecipe-' .. recipe_name] ~= nil then
            data.raw.recipe['StackedRecipe-' .. recipe_name].ignore_for_dependencies = true

            if recipe.hidden then
                data.raw.recipe['StackedRecipe-' .. recipe_name].hidden = true
            end
        end
    end
end

if mods['LightedPolesPlus'] then
    RECIPE('lighted-small-electric-pole'):add_unlock('optics'):remove_unlock('creosote'):set_enabled(false)
    if mods['pyalternativeenergy'] then
        RECIPE('lighted-medium-electric-pole'):remove_unlock('optics'):add_unlock('electric-energy-distribution-1')
        RECIPE('lighted-big-electric-pole'):remove_unlock('optics'):add_unlock('electric-energy-distribution-2')
        RECIPE('lighted-substation'):remove_unlock('optics'):add_unlock('electric-energy-distribution-4')
    end
end

if mods['reverse-factory'] then
    local cat = table.array_to_dictionary({ 'recycle-products', 'recycle-intermediates', 'recycle-with-fluids', 'recycle-productivity' }, true)

    for item_name, item in py_utils.iter_prototypes('item') do
        local recipe_name = 'rf-' .. item_name

        if data.raw.recipe[recipe_name] and cat[data.raw.recipe[recipe_name].category] then
            data.raw.recipe[recipe_name].ignore_for_dependencies = true
            data.raw.recipe[recipe_name].unlock_results = false

            if ITEM(item):has_flag('hidden') then
                data.raw.recipe[recipe_name].hidden = true
            end
        end
    end

    for fluid_name, fluid in pairs(data.raw.fluid) do
        local recipe_name = 'rf-' .. fluid_name

        if data.raw.recipe[recipe_name] and cat[data.raw.recipe[recipe_name].category] then
            data.raw.recipe[recipe_name].ignore_for_dependencies = true
            data.raw.recipe[recipe_name].unlock_results = false

            if fluid.hidden then
                data.raw.recipe[recipe_name].hidden = true
            end
        end
    end
end

if mods['omnimatter_water'] and mods['pyindustry'] then
    RECIPE('py-sinkhole'):remove_unlock('steel-processing'):add_unlock('engine')
end

-- Trains move to py-science-1 under pyindustry, move common train mods to match
if mods['pyindustry'] then
    if mods['LogisticTrainNetwork'] then
        TECHNOLOGY('logistic-train-network'):remove_pack('logistic-science-pack')
    end

    if mods['railloader'] then
        TECHNOLOGY('railloader'):remove_pack('logistic-science-pack')
    end

    if mods['train-pubsub'] then
        TECHNOLOGY('train-manager'):remove_pack('logistic-science-pack')
    end

    if mods['ShuttleTrainRefresh'] then
        TECHNOLOGY('shuttle-train'):remove_pack('logistic-science-pack')
    end
end

if mods['Portals'] and mods['pyhightech'] then
    -- Remove prereqs and let autotech figure it out
    TECHNOLOGY('portals'):remove_prereq('solar-panel-equipment')
    RECIPE('portal-gun'):replace_ingredient('advanced-circuit', 'electronic-circuit')
    RECIPE('portal-gun'):replace_ingredient('solar-panel-equipment', 'electronics-mk01')
end

if mods['Teleporters'] and mods['pyhightech'] then
    RECIPE('teleporter'):replace_ingredient('advanced-circuit', 'electronic-circuit')
    -- Remove prereqs and let autotech figure it out
    TECHNOLOGY('teleporter'):remove_pack('chemical-science-pack'):remove_prereq('advanced-electronics')
    if mods['pyalienlife'] then
        TECHNOLOGY('teleporter'):remove_pack('py-science-pack-2')
    end
end

if mods['WaterWell'] then
    RECIPE('water-well-flow'):set_fields { ignore_for_dependencies = true }

    if mods['pyhightech'] and data.raw.recipe['inductor1-2'] then
        RECIPE('water-well-pump'):replace_ingredient('electronic-circuit', 'inductor1')
    end
end

if mods['TinyStart'] then
    data.raw.recipe['tiny-armor-mk1'].ignore_for_dependencies = true
    data.raw.recipe['tiny-armor-mk2'].ignore_for_dependencies = true
end

if mods['Transport_Drones'] then
    data.raw.technology['transport-system'].prerequisites = nil
end

if mods['miniloader'] then
    TECHNOLOGY('miniloader'):add_pack('py-science-pack-1'):add_pack('logistic-science-pack')
    TECHNOLOGY('fast-miniloader'):add_pack('py-science-pack-2')
    RECIPE('chute-miniloader'):add_ingredient { 'burner-inserter', 2 }
end

if mods['Flare Stack'] then
    local cat = table.array_to_dictionary({ 'gas-venting', 'flaring', 'incineration', 'fuel-incineration' }, true)

    for recipe_name, recipe in pairs(data.raw.recipe) do
        if cat[recipe.category] then
            data.raw.recipe[recipe_name].ignore_for_dependencies = true
        end
    end
end

if mods['bobinserters'] then
    TECHNOLOGY('more-inserters-1'):add_pack('py-science-pack-2')
end

if mods['robot-recall'] and mods['pyindustry'] then
    -- The robot distribution chest should be available when construction bots are researched
    RECIPE('robot-redistribute-chest'):remove_unlock('logistic-robotics'):remove_ingredient('advanced-circuit')
    -- The robot recall chest can wait until mk02 robots are researched
    RECIPE('robot-recall-chest'):remove_unlock('construction-robotics'):remove_unlock('logistic-robotics'):add_unlock('robotics')
end

if mods['botReplacer'] and mods['pyindustry'] then
    -- Don't need the bot replacer chest until better bots are unlocked
    RECIPE('logistic-chest-botUpgrader'):remove_unlock('construction-robotics'):add_unlock('robotics')
end

if mods['yi_railway'] and mods['pyindustry'] then
    for recipe_name, recipe in pairs(data.raw.recipe) do
        --log('checking '..recipe_name..' , subgroup:' .. recipe.subgroup .. ' ('..string.sub(recipe.subgroup,1,4)..')')
        if recipe.subgroup and string.sub(recipe.subgroup, 1, 4) == 'yir_' then
            if recipe.subgroup == 'yir_locomotives_steam' then
                recipe.enabled = true
                recipe.category = data.raw.recipe['locomotive'].category
                recipe.group = data.raw.recipe['locomotive'].group
                recipe.energy_required = data.raw.recipe['locomotive'].energy_required
                recipe.ingredients = data.raw.recipe['locomotive'].ingredients -- I know what this does and I don't care

                RECIPE(recipe_name):add_unlock('railway-mk01')

                local resultname = recipe.results[1]['name']
                local loco = data.raw.locomotive['locomotive']
                if (loco and data.raw.locomotive[resultname]) then
                    data.raw.locomotive[resultname].weight = loco.weight
                    data.raw.locomotive[resultname].max_speed = loco.max_speed
                    data.raw.locomotive[resultname].max_power = loco.max_power
                    data.raw.locomotive[resultname].reversing_power_modifier = loco.reversing_power_modifier
                    data.raw.locomotive[resultname].braking_force = loco.braking_force
                    data.raw.locomotive[resultname].friction_force = loco.friction_force
                    data.raw.locomotive[resultname].air_resistance = loco.air_resistance
                    data.raw.locomotive[resultname].burner.fuel_category = loco.burner.fuel_category
                    data.raw.locomotive[resultname].burner.fuel_inventory_size = loco.burner.fuel_inventory_size
                    data.raw.locomotive[resultname].burner.burnt_inventory_size = loco.burner.burnt_inventory_size
                else
                    --log('can't find ' .. resultname)
                end

            elseif recipe.subgroup == 'yir_locomotives_diesel' or recipe.subgroup == 'yir_locomotives_nslong' then
                recipe.enabled = true
                recipe.category = data.raw.recipe['mk02-locomotive'].category
                recipe.group = data.raw.recipe['mk02-locomotive'].group
                recipe.energy_required = data.raw.recipe['mk02-locomotive'].energy_required
                recipe.ingredients = data.raw.recipe['mk02-locomotive'].ingredients

                RECIPE(recipe_name):add_unlock('railway-mk02')

                local resultname = recipe.results[1]['name']
                local loco = data.raw.locomotive['mk02-locomotive']

                data.raw.locomotive[resultname].weight = loco.weight
                data.raw.locomotive[resultname].max_speed = loco.max_speed
                data.raw.locomotive[resultname].max_power = loco.max_power
                data.raw.locomotive[resultname].reversing_power_modifier = loco.reversing_power_modifier
                data.raw.locomotive[resultname].braking_force = loco.braking_force
                data.raw.locomotive[resultname].friction_force = loco.friction_force
                data.raw.locomotive[resultname].air_resistance = loco.air_resistance
                data.raw.locomotive[resultname].burner.fuel_category = loco.burner.fuel_category
                data.raw.locomotive[resultname].burner.fuel_inventory_size = loco.burner.fuel_inventory_size
                data.raw.locomotive[resultname].burner.burnt_inventory_size = loco.burner.burnt_inventory_size

            elseif recipe.subgroup == 'yir_cargowagons' or recipe.subgroup == 'yir_cargowagons_4A' or
                recipe.subgroup == 'yir_cargowagons_2A2' then
                recipe.enabled = true
                recipe.category = data.raw.recipe['cargo-wagon'].category
                recipe.group = data.raw.recipe['cargo-wagon'].group
                recipe.energy_required = data.raw.recipe['cargo-wagon'].energy_required
                recipe.ingredients = data.raw.recipe['cargo-wagon'].ingredients

                RECIPE(recipe_name):add_unlock('railway-mk01')

                local resultname = recipe.results[1]['name']
                local wagon = data.raw['cargo-wagon']['cargo-wagon']
                local ywagon = data.raw['cargo-wagon'][resultname]

                ywagon.weight = wagon.weight
                ywagon.max_speed = wagon.max_speed
                ywagon.braking_force = wagon.braking_force
                ywagon.friction_force = wagon.friction_force
                ywagon.air_resistance = wagon.air_resistance
                ywagon.inventory_size = wagon.inventory_size


            elseif recipe.subgroup == 'yir_tankwagons2a' and recipe.subgroup == 'yir_fluidwagons_4A' then
                recipe.enabled = true
                recipe.category = data.raw.recipe['fluid-wagon'].category
                recipe.group = data.raw.recipe['fluid-wagon'].group
                recipe.energy_required = data.raw.recipe['fluid-wagon'].energy_required
                recipe.ingredients = data.raw.recipe['fluid-wagon'].ingredients

                RECIPE(recipe_name):add_unlock('railway-mk01')

                local resultname = recipe.results[1]['name']
                local wagon = data.raw['fluid-wagon']['fluid-wagon']
                local ywagon = data.raw['fluid-wagon'][resultname]

                ywagon.weight = wagon.weight
                ywagon.max_speed = wagon.max_speed
                ywagon.braking_force = wagon.braking_force
                ywagon.friction_force = wagon.friction_force
                ywagon.air_resistance = wagon.air_resistance
                ywagon.capacity = wagon.capacity

            else
                --log('disabling '..recipe_name..' as subgroup is '..recipe.subgroup)
                recipe.ignore_for_dependencies = true
                recipe.unlock_results = false
                recipe.hidden = true
                if (recipe.results) then
                    for i, v in ipairs(recipe.results[1]) do
                        --log('  disabling '..v.name)
                        v.hidden = true
                    end
                end
            end
        elseif string.sub(recipe_name, 1, 4) == 'yir_' and string.find(recipe_name, 'pyvoid') == nil then
            --log('disabling '..recipe_name)
            recipe.ignore_for_dependencies = true
            recipe.unlock_results = false
            recipe.hidden = true
            if (recipe.results) then
                for i, v in ipairs(recipe.results[1]) do
                    --log('  disabling '..v.name)
                    v.hidden = true
                end
            end
        end
    end
end

if mods['Rocket-Silo-Construction'] then
    RECIPE('rsc-construction-stage1'):set_enabled(false):add_unlock('rocket-silo')
    RECIPE('rsc-construction-stage2'):set_enabled(false):add_unlock('rocket-silo')
    RECIPE('rsc-construction-stage3'):set_enabled(false):add_unlock('rocket-silo')
    RECIPE('rsc-construction-stage4'):set_enabled(false):add_unlock('rocket-silo')
    RECIPE('rsc-construction-stage5'):set_enabled(false):add_unlock('rocket-silo')
    RECIPE('rsc-construction-stage6'):set_enabled(false):add_unlock('rocket-silo')

    if mods['pyindustry'] and mods['pycoalprocessing'] then
        RECIPE('rsc-excavation-site'):replace_ingredient('pipe', 'niobium-pipe')
        RECIPE('rsc-construction-stage4'):replace_ingredient('pipe', 'niobium-pipe'):replace_ingredient('pipe-to-ground', 'niobium-pipe-to-ground')
        RECIPE('rsc-construction-stage6'):replace_ingredient('radar', 'megadar')
    end

    if mods['pyrawores'] then
        RECIPE('rsc-construction-stage2'):replace_ingredient('steel-plate', 'stainless-steel')
        RECIPE('rsc-construction-stage4'):replace_ingredient('steel-plate', 'stainless-steel')
        RECIPE('rsc-construction-stage5'):replace_ingredient('steel-plate', 'stainless-steel'):replace_ingredient('copper-plate', 'nexelit-plate')
    end

    if mods['pypetroleumhandling'] then
        RECIPE('rsc-excavation-site'):replace_ingredient('processing-unit', 'advanced-circuit')
        RECIPE('rsc-construction-stage2'):add_ingredient{'small-parts-02', 20}
        RECIPE('rsc-construction-stage4'):add_ingredient{'small-parts-02', 10}
        RECIPE('rsc-construction-stage5'):add_ingredient{'small-parts-02', 10}
        RECIPE('rsc-construction-stage6'):remove_ingredient('processing-unit'):add_ingredient{'small-parts-02', 10}
    end

    if mods['pyalternativeenergy'] then
        RECIPE('rsc-construction-stage2'):add_ingredient{'self-assembly-monolayer', 5}
        RECIPE('rsc-construction-stage4'):add_ingredient{'self-assembly-monolayer', 5}
        RECIPE('rsc-construction-stage5'):add_ingredient{'self-assembly-monolayer', 5}
    end
end

if mods['scattergun_turret'] then
    for _, recipe in pairs(data.raw.recipe) do
        -- tried testing for subcategory, but it's nil at this point
        if recipe.name:find('^w93-') ~= nil and recipe.name:find('turret2$') ~= nil then
            recipe.ignore_for_dependencies = true
        end
    end
end

if mods['nixie-tubes'] then
    TECHNOLOGY('cathodes'):remove_pack('logistic-science-pack'):remove_prereq('advanced-electronics')
end

if mods['pushbutton'] then
    RECIPE('pushbutton'):remove_ingredient('advanced-circuit')
end

if mods['subspace_storage'] then
    for item_name, item_data in pairs(data.raw.item) do
        if item_data.subgroup == 'subspace_storage-interactor' then
            item_data.ignore_for_dependencies = true
            if data.raw.recipe[item_name] then
                data.raw.recipe[item_name].ignore_for_dependencies = true
            end
        end
    end
    -- 'get-n' is a pretty generic pattern to rely on, so we also make sure the results are empty.
    for fluid_name in pairs(data.raw.fluid) do
        local fluid_recipe = data.raw.recipe['get-' .. fluid_name]
        local fluid_result = fluid_recipe and fluid_recipe.results
        if fluid_result and fluid_result[1] and fluid_result[1].amount == 0 then
            fluid_recipe.ignore_for_dependencies = true
        end
    end
end

if mods['bobmodules'] then
    RECIPE('module-case'):add_unlock('basic-electronics')
    RECIPE('module-contact'):add_unlock('basic-electronics')
    RECIPE('module-circuit-board'):add_unlock('basic-electronics')
    RECIPE('module-processor-board'):add_unlock('basic-electronics')
    RECIPE('module-processor-board-2'):add_unlock('basic-electronics')
    RECIPE('module-processor-board-3'):add_unlock('basic-electronics')
    RECIPE('lab-module'):add_unlock('basic-electronics')
    RECIPE('speed-processor'):add_unlock('basic-electronics')
    RECIPE('effectivity-processor'):add_unlock('basic-electronics')
    RECIPE('productivity-processor'):add_unlock('basic-electronics')
    RECIPE('pollution-clean-processor'):add_unlock('basic-electronics')
    RECIPE('pollution-create-processor'):add_unlock('basic-electronics')
end

if data.raw.recipe['electronic-circuit'].enabled == false
    and (not data.raw.recipe['electronic-circuit-initial'] or data.raw.recipe['electronic-circuit-initial'].enabled == false)
    and data.raw.recipe['inductor1-2']
    and (data.raw.recipe['inductor1-2'].enabled == nil or data.raw.recipe['inductor1-2'].enabled == true)
then
    for _, recipe in pairs(data.raw.recipe) do
        local recipe_data = (recipe.normal and type(recipe.normal) == 'table' and recipe.normal) or recipe

        if (recipe_data.enabled == nil or recipe_data.enabled == true) and not recipe.ignore_for_dependencies then
            RECIPE(recipe):replace_ingredient('electronic-circuit', 'inductor1')
        end
    end
end