-- https://mods.factorio.com/mod/htl

if mods.htl and mods.pycoalprocessing then
    -- Move to parent tech (which isn't hidden)
    TECHNOLOGY("hydrothermal-liquefaction"):remove_prereq("coal-liquefaction"):add_prereq("advanced-oil-processing")
    -- If pyph is present, move from the refinery (disabled and hidden) to the gasifier
    if mods.pypetroleumhandling then
        RECIPE("hydrothermal-liquefaction"):change_category("gasifier")
    end
end