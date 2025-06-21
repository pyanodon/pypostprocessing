if mods["reverse-factory"] then
    local cat = table.invert {"recycle-products", "recycle-intermediates", "recycle-with-fluids", "recycle-productivity"}

    for item_name, item in py.iter_prototypes("item") do
        local recipe_name = "rf-" .. item_name

        if data.raw.recipe[recipe_name] and cat[data.raw.recipe[recipe_name].category] then
            data.raw.recipe[recipe_name].ignore_for_dependencies = true
            data.raw.recipe[recipe_name].unlock_results = false

            if ITEM(item).hidden then
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
