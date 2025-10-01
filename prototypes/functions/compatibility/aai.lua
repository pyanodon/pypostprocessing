if mods["aai-vehicles-miner"] and not mods["pyalienlife"] then
    TECHNOLOGY("vehicle-miner-2"):remove_prereq("electric-mining-drill")
end

if mods["aai-loaders"] then
    if data.raw.technology["aai-fast-loader"] and mods["pyalienlife"] then
        TECHNOLOGY("aai-fast-loader"):remove_prereq("advanced-circuit"):remove_pack("chemical-science-pack")
    end
end

if mods["aai-signal-transmission"] then
    TECHNOLOGY("aai-signal-transmission")
        :remove_prereq("advanced-circuit")
        :remove_prereq("electric-engine")
        :add_prereq("logistic-science-pack")
        :remove_pack("chemical-science-pack")
        :remove_pack("py-science-pack-2")

    TECHNOLOGY("aai-signal-transmission").unit = {
        count = 200,
        time = 60,
        ingredients = {
            { "logistic-science-pack", 1 }
        }
    }

    RECIPE("aai-signal-sender")
        :replace_ingredient("processing-unit", "electronic-circuit")
        :replace_ingredient("electric-engine-unit", "mechanical-parts-01", 2)
        :add_ingredient({ type = "item", name = "intermetallics", amount = 20 })
        :add_ingredient({ type = "item", name = "duralumin", amount = 20 })
        :add_ingredient({ type = "item", name = "small-parts-01", amount = 30 })


    RECIPE("aai-signal-receiver")
        :replace_ingredient("processing-unit", "electronic-circuit")
        :replace_ingredient("electric-engine-unit", "gearbox-mk01", 5)
        :add_ingredient({ type = "item", name = "shaft-mk01", amount = 2 })
        :add_ingredient({ type = "item", name = "lead-plate", amount = 10 })
        :add_ingredient({ type = "item", name = "small-parts-01", amount = 10 })
end
