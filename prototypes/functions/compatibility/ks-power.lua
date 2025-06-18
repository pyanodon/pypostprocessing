if mods["KS_Power"] and technology.name == "big-burner-generator" then
    technology:remove_prereq("flammables"):add_prereq("nuclear-power")
else
