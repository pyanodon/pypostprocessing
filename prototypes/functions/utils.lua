local config = require("prototypes.config")
local table = require("__stdlib__/stdlib/utils/table")
local string = require('__stdlib__/stdlib/utils/string')

local utils = {}


function utils.insert_double_lookup(tab, category, item)
    if not tab[category] then
        tab[category] = {}
    end

    tab[category][item] = true
end


function utils.get_prototype(parent_type, prototype_name, no_error)
    local prototype

    for t, _ in pairs(defines.prototypes[parent_type]) do
        prototype = data.raw[t] and data.raw[t][prototype_name]

        if prototype then break end
    end

    if not prototype and not no_error then
        error('\n\nERROR: Prototype not found: ' .. parent_type .. ' / ' .. prototype_name .. '\n', 0)
    end

    return prototype
end


function utils.standardize_products(products, product, item_name, count)
    local function standardize_product(p)
        return {
            type = p.type or 'item',
            name = p.name or p[1],
            amount = p.amount or p[2],
            probability = p.probability,
            amount_min = p.amount_min,
            amount_max = p.amount_max,
            catalyst_amount = p.catalyst_amount,
            temperature = p.temperature,
            min_temperature = p.minimum_temperature,
            max_temperature = p.maximum_temperature
        }
    end

    if not products then
        products = { product or { item_name, (count or 1) } }
    end

    local results = {}

    for _, p in pairs(products) do
        table.insert(results, standardize_product(p))
    end

    return results
end


function utils.is_py_or_base_tech(tech)
    local icons = tech.icons
    if not icons then icons = {{ icon = tech.icon }} end

    for _, icon in pairs(icons or {}) do
        local mod = icon and table.first(string.split(icon.icon, '/'))

        if not config.PY_GRAPHICS_MODS:contains(mod) and mod ~= '__base__' and mod ~= '__core__' then
            return false
        end
    end

    return true
end


return utils