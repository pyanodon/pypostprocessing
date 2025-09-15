if mods["WaterWell"] then
    if mods["pyhightech"] and data.raw.recipe["inductor1-2"] then
        RECIPE("water-well-pump"):replace_ingredient("electronic-circuit", "inductor1")
    end
end
