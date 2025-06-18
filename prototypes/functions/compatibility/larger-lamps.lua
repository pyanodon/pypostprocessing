if mods["LargerLamps-2_0"] then
  -- Originally these include electronic-circuits and are unlocked at optics, causing a deadlock in pymods
  RECIPE("deadlock-large-lamp"):remove_ingredient("electronic-circuit"):add_ingredient {type = "item", name = "copper-plate", amount = 4}:add_ingredient {type = "item", name = "glass", amount = 6}
  RECIPE("deadlock-floor-lamp"):remove_ingredient("electronic-circuit"):add_ingredient {type = "item", name = "copper-plate", amount = 4}:add_ingredient {type = "item", name = "glass", amount = 6}
  RECIPE("deadlock-electric-copper-lamp"):remove_ingredient("advanced-circuit"):add_ingredient {type = "item", name = "deadlock-copper-lamp", amount = 1}:add_ingredient {type = "item", name = "inductor1", amount = 4}:add_ingredient {type = "item", name = "glass", amount = 6}

  data.raw["assembling-machine"]["deadlock-copper-lamp"].energy_source.fuel_categories = {"chemical","biomass","nuke"}
end
