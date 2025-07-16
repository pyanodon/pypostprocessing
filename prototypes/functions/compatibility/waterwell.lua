if mods["WaterWell"] then
    RECIPE("water-well-flow"):set_fields {ignore_for_dependencies = true}

    if mods["pyhightech"] and data.raw.recipe["inductor1-2"] then
        RECIPE("water-well-pump"):replace_ingredient("electronic-circuit", "inductor1")
    end
end
