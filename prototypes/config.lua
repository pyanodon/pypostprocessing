local config = {
    PY_GRAPHICS_MODS = table.invert {"__pyalienlifegraphics__", "__pyalienlifegraphics2__", "__pyalienlifegraphics3__",
        "__pyalternativeenergygraphics__", "__pycoalprocessinggraphics__", "__pyfusionenergygraphics__", "__pyhightechgraphics__",
        "__pyindustry__", "__pypetroleumhandlinggraphics__", "__pyraworesgraphics__", "__pyaliensgraphics__", "__pystellarexpeditiongraphics__"},

    PYMODS = {
        "pycoalprocessing",
        "pyindustry",
        "pyfusionenergy",
        "pyrawores",
        "pypetroleumhandling",
        "pyhightech",
        "pyalienlife",
        "pyalternativeenergy",
        "PyBlock",
        "pystellarexpedition",
        "pyaliens"
    },
    TC_SCIENCE_PACK_COUNTS_PER_LEVEL = {},
    TC_TECH_INGREDIENTS_PER_LEVEL = {},
    TC_MIL_SCIENCE_IS_PROGRESSION_PACK = not not mods.pystellarexpedition,
    TC_MIL_SCIENCE_PACK_COUNT_PER_LEVEL = {},

    NON_PRODDABLE_ITEMS = {
        ["empty-barrel-milk"] = true,
        ["barrel"] = true,
        ["methanol-gas-canister"] = true,
        ["empty-gas-canister"] = true,
        ["cage"] = true,
        ["empty-fuel-canister"] = true,
    },

    SCIENCE_PACKS = {},
    SCIENCE_PACK_INDEX = {}
}

if mods.pystellarexpedition then
    config.SCIENCE_PACKS = {
        "automation-science-pack",
        "py-science-pack-1",
        "logistic-science-pack",
        "military-science-pack",
        "py-science-pack-2",
        "chemical-science-pack",
        "space-science-pack-2",
        "py-science-pack-3",
        "production-science-pack",
        "py-science-pack-4",
        "utility-science-pack",
        "space-science-pack",
    }
elseif mods.pyalienlife then
    config.SCIENCE_PACKS = {
        "automation-science-pack",
        "py-science-pack-1",
        "logistic-science-pack",
        "py-science-pack-2",
        "chemical-science-pack",
        "py-science-pack-3",
        "production-science-pack",
        "py-science-pack-4",
        "utility-science-pack",
        "space-science-pack",
    }
else
    config.SCIENCE_PACKS = {
        "automation-science-pack",
        "logistic-science-pack",
        "chemical-science-pack",
        "production-science-pack",
        "utility-science-pack",
        "space-science-pack",
    }
end
for i, science_pack in pairs(config.SCIENCE_PACKS) do
    config.SCIENCE_PACK_INDEX[science_pack] = i
end

-- Research cost if the science pack is the highest on the tech
if mods.pystellarexpedition then
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["automation-science-pack"] = {1}
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["py-science-pack-1"] = {1, 2}
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["logistic-science-pack"] = {1, 2, 4}
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["military-science-pack"] = {1, 2, 4, 6}
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["py-science-pack-2"] = {1, 2, 4, 6, 8}
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["chemical-science-pack"] = {1, 2, 4, 6, 8, 10}
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["space-science-pack-2"] = {1, 2, 4, 6, 8, 10, 20}
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["py-science-pack-3"] = {1, 2, 4, 6, 8, 10, 20, 30}
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["production-science-pack"] = {1, 2, 4, 6, 8, 10, 20, 30, 40}
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["py-science-pack-4"] = {1, 2, 4, 6, 8, 10, 20, 30, 40, 50}
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["utility-science-pack"] = {1, 2, 4, 6, 8, 10, 20, 30, 40, 50, 80}
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["space-science-pack"] = {1, 2, 4, 6, 8, 10, 20, 30, 40, 50, 80, 100}
elseif mods.pyalienlife then
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["automation-science-pack"] = {1}
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["py-science-pack-1"] = {1, 2}
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["logistic-science-pack"] = {1, 2, 3}
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["py-science-pack-2"] = {1, 2, 3, 6}
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["chemical-science-pack"] = {1, 2, 3, 6, 10}
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["py-science-pack-3"] = {1, 2, 3, 6, 10, 20}
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["production-science-pack"] = {1, 2, 3, 6, 10, 20, 30}
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["py-science-pack-4"] = {1, 2, 3, 6, 10, 20, 30, 60}
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["utility-science-pack"] = {1, 2, 3, 6, 10, 20, 30, 60, 100}
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["space-science-pack"] = {1, 2, 3, 6, 10, 20, 30, 60, 100, 200}
else
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["automation-science-pack"] = {1}
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["logistic-science-pack"] = {1, 2}
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["chemical-science-pack"] = {1, 2, 3}
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["production-science-pack"] = {1, 2, 3, 6}
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["utility-science-pack"] = {1, 2, 3, 6, 10}
    config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL["space-science-pack"] = {1, 2, 3, 6, 10, 20}
end

for highest_level_pack, counts_per_level in pairs(config.TC_SCIENCE_PACK_COUNTS_PER_LEVEL) do
    local pack_count = #counts_per_level
    local packs = {}

    for level, count in pairs(counts_per_level) do
        packs[#packs + 1] = {config.SCIENCE_PACKS[pack_count - level + 1], count}
    end

    config.TC_TECH_INGREDIENTS_PER_LEVEL[highest_level_pack] = packs
end

-- Research cost if the science pack is the highest on the tech
if mods.pystellarexpedition then
    -- TC_MIL_SCIENCE_PACK_COUNT_PER_LEVEL is not needed, since it's a progression pack now
elseif mods.pyalienlife then
    config.TC_MIL_SCIENCE_PACK_COUNT_PER_LEVEL["automation-science-pack"] = 1
    config.TC_MIL_SCIENCE_PACK_COUNT_PER_LEVEL["py-science-pack-1"] = 1
    config.TC_MIL_SCIENCE_PACK_COUNT_PER_LEVEL["logistic-science-pack"] = 1
    config.TC_MIL_SCIENCE_PACK_COUNT_PER_LEVEL["py-science-pack-2"] = 1
    config.TC_MIL_SCIENCE_PACK_COUNT_PER_LEVEL["chemical-science-pack"] = 2
    config.TC_MIL_SCIENCE_PACK_COUNT_PER_LEVEL["py-science-pack-3"] = 3
    config.TC_MIL_SCIENCE_PACK_COUNT_PER_LEVEL["production-science-pack"] = 6
    config.TC_MIL_SCIENCE_PACK_COUNT_PER_LEVEL["py-science-pack-4"] = 10
    config.TC_MIL_SCIENCE_PACK_COUNT_PER_LEVEL["utility-science-pack"] = 20
    config.TC_MIL_SCIENCE_PACK_COUNT_PER_LEVEL["space-science-pack"] = 30
else
    config.TC_MIL_SCIENCE_PACK_COUNT_PER_LEVEL["automation-science-pack"] = 1
    config.TC_MIL_SCIENCE_PACK_COUNT_PER_LEVEL["logistic-science-pack"] = 1
    config.TC_MIL_SCIENCE_PACK_COUNT_PER_LEVEL["chemical-science-pack"] = 1
    config.TC_MIL_SCIENCE_PACK_COUNT_PER_LEVEL["production-science-pack"] = 2
    config.TC_MIL_SCIENCE_PACK_COUNT_PER_LEVEL["utility-science-pack"] = 3
    config.TC_MIL_SCIENCE_PACK_COUNT_PER_LEVEL["space-science-pack"] = 6
end

return config
