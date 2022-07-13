local list = require "luagraphs.data.list"


local config = {
    STARTING_ENTITIES = list.fromArray { "character", "crash-site-assembling-machine-1-repaired", "crash-site-lab-repaired" },
    STARTING_ITEMS = list.fromArray { "iron-plate", "copper-plate", "burner-mining-drill", "stone-furnace" },

    ELECTRICITY_PRODUCER_PROTOTYPES = list.fromArray {"generator", "burner-generator", "electric-energy-interface", "solar-panel"},

    PY_GRAPHICS_MODS = list.fromArray { "__pyalienlifegraphics__", "__pyalienlifegraphics2__", "__pyalienlifegraphics3__",
        "__pyalternativeenergygraphics__", "__pycoalprocessinggraphics__", "__pyfusionenergygraphics__", "__pyhightechgraphics__",
        "__pyindustry__", "__pypetroleumhandlinggraphics__", "__pyraworesgraphics__" },

    ENTITY_SCRIPT_UNLOCKS = {},

    PRIMARY_PRODUCTION_RECIPE = {},

    WIN_GAME_TECH = mods["pycoalprocessing"] and "pyrrhic" or "space-science-pack",

    -- Tech cost stuff
    TC_MANDATORY_RECIPE_COUNT_MULT = 1,
    TC_OPTIONAL_RECIPE_COUNT_MULT = 1/4,
    TC_BASE_MULT = 3600 * 10,
    TC_SCIENCE_PACK_COST = {},
    TC_SCIENCE_PACK_COST_REDUCE = {},
    TC_SCIENCE_PACK_TIME = {},
    TC_SCIENCE_PACK_MULT = {1, 2, 3, 6},
    TC_SCIENCE_PACK_MULT_STEP = 10,
    TC_STARTING_TECH_COST = 10,
    TC_EXP_THRESHOLD = 0.001,
    TC_COST_ROUNDING_TARGETS = {10, 12, 15, 20, 25, 30, 40, 50, 60, 80}
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


-- TC_SCIENCE_PACK_COST estimate science pack production "cost" relative to the cheapest (on the same tech level)
config.TC_SCIENCE_PACK_COST["automation-science-pack"] = 1
config.TC_SCIENCE_PACK_COST["py-science-pack-1"] = 2
config.TC_SCIENCE_PACK_COST["logistic-science-pack"] = 5
config.TC_SCIENCE_PACK_COST["military-science-pack"] = 10
config.TC_SCIENCE_PACK_COST["py-science-pack-2"] = 10
config.TC_SCIENCE_PACK_COST["chemical-science-pack"] = 25
config.TC_SCIENCE_PACK_COST["py-science-pack-3"] = 50
config.TC_SCIENCE_PACK_COST["production-science-pack"] = 125
config.TC_SCIENCE_PACK_COST["py-science-pack-4"] = 250
config.TC_SCIENCE_PACK_COST["utility-science-pack"] = 625
config.TC_SCIENCE_PACK_COST["space-science-pack"] = 3125

-- TC_SCIENCE_PACK_COST_REDUCE estimate how much cheaper science packs become after researching techs at a science pack tier
config.TC_SCIENCE_PACK_COST_REDUCE["automation-science-pack"] = 2
config.TC_SCIENCE_PACK_COST_REDUCE["py-science-pack-1"] = 1.5
config.TC_SCIENCE_PACK_COST_REDUCE["logistic-science-pack"] = 2
config.TC_SCIENCE_PACK_COST_REDUCE["py-science-pack-2"] = 1.5
config.TC_SCIENCE_PACK_COST_REDUCE["chemical-science-pack"] = 2
config.TC_SCIENCE_PACK_COST_REDUCE["py-science-pack-3"] = 1.5
config.TC_SCIENCE_PACK_COST_REDUCE["production-science-pack"] = 2
config.TC_SCIENCE_PACK_COST_REDUCE["py-science-pack-4"] = 1.5
config.TC_SCIENCE_PACK_COST_REDUCE["utility-science-pack"] = 2

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

if mods["DeadlockLargerLamp"] then
    RECIPE("deadlock-large-lamp"):remove_ingredient("electronic-circuit"):add_ingredient({type = "item", name = "copper-plate", amount = 4}):add_ingredient({type = "item", name = "glass", amount = 6})
    RECIPE("deadlock-floor-lamp"):remove_ingredient("electronic-circuit"):add_ingredient({type = "item", name = "copper-plate", amount = 4}):add_ingredient({type = "item", name = "glass", amount = 6})
end

if mods["deadlock-beltboxes-loaders"] then
    for item_type, _ in pairs(defines.prototypes["item"]) do
        for item_name, item in pairs(data.raw[item_type]) do
            if data.raw.item["deadlock-stack-" .. item_name] ~= nil then
                data.raw.item["deadlock-stack-" .. item_name].ignore_for_dependencies = true
                data.raw.recipe["deadlock-stacks-stack-" .. item_name].ignore_for_dependencies = true
                data.raw.recipe["deadlock-stacks-unstack-" .. item_name].ignore_for_dependencies = true

                if ITEM(item):has_flag("hidden") then
                    ITEM("deadlock-stack-" .. item_name):add_flag("hidden")
                    data.raw.recipe["deadlock-stacks-stack-" .. item_name].hidden = true
                    data.raw.recipe["deadlock-stacks-unstack-" .. item_name].hidden = true
                end
            end
        end
    end
end

if mods["DeadlockCrating"] then
    for item_type, _ in pairs(defines.prototypes["item"]) do
        for item_name, item in pairs(data.raw[item_type]) do
            if data.raw.item["deadlock-crate-" .. item_name] ~= nil then
                data.raw.item["deadlock-crate-" .. item_name].ignore_for_dependencies = true
                data.raw.recipe["deadlock-packrecipe-" .. item_name].ignore_for_dependencies = true
                data.raw.recipe["deadlock-unpackrecipe-" .. item_name].ignore_for_dependencies = true

                if ITEM(item):has_flag("hidden") then
                    ITEM("deadlock-crate-" .. item_name):add_flag("hidden")
                    data.raw.recipe["deadlock-packrecipe-" .. item_name].hidden = true
                    data.raw.recipe["deadlock-unpackrecipe-" .. item_name].hidden = true
                end
            end
        end
    end
end

if mods["deadlock_stacked_recipes"] then
    for recipe_name, recipe in pairs(data.raw.recipe) do
        if data.raw.recipe["StackedRecipe-" .. recipe_name] ~= nil then
            data.raw.recipe["StackedRecipe-" .. recipe_name].ignore_for_dependencies = true

            if recipe.hidden then
                data.raw.recipe["StackedRecipe-" .. recipe_name].hidden = true
            end
        end
    end
end

return config
