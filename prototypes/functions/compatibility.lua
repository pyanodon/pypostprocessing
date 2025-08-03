-- Compatibility changes which need to modify data.raw should go here.
-- Additionally you should add new compatibility code not related to the py mods into it's own mod group file or mod file to keep things organized.
-- Compatibility changes affecting auto-tech config should go in the bottom of config.lua

if data.raw.recipe["electronic-circuit"].enabled == false
    and (not data.raw.recipe["electronic-circuit-initial"] or data.raw.recipe["electronic-circuit-initial"].enabled == false)
    and data.raw.recipe["inductor1-2"]
    and (data.raw.recipe["inductor1-2"].enabled == nil or data.raw.recipe["inductor1-2"].enabled == true)
then
    for _, recipe in pairs(data.raw.recipe) do
        recipe:standardize()
        if (recipe.enabled == nil or recipe.enabled == true) and not recipe.ignore_for_dependencies then
            recipe:replace_ingredient("electronic-circuit", "inductor1")
        end
    end
end

if mods["angelsrefining"] and not mods["PyCoalTBaA"] then
    error("\n\n\n\n\nPlease install PyCoal Touched By an Angel\n\n\n\n\n")
end

-- [Impossible to research technology - rampant-arsenal-technology-flamethrower-3 has hidden prereq processing unit](https://github.com/pyanodon/pybugreports/issues/1015)
if mods.pyhightech then
    for _, technology in pairs(data.raw.technology) do
        for _, prereq in pairs(technology.prerequisites or {}) do
            if prereq == "processing-unit" then
                technology:remove_prereq("processing-unit"):add_prereq("advanced-circuit")
            elseif prereq == "battery-mk2-equipment" then
                technology:remove_prereq("battery-mk2-equipment"):add_prereq("py-accumulator-mk01")
            elseif prereq == "battery-equipment" then
                technology:remove_prereq("battery-equipment"):add_prereq("electric-energy-accumulators")
            end
        end
    end
end

if mods.pycoalprocessing then
    for _, technology in pairs(data.raw.technology) do
        for _, prereq in pairs(technology.prerequisites or {}) do
            if prereq == "modules" then
                technology:remove_prereq("modules"):add_prereq("speed-module")
            elseif prereq == "laser" then
                technology:remove_prereq("laser"):add_prereq("logistic-science-pack")
            elseif prereq == "flammables" then
                technology:remove_prereq("flammables"):add_prereq("flamethrower")
            end
        end
    end
end

-- [advanced-solar has hidden prerequisite solar-energy](https://github.com/pyanodon/pybugreports/issues/1014)
if mods.pyalternativeenergy then
    for _, technology in pairs(data.raw.technology) do
        for _, prereq in pairs(technology.prerequisites or {}) do
            if prereq == "solar-energy" then
                technology:remove_prereq("solar-energy"):add_prereq("solar-mk01")
            elseif prereq == "battery" then
                technology:remove_prereq("battery"):add_prereq("battery-mk01")
            elseif prereq == "nuclear-fuel-reprocessing" then
                technology:remove_prereq("nuclear-fuel-reprocessing")
            end
        end
    end
end

if mods.pyrawores then
    for _, recipe in pairs(data.raw.recipe) do
        if recipe.enabled == nil or recipe.enabled == true and recipe.name ~= "coal-gas" then
            recipe:replace_ingredient("coal", "raw-coal")
        end
    end
    for _, technology in pairs(data.raw.technology) do
        for _, prereq in pairs(technology.prerequisites or {}) do
            if prereq == "kovarex-enrichment-process" then
                technology:remove_prereq("kovarex-enrichment-process"):add_prereq("uranium-mk01")
            end
        end
    end
end

if mods.pyindustry then
    for _, technology in pairs(data.raw.technology) do
        for i, pre in pairs(technology.prerequisites or {}) do
            if pre == "radar" then
                technology:remove_prereq("radar"):add_prereq("radars-mk01")
                break
            end
        end
    end
end

if not mods.pyalienlife and mods.pypetroleumhandling then
    RECIPE("oil-refinery"):remove_unlock("plastics")
end

require("compatibility.aai")
require("compatibility.bobs")
require("compatibility.bot-replacer")
require("compatibility.cargo-ships")
require("compatibility.compakt-circuit")
require("compatibility.deadlock")
require("compatibility.extra-storage-tank-minibuffer")
require("compatibility.flare-stack")
require("compatibility.galdoc")
require("compatibility.htl")
require("compatibility.jetpack")
require("compatibility.ks-power")
require("compatibility.larger-lamps")
require("compatibility.lighted-poles-plus")
require("compatibility.logistic-train-network")
require("compatibility.miniloader")
require("compatibility.nixie-tubes")
require("compatibility.omnimatter-water")
require("compatibility.plutonium-energy")
require("compatibility.portals")
require("compatibility.push-button")
require("compatibility.railloader")
require("compatibility.rampant-arsenal")
require("compatibility.renai-transportation")
require("compatibility.reverse-factory")
require("compatibility.robot-recall")
require("compatibility.rocket-silo-construction")
require("compatibility.scattergun-turret")
require("compatibility.shuttle-train-refresh")
require("compatibility.subspace-storage")
require("compatibility.teleporters")
require("compatibility.tiny-start")
require("compatibility.train-pubsub")
require("compatibility.train-upgrader")
require("compatibility.trainfactory")
require("compatibility.transport-drones")
require("compatibility.waterwell")
require("compatibility.yirailway")
