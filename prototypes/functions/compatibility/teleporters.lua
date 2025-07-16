if mods["Teleporters"] and mods["pyhightech"] then
    RECIPE("teleporter"):replace_ingredient("advanced-circuit", "electronic-circuit")
    -- Remove prereqs and let autotech figure it out
    TECHNOLOGY("teleporter"):remove_pack("chemical-science-pack"):remove_prereq("advanced-circuit")
    if mods["pyalienlife"] then
        TECHNOLOGY("teleporter"):remove_pack("py-science-pack-2")
    end
end
