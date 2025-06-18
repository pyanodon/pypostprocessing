if mods["DeadlockLargerLamp"] then
    -- Originally these include electronic-circuits and are unlocked at optics, causing a deadlock in pymods
    RECIPE("deadlock-large-lamp"):remove_ingredient("electronic-circuit"):add_ingredient {type = "item", name = "copper-plate", amount = 4}:add_ingredient {type = "item", name = "glass", amount = 6}
    RECIPE("deadlock-floor-lamp"):remove_ingredient("electronic-circuit"):add_ingredient {type = "item", name = "copper-plate", amount = 4}:add_ingredient {type = "item", name = "glass", amount = 6}

    data.raw["assembling-machine"]["deadlock-copper-lamp"].energy_source.fuel_categories = {"chemical","biomass","nuke"}

end

if mods["deadlock-beltboxes-loaders"] then
    for item_name, item in py.iter_prototypes("item") do
        local stack = data.raw.item["deadlock-stack-" .. item_name]
        if stack then
            stack.ignore_for_dependencies = true
            data.raw.recipe["deadlock-stacks-stack-" .. item_name].ignore_for_dependencies = true
            data.raw.recipe["deadlock-stacks-unstack-" .. item_name].ignore_for_dependencies = true
            data.raw.recipe["deadlock-stacks-unstack-" .. item_name].unlock_results = false

            if ITEM(item).burnt_result == "ash" then
                if not data.raw.item["deadlock-stack-ash"] then error("\n\n\n\n\nPlease install Deadlock\'s Stacking for Pyanodon\n\n\n\n\n") end
                stack.burnt_result = "deadlock-stack-ash"
            end

            if ITEM(item).hidden then
                ITEM("deadlock-stack-" .. item_name).hidden = true
                data.raw.recipe["deadlock-stacks-stack-" .. item_name].hidden = true
                data.raw.recipe["deadlock-stacks-unstack-" .. item_name].hidden = true
            end
        end
    end

    if data.raw.recipe["deadlock-stacks-stack-ralesia"] then
        RECIPE("deadlock-stacks-stack-ralesia"):remove_unlock("deadlock-stacking-1")
        RECIPE("deadlock-stacks-unstack-ralesia"):remove_unlock("deadlock-stacking-1")
        data.raw.recipe["deadlock-stacks-stack-ralesia"] = nil
        data.raw.recipe["deadlock-stacks-unstack-ralesia"] = nil
    end
    if data.raw.recipe["deadlock-stacks-stack-py-fertilizer"] then
        RECIPE("deadlock-stacks-stack-py-fertilizer"):remove_unlock("deadlock-stacking-2")
        RECIPE("deadlock-stacks-unstack-py-fertilizer"):remove_unlock("deadlock-stacking-2")
        data.raw.recipe["deadlock-stacks-stack-py-fertilizer"] = nil
        data.raw.recipe["deadlock-stacks-unstack-py-fertilizer"] = nil
    end
end

if mods["DeadlockCrating"] then
    for item_name, item in py.iter_prototypes("item") do
        if data.raw.item["deadlock-crate-" .. item_name] ~= nil then
            data.raw.item["deadlock-crate-" .. item_name].ignore_for_dependencies = true
            data.raw.recipe["deadlock-packrecipe-" .. item_name].ignore_for_dependencies = true
            data.raw.recipe["deadlock-unpackrecipe-" .. item_name].ignore_for_dependencies = true
            data.raw.recipe["deadlock-unpackrecipe-" .. item_name].unlock_results = false

            if ITEM(item).hidden then
                ITEM("deadlock-crate-" .. item_name).hidden = true
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
