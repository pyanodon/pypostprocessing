if mods["compaktcircuit"] then
    RECIPE("compaktcircuit-processor"):remove_ingredient("processing-unit")
    RECIPE("compaktcircuit-processor_1x1"):remove_ingredient("processing-unit")
    if mods["pyalienlife"] then
        TECHNOLOGY("compaktcircuit-tech").prerequisites = { "py-science-pack-mk02" }
        TECHNOLOGY("compaktcircuit-tech").unit.ingredients = {
            { "py-science-pack-2", 1 }
        }
    else
        TECHNOLOGY("compaktcircuit-tech").prerequisites = { "logistic-science-pack" }
        TECHNOLOGY("compaktcircuit-tech").unit.ingredients = {
            { "logistic-science-pack", 1 }
        }
    end
end
