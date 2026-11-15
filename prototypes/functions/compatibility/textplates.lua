-- In case that pyrawores is installed but pyalternativeenergy is not, the textplates will crash on use of hidden prerequisite technology.
-- This is happening because pyrawores hides uranium-processing and pyalternativeenergy unhides it back.
-- This compat places it after first technology which unlocks Uranium-238 which is used in recipes unlocked by textplates-uranium.

if mods["textplates"] and mods["pyrawores"] and not mods["pyalternativeenergy"] then
    TECHNOLOGY("textplates-uranium"):remove_prereq("uranium-processing"):add_prereq("uranium-mk01")
end
