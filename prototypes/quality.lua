if not mods.quality then return end

local RECYCLING_ICON_FILEPATH = "__quality__/graphics/icons/recycling.png"

local deadrecipes = {}
for r, recipe in pairs(data.raw.recipe) do
    if string.match(recipe.name, "recycling") and recipe.icons and recipe.icons[1] and recipe.icons[1].icon == RECYCLING_ICON_FILEPATH then
        if data.raw.item[recipe.ingredients[1].name] == nil or data.raw.item[recipe.results[1].name] == nil then
            table.insert(deadrecipes, recipe.name)
        end
    end
end

for r, recipe in pairs(deadrecipes) do
    log("WARNING @ quality.lua: Deleting quality recycling recipe " .. recipe)
    data.raw.recipe[recipe] = nil
end