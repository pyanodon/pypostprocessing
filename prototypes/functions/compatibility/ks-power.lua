-- https://mods.factorio.com/mod/KS_Power

if mods["KS_Power"] and mods.pycoalprocessing then
    -- Big burner generator tech moves from 'flammables' to 'nuclear-power'
    TECHNOLOGY("big-burner-generator"):remove_prereq("flammables"):add_prereq("nuclear-power")
end