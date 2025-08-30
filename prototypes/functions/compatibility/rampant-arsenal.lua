-- https://mods.factorio.com/mod/RampantArsenal
-- https://mods.factorio.com/mod/RampantArsenalFork
if (mods[ "RampantArsenal" ] or mods[ "RampantArsenalFork" ]) and mods.pyindustry and mods.pycoalprocessing then
    -- Superceded by pyin batteries
    ITEM("mk3-battery-rampant-arsenal"):set_fields({ hidden = true })
    TECHNOLOGY("rampant-arsenal-technology-battery-equipment-3"):set_fields({ hidden = true })
end
