if mods["aai-vehicles-miner"] and not mods["pyalienlife"] then
    TECHNOLOGY("vehicle-miner-2"):remove_prereq("electric-mining-drill")
end

if mods["aai-loaders"] then
    if data.raw.technology["aai-fast-loader"] and mods["pyalienlife"] then
        TECHNOLOGY("aai-fast-loader"):remove_prereq("advanced-circuit"):remove_pack("chemical-science-pack")
    end
end
