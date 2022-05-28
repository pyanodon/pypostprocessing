if mods["DeadlockLargerLamp"] then
    -- Originally these include electronic-circuits and are unlocked at optics, causing a deadlock in pymods
    RECIPE("deadlock-large-lamp"):remove_ingredient("electronic-circuit"):add_ingredient({type = "item", name = "copper-plate", amount = 4}):add_ingredient({type = "item", name = "glass", amount = 6})
    RECIPE("deadlock-floor-lamp"):remove_ingredient("electronic-circuit"):add_ingredient({type = "item", name = "copper-plate", amount = 4}):add_ingredient({type = "item", name = "glass", amount = 6})
end
