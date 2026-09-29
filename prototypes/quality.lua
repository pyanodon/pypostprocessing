if not mods.recycler then return end

local RECYCLING_ICON_FILEPATH = "__recycler__/graphics/icons/recycling.png"

local deadrecipes = {}
for _, recipe in pairs(data.raw.recipe) do
    if string.match(recipe.name, "recycling") 
        and recipe.icons 
        and recipe.icons[1] 
        and recipe.icons[1].icon == RECYCLING_ICON_FILEPATH 
        and #(recipe.results or {}) > 0 
    then
        -- we can have empty ingredients when other mods are involved :(
        local ingredient = recipe.ingredients and recipe.ingredients[1]
        if ingredient and data.raw[ingredient.type][ingredient.name] == nil then
            deadrecipes[recipe.name] = true
        else
            ---@cast recipe.results -? -- not nil, we checked above!
            local result = recipe.results[1]
            if result and data.raw[result.type][result.name] == nil then
                deadrecipes[recipe.name] = true
            end
        end
    end
end

for _, technology in pairs(data.raw.technology) do
    -- blacklist indexes then rebuild the effects, lol
    if technology.effects then
        local blacklisted_incidies = {}
        for i, effect in pairs(technology.effects) do
            if effect and effect.recipe and deadrecipes[effect.recipe] then
                blacklisted_incidies[i] = true
            end
        end
        -- we iterate twice but it's better than doing more work on literally every tech instead
        if table_size(blacklisted_incidies) > 0 then
            local new_effects = {}
            for i, effect in pairs(technology.effects) do
                if not blacklisted_incidies[i] then
                    new_effects[#new_effects+1] = effect
                end
            end
            technology.effects = new_effects
            log("WARNING @ quality.lua: Removed recycler recycling recipes from tech " .. technology.name)
        end
    end
end

for recipe in pairs(deadrecipes) do
    log("WARNING @ quality.lua: Deleting recycler recycling recipe " .. recipe)
    data.raw.recipe[recipe] = nil
end
