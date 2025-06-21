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

                RECIPE(recipe_name):add_unlock("railway")

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

                RECIPE(recipe_name):add_unlock("railway")

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

                RECIPE(recipe_name):add_unlock("railway")

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
