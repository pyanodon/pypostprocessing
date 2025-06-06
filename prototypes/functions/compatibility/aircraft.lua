-- https://mods.factorio.com/mod/Aircraft
-- https://mods.factorio.com/mod/Aircraft-space-age

if (mods["Aircraft"] or mods["Aircraft-space-age"]) and mods.pycoalprocessing then
    -- Napalm tech moves from 'flammables' to 'flamethrower'
    TECHNOLOGY("napalm"):remove_prereq("flammables"):add_prereq("flamethrower")
end