if mods[ "Transport_Drones" ] then
    local transportdepots = {
        "supply-depot",
        "request-depot",
        "buffer-depot",
        "fuel-depot",
        "fluid-depot"
    }
    data.raw.technology[ "transport-system" ].prerequisites = nil
    data.raw.recipe[ "road" ].category = "crafting-with-fluid"
    data.raw.recipe[ "road" ].ingredients = data.raw.recipe[ "concrete" ].ingredients
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
        if data.raw.recipe[ depotrecipe ] and data.raw.recipe[ depotrecipe ].ingredients[ "iron-plate" ] then
            data.raw.recipe[ depotrecipe ].ingredients[ "iron-plate" ].amount = data.raw.recipe[ depotrecipe ].ingredients[ "iron-plate" ].amount / 2
        end
        RECIPE(depotrecipe):add_ingredient({ type = "item", name = "electronic-circuit", amount = 1 }):add_ingredient({ type = "item", name = "solder", amount = 5 })
    end
    RECIPE("transport-drone"):remove_ingredient("engine-unit"):remove_ingredient("small-parts-01"):remove_ingredient("steel-plate")
    RECIPE("transport-drone"):add_ingredient({ type = "item", name = "electronic-circuit", amount = 10 }):add_ingredient({ type = "item", name = "glass", amount = 15 }):add_ingredient({ type = "item", name = "copper-plate", amount = 20 })
    RECIPE("transport-drone"):add_ingredient({ type = "item", name = "engine-unit", amount = 5 }):add_ingredient({ type = "item", name = "small-parts-01", amount = 10 }):add_ingredient({ type = "item", name = "steel-plate", amount = 20 })
    if mods[ "pycoalprocessing" ] then
        RECIPE("road"):add_ingredient({ type = "item", name = "coke", amount = 10 })
    else
        RECIPE("road"):add_ingredient({ type = "item", name = "coal", amount = 10 })
    end
    if mods[ "pypetroleumhandling" ] then
        RECIPE("fast-road"):replace_ingredient("crude-oil", "tar"):replace_ingredient("concrete", "road")
        TECHNOLOGY("fast-road"):add_prereq("kerogen"):remove_pack("chemical-science-pack"):remove_pack("logistic-science-pack")
    end
    if mods[ "pyhightech" ] then
        TECHNOLOGY("transport-system"):remove_pack("logistic-science-pack"):remove_pack("py-science-pack-1"):add_prereq("electronics")
    end
    if mods[ "pyalienlife" ] then
        TECHNOLOGY("transport-depot-circuits"):remove_pack("logistic-science-pack")
        TECHNOLOGY("fast-road"):remove_pack("py-science-pack-2"):remove_pack("py-science-pack-1")
    end
end
