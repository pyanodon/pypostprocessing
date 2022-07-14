-- Compatibility changes which need to modify data.raw should go here.
-- Compatibility changes affecting auto-tech config should go in the bottom of config.lua

if mods["DeadlockLargerLamp"] then
    -- Originally these include electronic-circuits and are unlocked at optics, causing a deadlock in pymods
    RECIPE("deadlock-large-lamp"):remove_ingredient("electronic-circuit"):add_ingredient({type = "item", name = "copper-plate", amount = 4}):add_ingredient({type = "item", name = "glass", amount = 6})
    RECIPE("deadlock-floor-lamp"):remove_ingredient("electronic-circuit"):add_ingredient({type = "item", name = "copper-plate", amount = 4}):add_ingredient({type = "item", name = "glass", amount = 6})
end

if mods["deadlock-beltboxes-loaders"] then
    for item_type, _ in pairs(defines.prototypes["item"]) do
        for item_name, item in pairs(data.raw[item_type]) do
            if data.raw.item["deadlock-stack-" .. item_name] ~= nil then
                data.raw.item["deadlock-stack-" .. item_name].ignore_for_dependencies = true
                data.raw.recipe["deadlock-stacks-stack-" .. item_name].ignore_for_dependencies = true
                data.raw.recipe["deadlock-stacks-unstack-" .. item_name].ignore_for_dependencies = true

                if ITEM(item):has_flag("hidden") then
                    ITEM("deadlock-stack-" .. item_name):add_flag("hidden")
                    data.raw.recipe["deadlock-stacks-stack-" .. item_name].hidden = true
                    data.raw.recipe["deadlock-stacks-unstack-" .. item_name].hidden = true
                end
            end
        end
    end
end

if mods["DeadlockCrating"] then
    for item_type, _ in pairs(defines.prototypes["item"]) do
        for item_name, item in pairs(data.raw[item_type]) do
            if data.raw.item["deadlock-crate-" .. item_name] ~= nil then
                data.raw.item["deadlock-crate-" .. item_name].ignore_for_dependencies = true
                data.raw.recipe["deadlock-packrecipe-" .. item_name].ignore_for_dependencies = true
                data.raw.recipe["deadlock-unpackrecipe-" .. item_name].ignore_for_dependencies = true

                if ITEM(item):has_flag("hidden") then
                    ITEM("deadlock-crate-" .. item_name):add_flag("hidden")
                    data.raw.recipe["deadlock-packrecipe-" .. item_name].hidden = true
                    data.raw.recipe["deadlock-unpackrecipe-" .. item_name].hidden = true
                end
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
