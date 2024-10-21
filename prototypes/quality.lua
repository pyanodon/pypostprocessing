if not mods.quality then return end

local deadrecipes = {}
for r, recipe in pairs(data.raw.recipe) do
    if string.match(recipe.name, "recycling") ~= nil then
        if data.raw.item[recipe.ingredients[1].name] == nil or data.raw.item[recipe.results[1].name] == nil then
            table.insert(deadrecipes, recipe.name)
        end
    end
end

for r, recipe in pairs(deadrecipes) do
    log("WARNING @ quality.lua: Deleting quality recycling recipe " .. recipe)
    data.raw.recipe[recipe] = nil
end
local deadrecipes = {}

for t, tech in pairs(data.raw.technology) do
    for e, effect in pairs(tech.effects or {}) do
        if effect.type == "unlock-recipe" then
            if data.raw.recipe[effect.recipe] == nil then
                log("WARNING @ quality.lua " .. tech.name .. ": Recipe unlock effect " .. effect.recipe .. " does not exist!")
                data.raw.technology[tech.name].effects[e] = nil
            end
        end
    end
end
