if mods[ "scattergun_turret" ] then
    for _, recipe in pairs(data.raw.recipe) do
        -- tried testing for subcategory, but it's nil at this point
        if recipe.name:find("^w93-") ~= nil and recipe.name:find("turret2$") ~= nil then
            recipe.ignore_for_dependencies = true
        end
    end
end
