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
        icon = "__pycoalprocessinggraphics__/graphics/placeholder.png",
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

end

if mods["pyalienlife"] and mods["pyhightech"] then
    -- create_tmp_tech("salt-mine", "electrolysis")
end

if mods["pyalternativeenergy"] then
    create_tmp_tech("nexelit-battery-recharge", "battery-mk02")

    create_tmp_tech("aerial-blimp-mk03", "renewable-mk03")
    create_tmp_tech("multiblade-turbine-mk03", "renewable-mk03")

    create_tmp_tech("czts-plate", "solar-mk03")
    create_tmp_tech("czts-slab", "solar-mk03")

    create_tmp_tech("sc-engine", "erbium")
    create_tmp_tech("rotor-m", "erbium")
    create_tmp_tech("magnetic-ring", "erbium")

    create_tmp_tech("arsenic", "nano-tech")
    create_tmp_tech("gaas", "nano-tech")
    create_tmp_tech("nanocrystaline-core", "nano-tech")

    create_tmp_tech("heavy-fermion", "integrated-circuits-3")

    create_tmp_tech("ammonium-sulfate", "nanozymes")

    create_tmp_tech("utility-box-mk04", "intermetallics-mk04")
    create_tmp_tech("electronics-mk04", "intermetallics-mk04")
    create_tmp_tech("controler-mk04", "intermetallics-mk04")
    create_tmp_tech("heating-system", "intermetallics-mk04")

    create_tmp_tech("tio2", "solar-mk03")
    create_tmp_tech("crude-top-layer", "solar-mk03")
    create_tmp_tech("transparent-anode", "solar-mk03")

    create_tmp_tech("brake-mk03", "energy-3")
    create_tmp_tech("hydraulic-system-mk01", "energy-3")

    create_tmp_tech("neutron-moderator-mk01")
    create_tmp_tech("control-rod")
end

----------------------------------------------------
-- AUTO TECH script. Make sure it's the very last
----------------------------------------------------
require('prototypes/functions/auto_tech')
----------------------------------------------------
----------------------------------------------------
