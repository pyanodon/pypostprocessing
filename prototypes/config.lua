local list = require "luagraphs.data.list"


local config = {
    STARTING_ENTITIES = list.fromArray { "character", "crash-site-assembling-machine-1-repaired", "crash-site-lab-repaired" },
    STARTING_ITEMS = list.fromArray { "iron-plate", "copper-plate", "burner-mining-drill", "stone-furnace" },

    ELECTRICITY_PRODUCER_PROTOTYPES = list.fromArray {"generator", "burner-generator", "electric-energy-interface", "solar-panel"},

    PY_GRAPHICS_MODS = list.fromArray { "__pyalienlifegraphics__", "__pyalienlifegraphics2__", "__pyalienlifegraphics3__",
        "__pyalternativeenergygraphics__", "__pycoalprocessinggraphics__", "__pyfusionenergygraphics__", "__pyhightechgraphics__",
        "__pyindustry__", "__pypetroleumhandlinggraphics__", "__pyraworesgraphics__" },

    ENTITY_SCRIPT_UNLOCKS = {},

    PRIMARY_PRODUCTION_RECIPE = {}
}

-- If an item unlocks an entity(s) that're not in its place_result:
-- config.ENTITY_SCRIPT_UNLOCKS[<item name>] = { <entity name 1>, <entity name 2> }
if mods["pypetroleumhandling"] then
    config.ENTITY_SCRIPT_UNLOCKS["bitumen-seep-mk01"] = { "oil-derrick-mk01", "oil-mk01" }
    config.ENTITY_SCRIPT_UNLOCKS["bitumen-seep-mk02"] = { "oil-derrick-mk02", "oil-mk02" }
    config.ENTITY_SCRIPT_UNLOCKS["bitumen-seep-mk03"] = { "oil-derrick-mk03", "oil-mk03" }
    config.ENTITY_SCRIPT_UNLOCKS["bitumen-seep-mk04"] = { "oil-derrick-mk04", "oil-mk04" }
    config.ENTITY_SCRIPT_UNLOCKS["natural-gas-seep-mk01"] = { "natural-gas-extractor-mk01", "natural-gas-mk01" }
    config.ENTITY_SCRIPT_UNLOCKS["natural-gas-seep-mk02"] = { "natural-gas-extractor-mk01", "natural-gas-mk01" }
    config.ENTITY_SCRIPT_UNLOCKS["natural-gas-seep-mk03"] = { "natural-gas-extractor-mk01", "natural-gas-mk01" }
    config.ENTITY_SCRIPT_UNLOCKS["natural-gas-seep-mk04"] = { "natural-gas-extractor-mk01", "natural-gas-mk01" }
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


-- PRIMARY_PRODUCTION_RECIPE means the recipe that unlocks first.
-- This is only for performance improvement for the auto-tech for items which have many different sources
config.PRIMARY_PRODUCTION_RECIPE["empty-barrel"] = "empty-barrel"
config.PRIMARY_PRODUCTION_RECIPE["cage"] = "cage"
config.PRIMARY_PRODUCTION_RECIPE["empty-fuel-canister"] = "empty-jerry-can"
config.PRIMARY_PRODUCTION_RECIPE["biomass"] = "biomass-log"

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


return config
