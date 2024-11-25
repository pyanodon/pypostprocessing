-- Compatibility changes which need to modify data.raw should go here.
-- Compatibility changes affecting auto-tech config should go in the bottom of config.lua

if mods["pyrawores"] then
    for _, recipe in pairs(data.raw.recipe) do
        if recipe.enabled == nil or recipe.enabled == true and recipe.name ~= "coal-gas" then
            recipe:replace_ingredient("coal", "raw-coal")
        end
    end
end

if mods["galdocs-manufacturing"] then
    require "prototypes/functions/galdoc"
end

if mods["DeadlockLargerLamp"] then
    -- Originally these include electronic-circuits and are unlocked at optics, causing a deadlock in pymods
    RECIPE("deadlock-large-lamp"):remove_ingredient("electronic-circuit"):add_ingredient {type = "item", name = "copper-plate", amount = 4}:add_ingredient {type = "item", name = "glass", amount = 6}
    RECIPE("deadlock-floor-lamp"):remove_ingredient("electronic-circuit"):add_ingredient {type = "item", name = "copper-plate", amount = 4}:add_ingredient {type = "item", name = "glass", amount = 6}
end

if mods["deadlock-beltboxes-loaders"] then
    for item_name, item in py.iter_prototypes("item") do
        local stack = data.raw.item["deadlock-stack-" .. item_name]
        if stack then
            stack.ignore_for_dependencies = true
            data.raw.recipe["deadlock-stacks-stack-" .. item_name].ignore_for_dependencies = true
            data.raw.recipe["deadlock-stacks-unstack-" .. item_name].ignore_for_dependencies = true
            data.raw.recipe["deadlock-stacks-unstack-" .. item_name].unlock_results = false

            if ITEM(item).burnt_result == "ash" then
                if not data.raw.item["deadlock-stack-ash"] then error("\n\n\n\n\nPlease install Deadlock\'s Stacking for Pyanodon\n\n\n\n\n") end
                stack.burnt_result = "deadlock-stack-ash"
            end

            if ITEM(item).hidden then
                ITEM("deadlock-stack-" .. item_name).hidden = true
                data.raw.recipe["deadlock-stacks-stack-" .. item_name].hidden = true
                data.raw.recipe["deadlock-stacks-unstack-" .. item_name].hidden = true
            end
        end
    end

    if data.raw.recipe["deadlock-stacks-stack-ralesia"] then
        RECIPE("deadlock-stacks-stack-ralesia"):remove_unlock("deadlock-stacking-1")
        RECIPE("deadlock-stacks-unstack-ralesia"):remove_unlock("deadlock-stacking-1")
        data.raw.recipe["deadlock-stacks-stack-ralesia"] = nil
        data.raw.recipe["deadlock-stacks-unstack-ralesia"] = nil
    end
    if data.raw.recipe["deadlock-stacks-stack-py-fertilizer"] then
        RECIPE("deadlock-stacks-stack-py-fertilizer"):remove_unlock("deadlock-stacking-2")
        RECIPE("deadlock-stacks-unstack-py-fertilizer"):remove_unlock("deadlock-stacking-2")
        data.raw.recipe["deadlock-stacks-stack-py-fertilizer"] = nil
        data.raw.recipe["deadlock-stacks-unstack-py-fertilizer"] = nil
    end
end

if mods["DeadlockCrating"] then
    for item_name, item in py.iter_prototypes("item") do
        if data.raw.item["deadlock-crate-" .. item_name] ~= nil then
            data.raw.item["deadlock-crate-" .. item_name].ignore_for_dependencies = true
            data.raw.recipe["deadlock-packrecipe-" .. item_name].ignore_for_dependencies = true
            data.raw.recipe["deadlock-unpackrecipe-" .. item_name].ignore_for_dependencies = true
            data.raw.recipe["deadlock-unpackrecipe-" .. item_name].unlock_results = false

            if ITEM(item).hidden then
                ITEM("deadlock-crate-" .. item_name).hidden = true
                data.raw.recipe["deadlock-packrecipe-" .. item_name].hidden = true
                data.raw.recipe["deadlock-unpackrecipe-" .. item_name].hidden = true
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

if mods["LightedPolesPlus"] then
    RECIPE("lighted-small-electric-pole"):add_unlock("optics"):remove_unlock("creosote").enabled = false
    if mods["pyalternativeenergy"] then
        RECIPE("lighted-medium-electric-pole"):remove_unlock("optics"):add_unlock("electric-energy-distribution-1")
        RECIPE("lighted-big-electric-pole"):remove_unlock("optics"):add_unlock("electric-energy-distribution-2")
        RECIPE("lighted-substation"):remove_unlock("optics"):add_unlock("electric-energy-distribution-4")
    end
end

if mods["reverse-factory"] then
    local cat = table.invert {"recycle-products", "recycle-intermediates", "recycle-with-fluids", "recycle-productivity"}

    for item_name, item in py.iter_prototypes("item") do
        local recipe_name = "rf-" .. item_name

        if data.raw.recipe[recipe_name] and cat[data.raw.recipe[recipe_name].category] then
            data.raw.recipe[recipe_name].ignore_for_dependencies = true
            data.raw.recipe[recipe_name].unlock_results = false

            if ITEM(item).hidden then
                data.raw.recipe[recipe_name].hidden = true
            end
        end
    end

    for fluid_name, fluid in pairs(data.raw.fluid) do
        local recipe_name = "rf-" .. fluid_name

        if data.raw.recipe[recipe_name] and cat[data.raw.recipe[recipe_name].category] then
            data.raw.recipe[recipe_name].ignore_for_dependencies = true
            data.raw.recipe[recipe_name].unlock_results = false

            if fluid.hidden then
                data.raw.recipe[recipe_name].hidden = true
            end
        end
    end
end

if mods["omnimatter_water"] and mods["pyindustry"] then
    RECIPE("py-sinkhole"):remove_unlock("steel-processing"):add_unlock("engine")
end

-- Trains move to py-science-1 under pyindustry, move common train mods to match
if mods["pyindustry"] then
    if mods["LogisticTrainNetwork"] then
        TECHNOLOGY("logistic-train-network"):remove_pack("logistic-science-pack")
    end

    if mods["railloader"] then
        TECHNOLOGY("railloader"):remove_pack("logistic-science-pack")
        data.raw.technology["railloader"].prerequisites = {"railway-mk01"}
    end

    if mods["train-pubsub"] then
        TECHNOLOGY("train-manager"):remove_pack("logistic-science-pack")
    end

    if mods["ShuttleTrainRefresh"] then
        TECHNOLOGY("shuttle-train"):remove_pack("logistic-science-pack")
    end

    if mods["train-upgrader"] then
        TECHNOLOGY("tu-rail-modernization"):add_prereq("railway-mk02"):remove_pack("chemical-science-pack")
    end
end

if mods["Portals"] and mods["pyhightech"] then
    -- Remove prereqs and let autotech figure it out
    TECHNOLOGY("portals"):remove_prereq("solar-panel-equipment")
    RECIPE("portal-gun"):replace_ingredient("advanced-circuit", "electronic-circuit")
    RECIPE("portal-gun"):replace_ingredient("solar-panel-equipment", "electronics-mk01")
end

if mods["Teleporters"] and mods["pyhightech"] then
    RECIPE("teleporter"):replace_ingredient("advanced-circuit", "electronic-circuit")
    -- Remove prereqs and let autotech figure it out
    TECHNOLOGY("teleporter"):remove_pack("chemical-science-pack"):remove_prereq("advanced-circuit")
    if mods["pyalienlife"] then
        TECHNOLOGY("teleporter"):remove_pack("py-science-pack-2")
    end
end

if mods["WaterWell"] then
    RECIPE("water-well-flow"):set_fields {ignore_for_dependencies = true}

    if mods["pyhightech"] and data.raw.recipe["inductor1-2"] then
        RECIPE("water-well-pump"):replace_ingredient("electronic-circuit", "inductor1")
    end
end

if mods["TinyStart"] then
    data.raw.recipe["tiny-armor-mk1"].ignore_for_dependencies = true
    data.raw.recipe["tiny-armor-mk2"].ignore_for_dependencies = true
end

if mods["Transport_Drones"] then
    local transportdepots = {
        "supply-depot",
        "request-depot",
        "buffer-depot",
        "fuel-depot",
        "fluid-depot"
    }
    data.raw.technology["transport-system"].prerequisites = nil
    data.raw.recipe["road"].category = "crafting-with-fluid"
    data.raw.recipe["road"].ingredients = data.raw.recipe["concrete"].ingredients
    TECHNOLOGY("transport-drone-capacity-1"):add_prereq("logistic-science-pack")
    TECHNOLOGY("transport-drone-speed-1"):add_prereq("logistic-science-pack")
    TECHNOLOGY("transport-drone-capacity-2"):add_prereq("chemical-science-pack")
    TECHNOLOGY("transport-drone-speed-2"):add_prereq("chemical-science-pack")
    TECHNOLOGY("transport-drone-capacity-3"):add_prereq("production-science-pack")
    TECHNOLOGY("transport-drone-speed-3"):add_prereq("production-science-pack")
    TECHNOLOGY("transport-drone-capacity-4"):add_prereq("utility-science-pack")
    TECHNOLOGY("transport-drone-speed-4"):add_prereq("utility-science-pack")
    TECHNOLOGY("transport-drone-capacity-5"):add_prereq("space-science-pack")
    for r, depotrecipe in pairs(transportdepots) do
        if data.raw.recipe[depotrecipe] and data.raw.recipe[depotrecipe].ingredients["iron-plate"] then
            data.raw.recipe[depotrecipe].ingredients["iron-plate"].amount = data.raw.recipe[depotrecipe].ingredients["iron-plate"].amount / 2
        end
        RECIPE(depotrecipe):add_ingredient {type = "item", name = "electronic-circuit", amount = 1}:add_ingredient {type = "item", name = "solder", amount = 5}
    end
    RECIPE("transport-drone"):remove_ingredient("engine-unit"):remove_ingredient("small-parts-01"):remove_ingredient("steel-plate")
    RECIPE("transport-drone"):add_ingredient {type = "item", name = "electronic-circuit", amount = 10}:add_ingredient {type = "item", name = "glass", amount = 15}:add_ingredient {type = "item", name = "copper-plate", amount = 20}
    RECIPE("transport-drone"):add_ingredient {type = "item", name = "engine-unit", amount = 5}:add_ingredient {type = "item", name = "small-parts-01", amount = 10}:add_ingredient {type = "item", name = "steel-plate", amount = 20}
    if mods["pycoalprocessing"] then
        RECIPE("road"):add_ingredient {type = "item", name = "coke", amount = 10}
    else
        RECIPE("road"):add_ingredient {type = "item", name = "coal", amount = 10}
    end
    if mods["pypetroleumhandling"] then
        RECIPE("fast-road"):replace_ingredient("crude-oil", "tar"):replace_ingredient("concrete", "road")
        TECHNOLOGY("fast-road"):add_prereq("kerogen"):remove_pack("chemical-science-pack"):remove_pack("logistic-science-pack")
    end
    if mods["pyhightech"] then
        TECHNOLOGY("transport-system"):remove_pack("logistic-science-pack"):remove_pack("py-science-pack-1"):add_prereq("vacuum-tube-electronics")
    end
    if mods["pyalienlife"] then
        TECHNOLOGY("transport-depot-circuits"):remove_pack("logistic-science-pack")
        TECHNOLOGY("fast-road"):remove_pack("py-science-pack-2"):remove_pack("py-science-pack-1")
    end
end

if mods["trainfactory"] then
    data.raw["train-stop"]["trainfactory-trainstop"].next_upgrade = nil
end

if mods["miniloader"] then
    TECHNOLOGY("miniloader"):add_pack("py-science-pack-1"):add_pack("logistic-science-pack")
    TECHNOLOGY("fast-miniloader"):add_pack("py-science-pack-2")
    RECIPE("chute-miniloader"):add_ingredient {"burner-inserter", 2}
end

if mods["Flare Stack"] then
    local cat = table.invert {"gas-venting", "flaring", "incineration", "fuel-incineration"}

    for recipe_name, recipe in pairs(data.raw.recipe) do
        if cat[recipe.category] then
            data.raw.recipe[recipe_name].ignore_for_dependencies = true
        end
    end
end

if mods["bobinserters"] and mods["pyalienlife"] then
    TECHNOLOGY("more-inserters-1"):add_pack("py-science-pack-2")
end

if mods["robot-recall"] and mods["pyindustry"] then
    -- The robot distribution chest should be available when construction bots are researched
    RECIPE("robot-redistribute-chest"):remove_unlock("logistic-robotics"):remove_ingredient("advanced-circuit")
    -- The robot recall chest can wait until mk02 robots are researched
    RECIPE("robot-recall-chest"):remove_unlock("construction-robotics"):remove_unlock("logistic-robotics"):add_unlock("robotics")
end

if mods["botReplacer"] and mods["pyindustry"] then
    -- Don't need the bot replacer chest until better bots are unlocked
    RECIPE("logistic-chest-botUpgrader"):remove_unlock("construction-robotics"):add_unlock("robotics")
end

if mods["yi_railway"] and mods["pyindustry"] then
    for recipe_name, recipe in pairs(data.raw.recipe) do
        --log('checking '..recipe_name..' , subgroup:' .. recipe.subgroup .. ' ('..string.sub(recipe.subgroup,1,4)..')')
        if recipe.subgroup and string.sub(recipe.subgroup, 1, 4) == "yir_" then
            if recipe.subgroup == "yir_locomotives_steam" then
                recipe.enabled = true
                recipe.category = data.raw.recipe["locomotive"].category
                recipe.group = data.raw.recipe["locomotive"].group
                recipe.energy_required = data.raw.recipe["locomotive"].energy_required
                recipe.ingredients = data.raw.recipe["locomotive"].ingredients -- I know what this does and I don't care

                RECIPE(recipe_name):add_unlock("railway-mk01")

                local resultname = recipe.results[1]["name"]
                local loco = data.raw.locomotive["locomotive"]
                if (loco and data.raw.locomotive[resultname]) then
                    data.raw.locomotive[resultname].weight = loco.weight
                    data.raw.locomotive[resultname].max_speed = loco.max_speed
                    data.raw.locomotive[resultname].max_power = loco.max_power
                    data.raw.locomotive[resultname].reversing_power_modifier = loco.reversing_power_modifier
                    data.raw.locomotive[resultname].braking_force = loco.braking_force
                    data.raw.locomotive[resultname].friction_force = loco.friction_force
                    data.raw.locomotive[resultname].air_resistance = loco.air_resistance
                    data.raw.locomotive[resultname].energy_source.fuel_categories = table.deepcopy(loco.energy_source.fuel_categories)
                    data.raw.locomotive[resultname].energy_source.fuel_inventory_size = loco.energy_source.fuel_inventory_size
                    data.raw.locomotive[resultname].energy_source.burnt_inventory_size = loco.energy_source.burnt_inventory_size
                else
                    --log('can't find ' .. resultname)
                end
            elseif recipe.subgroup == "yir_locomotives_diesel" or recipe.subgroup == "yir_locomotives_nslong" then
                recipe.enabled = true
                recipe.category = data.raw.recipe["mk02-locomotive"].category
                recipe.group = data.raw.recipe["mk02-locomotive"].group
                recipe.energy_required = data.raw.recipe["mk02-locomotive"].energy_required
                recipe.ingredients = data.raw.recipe["mk02-locomotive"].ingredients

                RECIPE(recipe_name):add_unlock("railway-mk02")

                local resultname = recipe.results[1]["name"]
                local loco = data.raw.locomotive["mk02-locomotive"]

                data.raw.locomotive[resultname].weight = loco.weight
                data.raw.locomotive[resultname].max_speed = loco.max_speed
                data.raw.locomotive[resultname].max_power = loco.max_power
                data.raw.locomotive[resultname].reversing_power_modifier = loco.reversing_power_modifier
                data.raw.locomotive[resultname].braking_force = loco.braking_force
                data.raw.locomotive[resultname].friction_force = loco.friction_force
                data.raw.locomotive[resultname].air_resistance = loco.air_resistance
                data.raw.locomotive[resultname].energy_source.fuel_categories = table.deepcopy(loco.energy_source.fuel_categories)
                data.raw.locomotive[resultname].energy_source.fuel_inventory_size = loco.energy_source.fuel_inventory_size
                data.raw.locomotive[resultname].energy_source.burnt_inventory_size = loco.energy_source.burnt_inventory_size
            elseif recipe.subgroup == "yir_cargowagons" or recipe.subgroup == "yir_cargowagons_4A" or
                recipe.subgroup == "yir_cargowagons_2A2" then
                recipe.enabled = true
                recipe.category = data.raw.recipe["cargo-wagon"].category
                recipe.group = data.raw.recipe["cargo-wagon"].group
                recipe.energy_required = data.raw.recipe["cargo-wagon"].energy_required
                recipe.ingredients = data.raw.recipe["cargo-wagon"].ingredients

                RECIPE(recipe_name):add_unlock("railway-mk01")

                local resultname = recipe.results[1]["name"]
                local wagon = data.raw["cargo-wagon"]["cargo-wagon"]
                local ywagon = data.raw["cargo-wagon"][resultname]

                ywagon.weight = wagon.weight
                ywagon.max_speed = wagon.max_speed
                ywagon.braking_force = wagon.braking_force
                ywagon.friction_force = wagon.friction_force
                ywagon.air_resistance = wagon.air_resistance
                ywagon.inventory_size = wagon.inventory_size
            elseif recipe.subgroup == "yir_tankwagons2a" and recipe.subgroup == "yir_fluidwagons_4A" then
                recipe.enabled = true
                recipe.category = data.raw.recipe["fluid-wagon"].category
                recipe.group = data.raw.recipe["fluid-wagon"].group
                recipe.energy_required = data.raw.recipe["fluid-wagon"].energy_required
                recipe.ingredients = data.raw.recipe["fluid-wagon"].ingredients

                RECIPE(recipe_name):add_unlock("railway-mk01")

                local resultname = recipe.results[1]["name"]
                local wagon = data.raw["fluid-wagon"]["fluid-wagon"]
                local ywagon = data.raw["fluid-wagon"][resultname]

                ywagon.weight = wagon.weight
                ywagon.max_speed = wagon.max_speed
                ywagon.braking_force = wagon.braking_force
                ywagon.friction_force = wagon.friction_force
                ywagon.air_resistance = wagon.air_resistance
                ywagon.capacity = wagon.capacity
            else
                --log('disabling '..recipe_name..' as subgroup is '..recipe.subgroup)
                recipe.ignore_for_dependencies = true
                recipe.unlock_results = false
                recipe.hidden = true
                if (recipe.results) then
                    for i, v in ipairs(recipe.results[1]) do
                        --log('  disabling '..v.name)
                        v.hidden = true
                    end
                end
            end
        elseif string.sub(recipe_name, 1, 4) == "yir_" and string.find(recipe_name, "pyvoid") == nil then
            --log('disabling '..recipe_name)
            recipe.ignore_for_dependencies = true
            recipe.unlock_results = false
            recipe.hidden = true
            if (recipe.results) then
                for i, v in ipairs(recipe.results[1]) do
                    --log('  disabling '..v.name)
                    v.hidden = true
                end
            end
        end
    end
end

if mods["Rocket-Silo-Construction"] then
    RECIPE("rsc-construction-stage1"):add_unlock("rocket-silo").enabled = false
    RECIPE("rsc-construction-stage2"):add_unlock("rocket-silo").enabled = false
    RECIPE("rsc-construction-stage3"):add_unlock("rocket-silo").enabled = false
    RECIPE("rsc-construction-stage4"):add_unlock("rocket-silo").enabled = false
    RECIPE("rsc-construction-stage5"):add_unlock("rocket-silo").enabled = false
    RECIPE("rsc-construction-stage6"):add_unlock("rocket-silo").enabled = false

    if mods["pyindustry"] and mods["pycoalprocessing"] then
        RECIPE("rsc-excavation-site"):replace_ingredient("pipe", "niobium-pipe")
        RECIPE("rsc-construction-stage4"):replace_ingredient("pipe", "niobium-pipe"):replace_ingredient("pipe-to-ground", "niobium-pipe-to-ground")
        RECIPE("rsc-construction-stage6"):replace_ingredient("radar", "megadar")
    end

    if mods["pyrawores"] then
        RECIPE("rsc-construction-stage2"):replace_ingredient("steel-plate", "stainless-steel")
        RECIPE("rsc-construction-stage4"):replace_ingredient("steel-plate", "stainless-steel")
        RECIPE("rsc-construction-stage5"):replace_ingredient("steel-plate", "stainless-steel"):replace_ingredient("copper-plate", "nexelit-plate")
    end

    if mods["pypetroleumhandling"] then
        RECIPE("rsc-excavation-site"):replace_ingredient("processing-unit", "advanced-circuit")
        RECIPE("rsc-construction-stage2"):add_ingredient {"small-parts-02", 20}
        RECIPE("rsc-construction-stage4"):add_ingredient {"small-parts-02", 10}
        RECIPE("rsc-construction-stage5"):add_ingredient {"small-parts-02", 10}
        RECIPE("rsc-construction-stage6"):remove_ingredient("processing-unit"):add_ingredient {"small-parts-02", 10}
    end

    if mods["pyalternativeenergy"] then
        RECIPE("rsc-construction-stage2"):add_ingredient {"self-assembly-monolayer", 5}
        RECIPE("rsc-construction-stage4"):add_ingredient {"self-assembly-monolayer", 5}
        RECIPE("rsc-construction-stage5"):add_ingredient {"self-assembly-monolayer", 5}
    end
end

if mods["scattergun_turret"] then
    for _, recipe in pairs(data.raw.recipe) do
        -- tried testing for subcategory, but it's nil at this point
        if recipe.name:find("^w93-") ~= nil and recipe.name:find("turret2$") ~= nil then
            recipe.ignore_for_dependencies = true
        end
    end
end

if mods["Teleporters"] and mods["pyalternativeenergy"] then
    TECHNOLOGY("teleporter"):remove_prereq("battery"):add_prereq("battery-mk01")
end

if mods["pushbutton"] then
    RECIPE("pushbutton"):remove_ingredient("advanced-circuit")
end

if mods["subspace_storage"] then
    for item_name, item_data in pairs(data.raw.item) do
        if item_data.subgroup == "subspace_storage-interactor" then
            item_data.ignore_for_dependencies = true
            if data.raw.recipe[item_name] then
                data.raw.recipe[item_name].ignore_for_dependencies = true
            end
        end
    end
    -- 'get-n' is a pretty generic pattern to rely on, so we also make sure the results are empty.
    for fluid_name in pairs(data.raw.fluid) do
        local fluid_recipe = data.raw.recipe["get-" .. fluid_name]
        local fluid_result = fluid_recipe and fluid_recipe.results
        if fluid_result and fluid_result[1] and fluid_result[1].amount == 0 then
            fluid_recipe.ignore_for_dependencies = true
        end
    end
end

if mods["bobmodules"] then
    RECIPE("module-case"):add_unlock("basic-electronics")
    RECIPE("module-contact"):add_unlock("basic-electronics")
    RECIPE("module-circuit-board"):add_unlock("basic-electronics")
    RECIPE("module-processor-board"):add_unlock("basic-electronics")
    RECIPE("module-processor-board-2"):add_unlock("basic-electronics")
    RECIPE("module-processor-board-3"):add_unlock("basic-electronics")
    RECIPE("lab-module"):add_unlock("basic-electronics")
    RECIPE("speed-processor"):add_unlock("basic-electronics")
    RECIPE("effectivity-processor"):add_unlock("basic-electronics")
    RECIPE("productivity-processor"):add_unlock("basic-electronics")
    RECIPE("pollution-clean-processor"):add_unlock("basic-electronics")
    RECIPE("pollution-create-processor"):add_unlock("basic-electronics")
end

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

if mods["aai-loaders"] then
    TECHNOLOGY("aai-express-loader"):remove_prereq("processing-unit")
    if mods["pyalienlife"] then
        TECHNOLOGY("aai-fast-loader"):remove_prereq("advanced-circuit"):remove_pack("chemical-science-pack")
    end
end

if mods["cargo-ships"] then
    TECHNOLOGY("water_transport"):remove_prereq("logistics-2"):remove_pack("logistic-science-pack")
    TECHNOLOGY("cargo_ships"):remove_pack("logistic-science-pack")
    TECHNOLOGY("automated_water_transport"):remove_pack("logistic-science-pack")
    if mods["pyalternativeenergy"] then
        TECHNOLOGY("oversea-energy-distribution"):remove_prereq("electric-energy-distribution-1"):add_prereq("electric-energy-distribution-2")
    end
end

if mods["RenaiTransportation"] then
    if mods["pyindustry"] then
        TECHNOLOGY("RTFlyingFreight"):remove_prereq("railway"):remove_prereq("concrete"):add_prereq("railway-mk01")
        TECHNOLOGY("RTImpactTech"):remove_prereq("railway"):remove_prereq("concrete"):add_prereq("railway-mk01")
    end

    if mods["pycoalprocessing"] then
        TECHNOLOGY("RTDeliverThePayload"):remove_prereq("military-3"):remove_pack("chemical-science-pack")

        RECIPE("PrimerBouncePlateRecipe"):replace_ingredient("coal", "coke")
    end

    if mods["pyfusionenergy"] then
        TECHNOLOGY("RTZiplineTech5"):remove_prereq("uranium-processing")
    end

    if mods["pyrawores"] then
        TECHNOLOGY("RTZiplineTech5"):remove_prereq("kovarex-enrichment-process")
    end

    if mods["pypetroleumhandling"] then
        RECIPE("RTZiplineRecipe3"):remove_ingredient("small-parts-01"):add_ingredient {type = "item", name = "small-parts-02", amount = 50}
        RECIPE("RTZiplineRecipe4"):remove_ingredient("small-parts-01"):add_ingredient {type = "item", name = "small-parts-03", amount = 50}
    end

    if mods["pyhightech"] then
        TECHNOLOGY("RTImpactTech"):remove_prereq("advanced-circuit")
        TECHNOLOGY("RTSimonSays"):remove_prereq("advanced-circuit"):add_prereq("circuit-network")
        TECHNOLOGY("RTZiplineTech"):add_prereq("vacuum-tube-electronics"):remove_prereq("steel-processing")
        TECHNOLOGY("RTZiplineTech2"):remove_prereq("logistic-science-pack")
        TECHNOLOGY("RTZiplineTech3"):add_prereq("basic-electronics")
        TECHNOLOGY("RTZiplineTech4"):remove_prereq("processing-unit"):add_prereq("advanced-circuit")

        RECIPE("RTImpactUnloaderRecipe"):replace_ingredient("advanced-circuit", "electronic-circuit")
        RECIPE("RTMagnetTrainRampRecipe"):replace_ingredient("advanced-circuit", "electronic-circuit")
        RECIPE("RTImpactWagonRecipe"):replace_ingredient("advanced-circuit", "electronic-circuit")
        RECIPE("DirectorBouncePlateRecipie"):replace_ingredient("advanced-circuit", "decider-combinator")
    end

    if mods["pyalienlife"] then
        TECHNOLOGY("EjectorHatchRTTech"):add_prereq("py-science-pack-mk01")
        TECHNOLOGY("RTDeliverThePayload"):add_prereq("military-science-pack")
        TECHNOLOGY("EjectorHatchRTTech"):remove_pack("logistic-science-pack")
        TECHNOLOGY("RTFlyingFreight"):remove_pack("logistic-science-pack")
        --TECHNOLOGY("SignalPlateTech"):remove_pack("logistic-science-pack")
        TECHNOLOGY("RTFreightPlates"):remove_pack("logistic-science-pack")
        TECHNOLOGY("PrimerPlateTech"):remove_pack("logistic-science-pack")
        TECHNOLOGY("RTImpactTech"):remove_pack("logistic-science-pack")
        TECHNOLOGY("RTSimonSays"):remove_pack("logistic-science-pack")
        TECHNOLOGY("RTProgrammableZiplineControlTech"):remove_pack("logistic-science-pack")
        TECHNOLOGY("RTDeliverThePayload"):remove_pack("py-science-pack-2")
        TECHNOLOGY("RTZiplineTech3"):remove_pack("chemical-science-pack")
        TECHNOLOGY("RTZiplineTech4"):add_pack("py-science-pack-3"):remove_prereq("")
    end

    if mods["pyalternativeenergy"] then
        TECHNOLOGY("RTMagnetTrainRamps"):remove_pack("chemical-science-pack"):remove_pack("py-science-pack-2")
        TECHNOLOGY("RTZiplineTech4"):add_prereq("machine-components-mk03")

        RECIPE("RTMagnetTrainRampRecipe"):add_ingredient {type = "item", name = "nexelit-plate", amount = 10}:replace_ingredient("substation", "big-electric-pole")
        RECIPE("RTZiplineRecipe3"):add_ingredient {type = "item", name = "mechanical-parts-02", amount = 10}
        RECIPE("RTZiplineRecipe4"):add_ingredient {type = "item", name = "mechanical-parts-03", amount = 10}
        RECIPE("RTTrainRampRecipe"):add_ingredient {type = "item", name = "intermetallics", amount = 10}

        data.raw.recipe["RTZiplineRecipe5"].ingredients = table.deepcopy(data.raw.recipe["exoskeleton-equipment"].ingredients)

        RECIPE("RTZiplineRecipe5"):add_ingredient {type = "item", name = "fission-reactor-equipment", amount = 1}:add_ingredient {type = "item", name = "RTZiplineItem4", amount = 1}:add_ingredient {type = "item", name = "nuclear-fuel", amount = 5}
    end
end

if mods["angelsrefining"] and not mods["PyCoalTBaA"] then
    error("\n\n\n\n\nPlease install PyCoal Touched By an Angel\n\n\n\n\n")
end

if mods["jetpack"] and mods["pyrawores"] and mods["pypetroleumhandling"] then
    -- using remove_pack doesn't work, I don't understand why
    local rocket_fuel = data.raw.technology["rocket-fuel"]
    rocket_fuel.prerequisites = mods["pyalienlife"] and {"py-science-pack-mk01", "scrude", "electrolysis"} or {"scrude", "electrolysis"}
    rocket_fuel.unit = {
        ingredients = {{mods["pyalienlife"] and "py-science-pack-1" or "automation-science-pack", 1}},
        count = 100,
        time = 30
    }
    TECHNOLOGY("jetpack-1"):set_fields {prerequisites = {"rocket-fuel"}}:remove_pack("chemical-science-pack"):remove_pack("logistic-science-pack"):add_pack("py-science-pack-1")
    RECIPE("jetpack-1"):add_ingredient {type = "item", name = "mechanical-parts-01", amount = 2}:replace_ingredient("electronic-circuit", "electronics-mk01")
    TECHNOLOGY("jetpack-2"):set_fields {prerequisites = {"jetpack-1"}}:remove_pack("chemical-science-pack"):add_pack("py-science-pack-2"):add_prereq(mods["pyalienlife"] and "py-science-pack-mk02" or "logistic-science-pack")
    TECHNOLOGY("jetpack-3"):set_fields {prerequisites = {"jetpack-2"}}:remove_pack("production-science-pack"):remove_pack("py-science-pack-4"):remove_pack("utility-science-pack"):add_pack("py-science-pack-3"):add_prereq(mods["pyalienlife"] and "py-science-pack-mk03" or "chemical-science-pack")
    TECHNOLOGY("jetpack-4"):set_fields {prerequisites = {"jetpack-3"}}:remove_pack("space-science-pack"):add_prereq("utility-science-pack")
end

if mods["extra-storage-tank-minibuffer"] then
    TECHNOLOGY("minibuffer"):remove_pack("logistic-science-pack")
end
