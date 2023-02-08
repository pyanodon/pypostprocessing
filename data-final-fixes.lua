local dev_mode = settings.startup["pypp-dev-mode"].value
local create_cache_mode = settings.startup["pypp-create-cache"].value

require('__stdlib__/stdlib/data/data').Util.create_data_globals()

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


for _, recipe in pairs(data.raw.recipe) do
    if recipe.results and table.size(recipe.results) == 1 then
        local product = recipe.results[1]
        --log(serpent.block(recipe))
        --log(serpent.block(recipe.results))
        --log(serpent.block(product))
        if product ~= nil and (product.amount or product[2]) ~= 1 then
            recipe.always_show_products = true
        end
    elseif recipe.result_amount ~= 1 then
        recipe.always_show_products = true
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

if mods["PyBlock"] then
create_tmp_tech("fake-anti-ore")
create_tmp_tech("fake-borax-ore")
--create_tmp_tech("fake-copper-ore")
create_tmp_tech("fake-moly-ore")
create_tmp_tech("fake-nio-ore")
--create_tmp_tech("fake-aluminium-ore")
create_tmp_tech("fake-bioreserve-ore")
--create_tmp_tech("fake-chrome-ore")
create_tmp_tech("fake-lead-ore")
create_tmp_tech("fake-nickel-ore")
--create_tmp_tech("fake-tin-ore")
create_tmp_tech("fake-titanium-ore")
create_tmp_tech("fake-zinc-ore")
create_tmp_tech("fake-phosphate-ore")
create_tmp_tech("fake-ree-ore")
create_tmp_tech("fake-stone-ore")
create_tmp_tech("fake-kerogen-ore")

--aluminium
create_tmp_tech("borax-mine", "glass")
--create_tmp_tech("aluminium-plate-1")
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
-- TECHNOLOGY CHANGES
----------------------------------------------------

for _, tech in pairs(data.raw.technology) do
    local science_packs = {}
    local function add_science_pack_dep(t, science_pack, dep_pack)
        if science_packs[science_pack] and not science_packs[dep_pack] then
            TECHNOLOGY(t):add_pack(dep_pack)
            science_packs[dep_pack] = true
        end
    end

    for _, pack in pairs(tech.unit and tech.unit.ingredients or {}) do
        science_packs[pack.name or pack[1]] = true
    end

    add_science_pack_dep(tech, "utility-science-pack", "military-science-pack")

    if mods["pyalienlife"] then
        add_science_pack_dep(tech, "utility-science-pack", "py-science-pack-4")
        add_science_pack_dep(tech, "production-science-pack", "py-science-pack-3")
        add_science_pack_dep(tech, "chemical-science-pack", "py-science-pack-2")
        add_science_pack_dep(tech, "logistic-science-pack", "py-science-pack-1")
        add_science_pack_dep(tech, "py-science-pack-4", "military-science-pack")
    end

    if mods["pyalternativeenergy"] then
        add_science_pack_dep(tech, "production-science-pack", "military-science-pack")
    end
end


if dev_mode then
    log("AUTOTECH START")
    local at = require("prototypes.functions.auto_tech").create()
    at:run()
    if create_cache_mode then
        at:create_cachefile_code()
    end
    log("AUTOTECH END")
else
    require "cached-configs.run"
end


for _, lab in pairs(data.raw.lab) do
    table.sort(lab.inputs, function (i1, i2) return data.raw.tool[i1].order < data.raw.tool[i2].order end)
end

if mods['pycoalprocessing'] then
    for _, subgroup in pairs(data.raw['item-subgroup']) do
        if subgroup.group == 'intermediate-products' then
            subgroup.group = 'coal-processing'
            subgroup.order = 'b'
        end
    end
end