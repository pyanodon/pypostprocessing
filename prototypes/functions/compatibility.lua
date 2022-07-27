-- Compatibility changes which need to modify data.raw should go here.
-- Compatibility changes affecting auto-tech config should go in the bottom of config.lua

local py_utils = require "prototypes.functions.utils"
local table = require "__stdlib__.stdlib.utils.table"

if data.raw.recipe["electronic-circuit"].enabled == false
    and (not data.raw.recipe["electronic-circuit-initial"] or data.raw.recipe["electronic-circuit-initial"].enabled == false)
    and data.raw.recipe["inductor1-2"]
    and (data.raw.recipe["inductor1-2"].enabled == nil or data.raw.recipe["inductor1-2"].enabled == true)
then
    for _, recipe in pairs(data.raw.recipe) do
        local recipe_data = (recipe.normal and type(recipe.normal) == "table" and recipe.normal) or recipe

        if recipe_data.enabled == nil or recipe_data.enabled == true then
            RECIPE(recipe):replace_ingredient("electronic-circuit", "inductor1")
        end
    end
end

if mods["pyrawores"] then
    for _, recipe in pairs(data.raw.recipe) do
        if recipe.enabled == nil or recipe.enabled == true then
            RECIPE(recipe):replace_ingredient("coal", "raw-coal")
        end
    end
end


if mods["DeadlockLargerLamp"] then
    -- Originally these include electronic-circuits and are unlocked at optics, causing a deadlock in pymods
    RECIPE("deadlock-large-lamp"):remove_ingredient("electronic-circuit"):add_ingredient({type = "item", name = "copper-plate", amount = 4}):add_ingredient({type = "item", name = "glass", amount = 6})
    RECIPE("deadlock-floor-lamp"):remove_ingredient("electronic-circuit"):add_ingredient({type = "item", name = "copper-plate", amount = 4}):add_ingredient({type = "item", name = "glass", amount = 6})
end

if mods["deadlock-beltboxes-loaders"] then
    for item_name, item in py_utils.iter_prototypes("item") do
        if data.raw.item["deadlock-stack-" .. item_name] ~= nil then
            data.raw.item["deadlock-stack-" .. item_name].ignore_for_dependencies = true
            data.raw.recipe["deadlock-stacks-stack-" .. item_name].ignore_for_dependencies = true
            data.raw.recipe["deadlock-stacks-unstack-" .. item_name].ignore_for_dependencies = true
            data.raw.recipe["deadlock-stacks-unstack-" .. item_name].unlock_results = false

            if ITEM(item):has_flag("hidden") then
                ITEM("deadlock-stack-" .. item_name):add_flag("hidden")
                data.raw.recipe["deadlock-stacks-stack-" .. item_name].hidden = true
                data.raw.recipe["deadlock-stacks-unstack-" .. item_name].hidden = true
            end
        end
    end
end

if mods["DeadlockCrating"] then
    for item_name, item in py_utils.iter_prototypes("item") do
        if data.raw.item["deadlock-crate-" .. item_name] ~= nil then
            data.raw.item["deadlock-crate-" .. item_name].ignore_for_dependencies = true
            data.raw.recipe["deadlock-packrecipe-" .. item_name].ignore_for_dependencies = true
            data.raw.recipe["deadlock-unpackrecipe-" .. item_name].ignore_for_dependencies = true
            data.raw.recipe["deadlock-unpackrecipe-" .. item_name].unlock_results = false

            if ITEM(item):has_flag("hidden") then
                ITEM("deadlock-crate-" .. item_name):add_flag("hidden")
                data.raw.recipe["deadlock-packrecipe-" .. item_name].hidden = true
                data.raw.recipe["deadlock-unpackrecipe-" .. item_name].hidden = true
            end
        end
    end
end

if mods["deadlock_stacked_recipes"] then
    for recipe_name, recipe in pairs(data.raw.recipe) do
        if data.raw.recipe["StackedRecipe-" .. recipe_name] ~= nil then
            data.raw.recipe["StackedRecipe-" .. recipe_name].ignore_for_dependencies = true

            if recipe.hidden then
                data.raw.recipe["StackedRecipe-" .. recipe_name].hidden = true
            end
        end
    end
end

if mods["LightedPolesPlus"] then
    RECIPE("lighted-small-electric-pole"):add_unlock("optics"):remove_unlock("creosote"):set_enabled(false)
end

if mods["reverse-factory"] then
    local cat = table.array_to_dictionary({"recycle-products", "recycle-intermediates", "recycle-with-fluids", "recycle-productivity"}, true)

    for item_name, item in py_utils.iter_prototypes("item") do
        local recipe_name = "rf-" .. item_name

        if data.raw.recipe[recipe_name] and cat[data.raw.recipe[recipe_name].category] then
            data.raw.recipe[recipe_name].ignore_for_dependencies = true
            data.raw.recipe[recipe_name].unlock_results = false

            if ITEM(item):has_flag("hidden") then
                data.raw.recipe[recipe_name].hidden = true
            end
        end
    end

    for fluid_name, fluid in pairs(data.raw.fluid) do
        local recipe_name = "rf-" .. fluid_name

        if data.raw.recipe[recipe_name] and cat[data.raw.recipe[recipe_name].category] then
            data.raw.recipe[recipe_name].ignore_for_dependencies = true
            data.raw.recipe[recipe_name].unlock_results = false

            if fluid.hidden then
                data.raw.recipe[recipe_name].hidden = true
            end
        end
    end
end

if mods["omnimatter_water"] and mods["pyindustry"] then
    RECIPE("py-sinkhole"):remove_unlock("steel-processing"):add_unlock("engine")
end

-- Trains move to py-science-1 under pyindustry, move common train mods to match
if mods["pyindustry"] then
    if mods["LogisticTrainNetwork"] then
        TECHNOLOGY("logistic-train-network"):remove_pack("logistic-science-pack")
    end

    if mods["railloader"] then
        TECHNOLOGY("railloader"):remove_pack("logistic-science-pack")
    end

    if mods["train-pubsub"] then
        TECHNOLOGY("train-manager"):remove_pack("logistic-science-pack")
    end

    if mods["ShuttleTrainRefresh"] then
        TECHNOLOGY("shuttle-train"):remove_pack("logistic-science-pack")
    end
end

if mods["Teleporters"] and mods["pyhightech"] then
    RECIPE("teleporter"):replace_ingredient("advanced-circuit", "electronic-circuit")
    -- Remove prereqs and let autotech figure it out
    TECHNOLOGY('teleporter'):remove_pack('chemical-science-pack'):remove_prereq('advanced-electronics')
    if mods["pyalienlife"] then
        TECHNOLOGY('teleporter'):remove_pack('py-science-pack-2')
    end
end

if mods["WaterWell"] then
    RECIPE("water-well-flow"):set_fields{ ignore_for_dependencies = true }

    if mods["pyhightech"] and data.raw.recipe["inductor1-2"] then
        RECIPE("water-well-pump"):replace_ingredient("electronic-circuit", "inductor1")
    end
end

if mods["Transport_Drones"] then
    data.raw.technology["transport-system"].prerequisites = nil
end

if mods["miniloader"] then
    TECHNOLOGY("miniloader"):add_pack("py-science-pack-1"):add_pack("logistic-science-pack")
    TECHNOLOGY("fast-miniloader"):add_pack("py-science-pack-2")
    RECIPE("chute-miniloader"):add_ingredient{"burner-inserter", 2}
end

if mods["Flare Stack"] then
    local cat = table.array_to_dictionary({"gas-venting", "flaring", "incineration", "fuel-incineration"}, true)

    for recipe_name, recipe in pairs(data.raw.recipe) do
        if cat[recipe.category] then
            data.raw.recipe[recipe_name].ignore_for_dependencies = true
        end
    end
end

if mods["bobinserters"] then
    TECHNOLOGY("more-inserters-1"):add_pack("py-science-pack-2")
end

if mods["robot-recall"] and mods["pyindustry"] then
    -- The robot distribution chest should be available when construction bots are researched
    RECIPE("robot-redistribute-chest"):remove_unlock("logistic-robotics"):remove_ingredient("advanced-circuit")
    -- The robot recall chest can wait until mk02 robots are researched
    RECIPE("robot-recall-chest"):remove_unlock("construction-robotics"):remove_unlock("logistic-robotics"):add_unlock("robotics")
end

if mods["botReplacer"] and mods["pyindustry"] then
    -- Don't need the bot replacer chest until better bots are unlocked
    RECIPE("logistic-chest-botUpgrader"):remove_unlock("construction-robotics"):add_unlock("robotics")
end
