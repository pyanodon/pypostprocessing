if mods["cargo-ships"] then
    TECHNOLOGY("water_transport"):remove_prereq("logistics-2"):remove_pack("logistic-science-pack")
    TECHNOLOGY("cargo_ships"):remove_pack("logistic-science-pack")
    TECHNOLOGY("automated_water_transport"):remove_pack("logistic-science-pack")
    if mods["pyalternativeenergy"] then
        TECHNOLOGY("oversea-energy-distribution"):remove_prereq("electric-energy-distribution-1"):add_prereq("electric-energy-distribution-2")
    end
end
