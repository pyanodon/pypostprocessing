if mods["LightedPolesPlus"] then
    RECIPE("lighted-small-electric-pole"):add_unlock("optics"):remove_unlock("creosote").enabled = false
    if mods["pyalternativeenergy"] then
        RECIPE("lighted-medium-electric-pole"):remove_unlock("optics"):add_unlock("electric-energy-distribution-1")
        RECIPE("lighted-big-electric-pole"):remove_unlock("optics"):add_unlock("electric-energy-distribution-2")
        RECIPE("lighted-substation"):remove_unlock("optics"):add_unlock("electric-energy-distribution-4")
    end
end
