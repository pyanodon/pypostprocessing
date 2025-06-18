if mods["KS_Power"] then
    TECHNOLOGY("big-burner-generator"):remove_prereq("flammables"):add_prereq("nuclear-power")
else
