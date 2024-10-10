-- Trees are mandatory
if mods["alien-biomes"] and mods["pycoalprocessing"] and data.raw["string-setting"]["alien-biomes-disable-vegetation"] then
    data.raw["string-setting"]["alien-biomes-disable-vegetation"].allowed_values = {"Disabled"}
    data.raw["string-setting"]["alien-biomes-disable-vegetation"].hidden = true
end

if mods["Transport_Drones"] then
    data.raw["double-setting"]["fuel-consumption-per-meter"].default_value = 0.01
    data.raw["double-setting"]["fuel-consumption-per-meter"].minimum_value = 0.01
    data.raw["double-setting"]["fuel-amount-per-drone"].default_value = 25
    if mods["pypetroleumhandling"] then
        data.raw["string-setting"]["fuel-fluid"].default_value = "gasoline"
    end
end
