local dev_mode = false
local create_cache_mode = true
_G.verbose_logging = false

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
        if (product.amount or product[2]) ~= 1 then
            recipe.always_show_products = true
        end
    elseif recipe.result_amount ~= 1 then
        recipe.always_show_products = true
    end
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