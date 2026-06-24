if mods["reverse-factory"] then
    local whitelist = {"recycle-products", "recycle-intermediates", "recycle-with-fluids", "recycle-productivity"}

    for item_name, item in py.iter_prototypes("item") do
        local recipe_name = "rf-" .. item_name

        if data.raw.recipe[recipe_name] and RECIPE(recipe_name):has_categories(whitelist) then
            if ITEM(item).hidden then
                data.raw.recipe[recipe_name].hidden = true
            end
        end
    end

    for fluid_name, fluid in pairs(data.raw.fluid) do
        local recipe_name = "rf-" .. fluid_name

        if data.raw.recipe[recipe_name] and RECIPE(recipe_name):has_categories(whitelist) then
            if fluid.hidden then
                data.raw.recipe[recipe_name].hidden = true
            end
        end
    end
end
