local list = require "__pypostprocessing__.luagraphs.data.list"


local config = {
    STARTING_ENTITIES = list.fromArray { "character", "crash-site-assembling-machine-1-repaired", "crash-site-lab-repaired", "solid-separator" },
    STARTING_ITEMS = list.fromArray { "iron-plate", "copper-plate", "burner-mining-drill", "stone-furnace", "stone", "log", "copper-ore", "ash", "soil"},

    ELECTRICITY_PRODUCER_PROTOTYPES = list.fromArray {"generator", "burner-generator", "electric-energy-interface", "solar-panel"},

    PY_GRAPHICS_MODS = list.fromArray { "__pyalienlifegraphics__", "__pyalienlifegraphics2__", "__pyalienlifegraphics3__",
        "__pyalternativeenergygraphics__", "__pycoalprocessinggraphics__", "__pyfusionenergygraphics__", "__pyhightechgraphics__",
        "__pyindustry__", "__pypetroleumhandlinggraphics__", "__pyraworesgraphics__" },

    ENTITY_SCRIPT_UNLOCKS = {},

    PRIMARY_PRODUCTION_RECIPE = {},

    WIN_GAME_TECH = mods["pycoalprocessing"] and "pyrrhic" or "space-science-pack",

    -- Tech cost stuff
    TC_MANDATORY_RECIPE_COUNT_MULT = 1/4,
    TC_OPTIONAL_RECIPE_COUNT_MULT = 1/16,
    TC_BASE_MULT = 3600 * 0.2,
    TC_SCIENCE_PACK_TIME = {},
    TC_SCIENCE_PACK_MULT = {1, 2, 3, 6},
    TC_SCIENCE_PACK_MULT_STEP = 10,
    TC_STARTING_TECH_COST = 20,
    TC_WIN_TECH_COST = 500,
    TC_WIN_TECH_COST_OVERRIDE = 3000,
    TC_EXP_THRESHOLD = 0.001,
    TC_COST_ROUNDING_TARGETS = {10, 11, 12, 13, 14, 15, 16, 17.5, 20, 22.5, 25, 27.5, 30, 33, 36, 40, 45, 50, 55, 60, 65, 70, 75, 80, 90}     -- Should be >=10 & <100
}

-- If an item unlocks an entity(s) that're not in its place_result:
-- config.ENTITY_SCRIPT_UNLOCKS[<item name>] = { <entity name 1>, <entity name 2> }
if mods["pypetroleumhandling"] then
    config.ENTITY_SCRIPT_UNLOCKS["bitumen-seep-mk01"] = { "oil-derrick-mk01", "oil-mk01" }
    config.ENTITY_SCRIPT_UNLOCKS["bitumen-seep-mk02"] = { "oil-derrick-mk02", "oil-mk02" }
    config.ENTITY_SCRIPT_UNLOCKS["bitumen-seep-mk03"] = { "oil-derrick-mk03", "oil-mk03" }
    config.ENTITY_SCRIPT_UNLOCKS["bitumen-seep-mk04"] = { "oil-derrick-mk04", "oil-mk04" }
    config.ENTITY_SCRIPT_UNLOCKS["natural-gas-seep-mk01"] = { "natural-gas-extractor-mk01", "natural-gas-mk01" }
    config.ENTITY_SCRIPT_UNLOCKS["natural-gas-seep-mk02"] = { "natural-gas-extractor-mk02", "natural-gas-mk01" }
    config.ENTITY_SCRIPT_UNLOCKS["natural-gas-seep-mk03"] = { "natural-gas-extractor-mk03", "natural-gas-mk01" }
    config.ENTITY_SCRIPT_UNLOCKS["natural-gas-seep-mk04"] = { "natural-gas-extractor-mk04", "natural-gas-mk01" }
    config.ENTITY_SCRIPT_UNLOCKS["tar-seep-mk01"] = { "tar-extractor-mk01", "tar-patch" }
    config.ENTITY_SCRIPT_UNLOCKS["tar-seep-mk02"] = { "tar-extractor-mk02", "tar-patch" }
    config.ENTITY_SCRIPT_UNLOCKS["tar-seep-mk03"] = { "tar-extractor-mk03", "tar-patch" }
    config.ENTITY_SCRIPT_UNLOCKS["tar-seep-mk04"] = { "tar-extractor-mk04", "tar-patch" }
end

if mods["pyalternativeenergy"] then
    config.ENTITY_SCRIPT_UNLOCKS["numal-reef-mk01"] = { "numal-reef-mk01" }
    config.ENTITY_SCRIPT_UNLOCKS["numal-reef-mk02"] = { "numal-reef-mk02" }
    config.ENTITY_SCRIPT_UNLOCKS["numal-reef-mk03"] = { "numal-reef-mk03" }
    config.ENTITY_SCRIPT_UNLOCKS["numal-reef-mk04"] = { "numal-reef-mk04" }
end


-- Research time if the science pack is the highest on the tech
config.TC_SCIENCE_PACK_TIME["automation-science-pack"] = 30
config.TC_SCIENCE_PACK_TIME["py-science-pack-1"] = 45
config.TC_SCIENCE_PACK_TIME["logistic-science-pack"] = 60
config.TC_SCIENCE_PACK_TIME["military-science-pack"] = 90
config.TC_SCIENCE_PACK_TIME["py-science-pack-2"] = 90
config.TC_SCIENCE_PACK_TIME["chemical-science-pack"] = 120
config.TC_SCIENCE_PACK_TIME["py-science-pack-3"] = 180
config.TC_SCIENCE_PACK_TIME["production-science-pack"] = 300
config.TC_SCIENCE_PACK_TIME["py-science-pack-4"] = 450
config.TC_SCIENCE_PACK_TIME["utility-science-pack"] = 600
config.TC_SCIENCE_PACK_TIME["space-science-pack"] = 1200


-- PRIMARY_PRODUCTION_RECIPE means the recipe that unlocks first.
-- This is only for performance improvement for the auto-tech for items which have many different sources
config.PRIMARY_PRODUCTION_RECIPE["empty-barrel"] = "empty-barrel"
config.PRIMARY_PRODUCTION_RECIPE["cage"] = "cage"
config.PRIMARY_PRODUCTION_RECIPE["empty-fuel-canister"] = "empty-jerry-can"
config.PRIMARY_PRODUCTION_RECIPE["biomass"] = "biomass-log"
config.PRIMARY_PRODUCTION_RECIPE["used-auog"] = "burnt:auog"

if mods["pyrawores"] then
    config.PRIMARY_PRODUCTION_RECIPE["ash"] = "burnt:raw-coal"
else
    config.PRIMARY_PRODUCTION_RECIPE["ash"] = "burnt:coal"
end


-- ==========================================================================================
-- Compatibility settings
-- ==========================================================================================
if mods["NoHandCrafting"] then
    config.STARTING_ITEMS:add("assembling-machine-1")
end

if mods["trainfactory"] then
    config.ENTITY_SCRIPT_UNLOCKS["trainfactory-full-placer-item"] = { "trainfactory-full-entity" }
    config.ENTITY_SCRIPT_UNLOCKS["trainfactory-half-placer-item"] = { "trainfactory-half-entity" }
    config.ENTITY_SCRIPT_UNLOCKS["trainfactory-disassemble-full-placer-item"] = { "trainfactory-disassemble-full-entity" }
    config.ENTITY_SCRIPT_UNLOCKS["trainfactory-disassemble-half-placer-item"] = { "trainfactory-disassemble-half-entity" }
end

if mods["Rocket-Silo-Construction"] then
    config.ENTITY_SCRIPT_UNLOCKS["rsc-building-stage1"] = { "rsc-silo-stage2" }
    config.ENTITY_SCRIPT_UNLOCKS["rsc-building-stage2"] = { "rsc-silo-stage3" }
    config.ENTITY_SCRIPT_UNLOCKS["rsc-building-stage3"] = { "rsc-silo-stage4" }
    config.ENTITY_SCRIPT_UNLOCKS["rsc-building-stage4"] = { "rsc-silo-stage5" }
    config.ENTITY_SCRIPT_UNLOCKS["rsc-building-stage5"] = { "rsc-silo-stage6" }
    config.ENTITY_SCRIPT_UNLOCKS["rsc-building-stage6"] = { "rocket-silo" }
end


-- ==========================================================================================
return config
