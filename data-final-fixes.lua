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


-- TMP TECHS HERE --
-- create_tmp_tech(<recipe-name>): Create tmp tech with only that recipe
-- create_tmp_tech(<recipe-name>, <tech-name>): Create tmp tech with only that recipe, and remove it from tech
if mods["pyalienlife"] then
    for t, tech in pairs(data.raw.technology) do
        local logi_pack = false
        local psp1 = false

        for _, pack in pairs(tech.unit and tech.unit.ingredients or {}) do
            if (pack.name or pack[1]) == "logistic-science-pack" then
                logi_pack = true
            elseif (pack.name or pack[1]) == "py-science-pack-1" then
                psp1 = true
            end
        end

        if logi_pack and not psp1 then
            TECHNOLOGY(tech):add_pack("py-science-pack-1")
        end
    end
end

if mods["pyalienlife"] and mods["pyhightech"] then
    -- create_tmp_tech("salt-mine", "electrolysis")
end

if mods["pyalternativeenergy"] then

end

----------------------------------------------------
-- AUTO TECH script. Make sure it's the very last
----------------------------------------------------
require('prototypes/functions/auto_tech')
----------------------------------------------------
----------------------------------------------------
