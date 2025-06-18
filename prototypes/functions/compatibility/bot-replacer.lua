if mods["botReplacer"] and mods["pyindustry"] then
    -- Don't need the bot replacer chest until better bots are unlocked
    RECIPE("logistic-chest-botUpgrader"):remove_unlock("construction-robotics"):add_unlock("robotics")
end
