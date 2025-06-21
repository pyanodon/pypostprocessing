if mods["Portals"] and mods["pyhightech"] then
    -- Remove prereqs and let autotech figure it out
    TECHNOLOGY("portals"):remove_prereq("solar-panel-equipment")
    RECIPE("portal-gun"):replace_ingredient("advanced-circuit", "electronic-circuit")
    RECIPE("portal-gun"):replace_ingredient("solar-panel-equipment", "electronics-mk01")
end
