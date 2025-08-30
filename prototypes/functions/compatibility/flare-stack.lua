if mods[ "Flare Stack" ] then
    local cat = table.invert({ "gas-venting", "flaring", "incineration", "fuel-incineration" })

    for recipe_name, recipe in pairs(data.raw.recipe) do
        if cat[ recipe.category ] then
            data.raw.recipe[ recipe_name ].ignore_for_dependencies = true
        end
    end
end
