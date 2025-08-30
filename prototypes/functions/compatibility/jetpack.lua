if mods["jetpack"] and mods["pyrawores"] and mods["pypetroleumhandling"] then
    -- using remove_pack doesn't work, I don't understand why
    local rocket_fuel = data.raw.technology["rocket-fuel"]
    rocket_fuel.prerequisites = mods["pyalienlife"] and { "py-science-pack-mk01", "scrude", "electrolysis" } or { "scrude", "electrolysis" }
    rocket_fuel.unit = {
        ingredients = { { mods["pyalienlife"] and "py-science-pack-1" or "automation-science-pack", 1 } },
        count = 100,
        time = 30
    }
    TECHNOLOGY("jetpack-1"):set_fields({ prerequisites = { "rocket-fuel" } }):remove_pack("chemical-science-pack"):remove_pack("logistic-science-pack"):add_pack("py-science-pack-1")
    RECIPE("jetpack-1"):add_ingredient({ type = "item", name = "mechanical-parts-01", amount = 2 }):replace_ingredient("electronic-circuit", "electronics-mk01")
    TECHNOLOGY("jetpack-2"):set_fields({ prerequisites = { "jetpack-1" } }):remove_pack("chemical-science-pack"):add_pack("py-science-pack-2"):add_prereq(mods["pyalienlife"] and "py-science-pack-mk02" or "logistic-science-pack")
    TECHNOLOGY("jetpack-3"):set_fields({ prerequisites = { "jetpack-2" } }):remove_pack("production-science-pack"):remove_pack("py-science-pack-4"):remove_pack("utility-science-pack"):add_pack("py-science-pack-3"):add_prereq(mods["pyalienlife"] and "py-science-pack-mk03" or "chemical-science-pack")
    TECHNOLOGY("jetpack-4"):set_fields({ prerequisites = { "jetpack-3" } }):remove_pack("space-science-pack"):add_prereq("utility-science-pack")
end
