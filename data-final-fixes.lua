local table = require('__stdlib__/stdlib/utils/table')

for _, module in pairs(data.raw.module) do
    local remove_recipe = {}

    for _, r in pairs(module.limitation or {}) do
        if not data.raw.recipe[r] then
            remove_recipe[r] = true
        end
    end

    if not table.is_empty(remove_recipe) then
        local limit = table.array_to_dictionary(module.limitation, true)

        for r, _ in pairs(remove_recipe) do
            limit[r] = nil
        end

        module.limitation = table.keys(limit)
    end

    remove_recipe = {}

    for _, r in pairs(module.limitation_blacklist or {}) do
        if not data.raw.recipe[r] then
            remove_recipe[r] = true
        end
    end

    if not table.is_empty(remove_recipe) then
        local limit = table.array_to_dictionary(module.limitation_blacklist, true)

        for r, _ in pairs(remove_recipe) do
            limit[r] = nil
        end

        module.limitation_blacklist = table.keys(limit)
    end
end


local function create_tmp_tech(recipe, original_tech, add_dependency)
    local new_tech = TECHNOLOGY {
        type = "technology",
        name = "tmp-" .. recipe .. "-tech",
        icon = "__pypostprocessing__/graphics/placeholder.png",
        icon_size = 128,
        order = "c-a",
        prerequisites = {},
        effects = {
            { type = "unlock-recipe", recipe = recipe }
        },
        unit = {
            count = 30,
            ingredients = {
                {"automation-science-pack", 1}
            },
            time = 30
        }
    }

    RECIPE(recipe):set_enabled(false)

    if original_tech then
        RECIPE(recipe):remove_unlock(original_tech)

        if add_dependency then
            new_tech.dependencies = { original_tech }
        end
    end

    return new_tech
end


if mods["pyalienlife"] then
    for _, tech in pairs(data.raw.technology) do
        local science_packs = {}

        for _, pack in pairs(tech.unit and tech.unit.ingredients or {}) do
            science_packs[pack.name or pack[1]] = true
        end

        if science_packs["logistic-science-pack"] and not science_packs["py-science-pack-1"] then
            TECHNOLOGY(tech):add_pack("py-science-pack-1")
        end

        if science_packs["production-science-pack"] and not science_packs["py-science-pack-2"] then
            TECHNOLOGY(tech):add_pack("py-science-pack-2")
        end

        if science_packs["utility-science-pack"] and not science_packs["py-science-pack-3"] then
            TECHNOLOGY(tech):add_pack("py-science-pack-3")
        end
    end
end


-- TMP TECHS HERE --
-- create_tmp_tech(<recipe-name>): Create tmp tech with only that recipe
-- create_tmp_tech(<recipe-name>, <tech-name>): Create tmp tech with only that recipe, and remove it from tech
if mods["pyalienlife"] and mods["pyhightech"] then
    -- create_tmp_tech("salt-mine", "electrolysis")
end

if mods["pyalternativeenergy"] then

end

----------------------------------------------------
-- THIRD PARTY COMPATIBILITY
----------------------------------------------------
require('prototypes/functions/compatibility')

----------------------------------------------------
-- AUTO TECH script. Make sure it's the very last
----------------------------------------------------
require('prototypes/functions/auto_tech')
----------------------------------------------------
----------------------------------------------------
