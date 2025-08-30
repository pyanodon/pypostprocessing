if mods["subspace_storage"] then
    for item_name, item_data in pairs(data.raw.item) do
        if item_data.subgroup == "subspace_storage-interactor" then
            item_data.ignore_for_dependencies = true
            if data.raw.recipe[item_name] then
                data.raw.recipe[item_name].ignore_for_dependencies = true
            end
        end
    end
    -- 'get-n' is a pretty generic pattern to rely on, so we also make sure the results are empty.
    for fluid_name in pairs(data.raw.fluid) do
        local fluid_recipe = data.raw.recipe["get-" .. fluid_name]
        local fluid_result = fluid_recipe and fluid_recipe.results
        if fluid_result and fluid_result[1] and fluid_result[1].amount == 0 then
            fluid_recipe.ignore_for_dependencies = true
        end
    end
end
