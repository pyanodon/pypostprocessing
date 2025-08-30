if mods["KS_Power"] and mods.pycoalprocessing then
    TECHNOLOGY("big-burner-generator"):remove_prereq("flamethrower"):add_prereq("nuclear-power")
end
