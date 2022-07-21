-- Trees are mandatory
if mods["alien-biomes"] and mods["pycoalprocessing"] and data.raw["string-setting"]["alien-biomes-disable-vegetation"] then
    data.raw["string-setting"]["alien-biomes-disable-vegetation"].allowed_values = { "Disabled" }
    data.raw["string-setting"]["alien-biomes-disable-vegetation"].hidden = true
end
